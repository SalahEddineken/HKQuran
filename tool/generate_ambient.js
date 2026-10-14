const fs = require('fs');
const path = require('path');

const sampleRate = 22050;
const durationSec = 9.5;
const numSamples = Math.floor(sampleRate * durationSec); // 209475

function createWavHeader(numSamples, sampleRate) {
  const dataSize = numSamples * 2;
  const buffer = Buffer.alloc(44);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); // PCM
  buffer.writeUInt16LE(1, 22); // mono
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);
  return buffer;
}

// Biquad filter implementation
class BiquadFilter {
  constructor(type, f0, q, fs) {
    this.fs = fs;
    this.reset();
    this.setParams(type, f0, q);
  }

  reset() {
    this.x1 = 0; this.x2 = 0;
    this.y1 = 0; this.y2 = 0;
  }

  setParams(type, f0, q) {
    const w0 = 2 * Math.PI * Math.max(10, Math.min(this.fs * 0.49, f0)) / this.fs;
    const alpha = Math.sin(w0) / (2 * Math.max(0.01, q));
    const cosw0 = Math.cos(w0);

    let b0, b1, b2, a0, a1, a2;
    if (type === 'lowpass') {
      b0 = (1 - cosw0) / 2;
      b1 = 1 - cosw0;
      b2 = (1 - cosw0) / 2;
      a0 = 1 + alpha;
      a1 = -2 * cosw0;
      a2 = 1 - alpha;
    } else if (type === 'highpass') {
      b0 = (1 + cosw0) / 2;
      b1 = -(1 + cosw0);
      b2 = (1 + cosw0) / 2;
      a0 = 1 + alpha;
      a1 = -2 * cosw0;
      a2 = 1 - alpha;
    } else if (type === 'bandpass') {
      b0 = alpha;
      b1 = 0;
      b2 = -alpha;
      a0 = 1 + alpha;
      a1 = -2 * cosw0;
      a2 = 1 - alpha;
    }

    this.b0 = b0 / a0;
    this.b1 = b1 / a0;
    this.b2 = b2 / a0;
    this.a1 = a1 / a0;
    this.a2 = a2 / a0;
  }

  process(x) {
    const y = this.b0 * x + this.b1 * this.x1 + this.b2 * this.x2 - this.a1 * this.y1 - this.a2 * this.y2;
    this.x2 = this.x1;
    this.x1 = x;
    this.y2 = this.y1;
    this.y1 = isFinite(y) ? y : 0;
    return this.y1;
  }
}

// Pink noise generator (Paul Kellet's filter method)
class PinkNoise {
  constructor() {
    this.b0 = 0; this.b1 = 0; this.b2 = 0; this.b3 = 0; this.b4 = 0; this.b5 = 0; this.b6 = 0;
  }
  next() {
    const white = Math.random() * 2 - 1;
    this.b0 = 0.99886 * this.b0 + white * 0.0555179;
    this.b1 = 0.99332 * this.b1 + white * 0.0750759;
    this.b2 = 0.96900 * this.b2 + white * 0.1538520;
    this.b3 = 0.86650 * this.b3 + white * 0.3104856;
    this.b4 = 0.55000 * this.b4 + white * 0.5329522;
    this.b5 = -0.7616 * this.b5 - white * 0.0168980;
    const pink = this.b0 + this.b1 + this.b2 + this.b3 + this.b4 + this.b5 + this.b6 + white * 0.5362;
    this.b6 = white * 0.115926;
    return pink * 0.15;
  }
}

// Brown noise generator (leaky integrator)
class BrownNoise {
  constructor() {
    this.val = 0;
  }
  next() {
    const white = Math.random() * 2 - 1;
    this.val = 0.97 * this.val + white * 0.15;
    return this.val;
  }
}

// Seamless circular crossfade
function makeSeamlessLoop(buffer, crossfadeSamples = 11025) { // 0.5 sec
  const len = buffer.length;
  for (let i = 0; i < crossfadeSamples; i++) {
    const t = i / crossfadeSamples;
    // Cosine ease
    const gainHead = Math.cos(t * Math.PI * 0.5); // 1 -> 0
    const gainTail = Math.sin(t * Math.PI * 0.5); // 0 -> 1

    const headSample = buffer[i];
    const tailSample = buffer[len - crossfadeSamples + i];

    buffer[i] = headSample * gainTail + tailSample * gainHead;
    buffer[len - crossfadeSamples + i] = headSample * gainTail + tailSample * gainHead;
  }
  return buffer;
}

function normalizeAndExport(rawSamples, targetMax = 26000) {
  let max = 0;
  for (let i = 0; i < rawSamples.length; i++) {
    const abs = Math.abs(rawSamples[i]);
    if (abs > max) max = abs;
  }
  const scale = max > 0 ? targetMax / max : 1;
  const pcmBuffer = Buffer.alloc(rawSamples.length * 2);
  for (let i = 0; i < rawSamples.length; i++) {
    const s = Math.max(-32767, Math.min(32767, Math.round(rawSamples[i] * scale)));
    pcmBuffer.writeInt16LE(s, i * 2);
  }
  return pcmBuffer;
}

// -------------------------------------------------------------
// 1. STREAM (Babbling Brook / Gentle Flowing Water)
// -------------------------------------------------------------
function generateStream() {
  const pink = new PinkNoise();
  const brown = new BrownNoise();
  const lp = new BiquadFilter('lowpass', 1800, 0.7, sampleRate);
  const hp = new BiquadFilter('highpass', 120, 0.8, sampleRate);
  const bp1 = new BiquadFilter('bandpass', 450, 2.5, sampleRate);
  const bp2 = new BiquadFilter('bandpass', 920, 3.0, sampleRate);
  const bp3 = new BiquadFilter('bandpass', 1650, 4.0, sampleRate);

  const raw = new Float32Array(numSamples);
  // Bubble trigger states
  const bubbleCount = 4;
  const bubbles = Array.from({ length: bubbleCount }, () => ({
    active: false,
    freq: 600,
    age: 0,
    duration: 0,
    amp: 0
  }));

  for (let i = 0; i < numSamples; i++) {
    const p = pink.next();
    const b = brown.next();
    const t = i / sampleRate;

    // Slow swirling modulation
    const mod1 = 1 + 0.3 * Math.sin(2 * Math.PI * 0.45 * t);
    const mod2 = 1 + 0.25 * Math.cos(2 * Math.PI * 0.73 * t + 1.2);

    let water = (p * 0.6 + b * 0.4);
    water = lp.process(hp.process(water));

    const res1 = bp1.process(p) * 0.9 * mod1;
    const res2 = bp2.process(p) * 0.7 * mod2;
    const res3 = bp3.process(p) * 0.4;

    // Bubbles
    let bubbleSound = 0;
    for (const bub of bubbles) {
      if (!bub.active && Math.random() < 0.0035) {
        bub.active = true;
        bub.freq = 400 + Math.random() * 850;
        bub.age = 0;
        bub.duration = Math.floor(sampleRate * (0.015 + Math.random() * 0.035));
        bub.amp = 0.15 + Math.random() * 0.25;
      }
      if (bub.active) {
        const bt = bub.age / sampleRate;
        const env = Math.exp(-bub.age / (bub.duration * 0.35));
        // Upward pitch chirp typical of water drops/bubbles
        const instantFreq = bub.freq * (1 + 0.8 * (bub.age / bub.duration));
        bubbleSound += Math.sin(2 * Math.PI * instantFreq * bt) * env * bub.amp;
        bub.age++;
        if (bub.age >= bub.duration) bub.active = false;
      }
    }

    raw[i] = water * 0.65 + (res1 + res2 + res3) * 0.45 + bubbleSound * 0.35;
  }

  makeSeamlessLoop(raw, Math.floor(sampleRate * 0.6));
  return normalizeAndExport(raw, 25000);
}

// -------------------------------------------------------------
// 2. BIRDS (Tranquil Garden / Dawn Birdsong)
// -------------------------------------------------------------
function generateBirds() {
  const pink = new PinkNoise();
  const breezeFilter = new BiquadFilter('bandpass', 550, 0.6, sampleRate);
  const raw = new Float32Array(numSamples);

  // Define realistic bird song events within 9.5s
  const birdEvents = [
    { start: 0.6, type: 'trill', baseFreq: 3100 },
    { start: 1.8, type: 'call', baseFreq: 2750 },
    { start: 2.3, type: 'call', baseFreq: 3400 },
    { start: 3.5, type: 'warble', baseFreq: 2900 },
    { start: 4.8, type: 'trill', baseFreq: 3600 },
    { start: 5.9, type: 'call', baseFreq: 2600 },
    { start: 6.5, type: 'call', baseFreq: 3200 },
    { start: 7.6, type: 'warble', baseFreq: 3300 },
    { start: 8.5, type: 'chirp', baseFreq: 3800 },
  ];

  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    // Ambient garden leaf breeze background
    const p = pink.next();
    const breeze = breezeFilter.process(p) * 0.12 * (1 + 0.3 * Math.sin(2 * Math.PI * 0.2 * t));

    let birdTone = 0;
    for (const b of birdEvents) {
      const dt = t - b.start;
      if (dt >= 0 && dt <= 0.65) {
        if (b.type === 'call') {
          // Ascending then descending whistle
          const env = Math.sin(Math.PI * (dt / 0.35));
          if (dt <= 0.35) {
            const freq = b.baseFreq + Math.sin(dt * 25) * 200 + (dt / 0.35) * 600;
            birdTone += Math.sin(2 * Math.PI * freq * dt) * env * 0.55;
            // Faint harmonic
            birdTone += Math.sin(4 * Math.PI * freq * dt) * env * 0.08;
          }
        } else if (b.type === 'trill') {
          // Rapid fluttering trill
          if (dt <= 0.5) {
            const env = Math.sin(Math.PI * (dt / 0.5));
            const flutter = Math.sin(2 * Math.PI * 22 * dt);
            const freq = b.baseFreq + flutter * 380;
            birdTone += Math.sin(2 * Math.PI * freq * dt) * env * 0.48;
          }
        } else if (b.type === 'warble') {
          // Melodic two-part phrase
          if (dt <= 0.55) {
            const env = Math.sin(Math.PI * (dt / 0.55));
            const freq = b.baseFreq + Math.sin(2 * Math.PI * 8 * dt) * 450;
            birdTone += Math.sin(2 * Math.PI * freq * dt) * env * 0.5;
          }
        } else if (b.type === 'chirp') {
          if (dt <= 0.18) {
            const env = Math.sin(Math.PI * (dt / 0.18));
            const freq = b.baseFreq - (dt / 0.18) * 800;
            birdTone += Math.sin(2 * Math.PI * freq * dt) * env * 0.45;
          }
        }
      }
    }

    raw[i] = breeze + birdTone;
  }

  makeSeamlessLoop(raw, Math.floor(sampleRate * 0.6));
  return normalizeAndExport(raw, 26000);
}

// -------------------------------------------------------------
// 3. THUNDER (Distant Rolling Atmospheric Thunder & Rain)
// -------------------------------------------------------------
function generateThunder() {
  const pink = new PinkNoise();
  const brown = new BrownNoise();
  const subLp = new BiquadFilter('lowpass', 110, 1.8, sampleRate);
  const midLp = new BiquadFilter('lowpass', 240, 1.0, sampleRate);
  const hp = new BiquadFilter('highpass', 25, 0.7, sampleRate);
  const rainHp = new BiquadFilter('highpass', 1200, 0.7, sampleRate);
  const rainLp = new BiquadFilter('lowpass', 4500, 0.7, sampleRate);

  const raw = new Float32Array(numSamples);

  // Thunder rumble envelopes: 2 long rolling rumbles across 9.5s
  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    const p = pink.next();
    const b = brown.next();

    // Constant background rain accompanying thunder
    const rain = rainLp.process(rainHp.process(p)) * 0.22;

    // Thunder strike 1: swells around t=1.5s to 4.8s
    let env1 = 0;
    if (t >= 0.8 && t <= 5.0) {
      const dt = t - 0.8;
      // Rolling peaks
      const swell = Math.pow(Math.sin(Math.PI * (dt / 4.2)), 1.8);
      const rumble = 1 + 0.45 * Math.sin(2 * Math.PI * 3.2 * dt) + 0.3 * Math.cos(2 * Math.PI * 5.7 * dt);
      env1 = swell * rumble * 1.5;
    }

    // Thunder strike 2: deep distant roll around t=5.8s to 8.9s
    let env2 = 0;
    if (t >= 5.2 && t <= 9.0) {
      const dt = t - 5.2;
      const swell = Math.pow(Math.sin(Math.PI * (dt / 3.8)), 2.2);
      const rumble = 1 + 0.5 * Math.sin(2 * Math.PI * 2.8 * dt + 0.8);
      env2 = swell * rumble * 1.2;
    }

    const thunderEnv = Math.max(0, env1 + env2);
    // Sub-bass heavy filtered rumble
    const rawRumble = (b * 1.5 + p * 0.5) * thunderEnv;
    const sub = subLp.process(hp.process(rawRumble));
    const mid = midLp.process(rawRumble) * 0.4;

    raw[i] = rain + (sub * 1.6 + mid);
  }

  makeSeamlessLoop(raw, Math.floor(sampleRate * 0.6));
  return normalizeAndExport(raw, 27000);
}

// -------------------------------------------------------------
// 4. DESERT (Desert Breeze / Sand Dunes Atmosphere)
// -------------------------------------------------------------
function generateDesert() {
  const pink = new PinkNoise();
  const brown = new BrownNoise();
  const bpDune1 = new BiquadFilter('bandpass', 190, 1.4, sampleRate);
  const bpDune2 = new BiquadFilter('bandpass', 340, 1.8, sampleRate);
  const bpWhistle = new BiquadFilter('bandpass', 780, 4.0, sampleRate);
  const sandHPass = new BiquadFilter('highpass', 3200, 0.8, sampleRate);
  const sandLPass = new BiquadFilter('lowpass', 7500, 0.8, sampleRate);

  const raw = new Float32Array(numSamples);

  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    const p = pink.next();
    const b = brown.next();

    // Slow sweeping expansive gusts
    const gust1 = 0.5 + 0.5 * Math.sin(2 * Math.PI * 0.18 * t);
    const gust2 = 0.5 + 0.5 * Math.cos(2 * Math.PI * 0.28 * t + 1.5);
    const intensity = 0.5 + 0.5 * (gust1 * 0.6 + gust2 * 0.4);

    const duneLow = bpDune1.process(b) * 1.6 * intensity;
    const duneMid = bpDune2.process(b) * 1.1 * gust1;
    const whistle = bpWhistle.process(p) * 0.45 * Math.pow(gust2, 2);
    const sandTexture = sandLPass.process(sandHPass.process(p)) * 0.12 * intensity;

    raw[i] = duneLow + duneMid + whistle + sandTexture;
  }

  makeSeamlessLoop(raw, Math.floor(sampleRate * 0.6));
  return normalizeAndExport(raw, 25000);
}

// -------------------------------------------------------------
// 5. DROPLETS (Rain on Glass / Window Pane)
// -------------------------------------------------------------
function generateDroplets() {
  const pink = new PinkNoise();
  const glassFilter = new BiquadFilter('bandpass', 2400, 5.0, sampleRate);
  const dripFilter = new BiquadFilter('bandpass', 1500, 6.0, sampleRate);
  const drizzleLp = new BiquadFilter('lowpass', 1400, 0.6, sampleRate);
  const drizzleHp = new BiquadFilter('highpass', 200, 0.6, sampleRate);

  const raw = new Float32Array(numSamples);

  // Droplet impacts
  const dropCount = 5;
  const drops = Array.from({ length: dropCount }, () => ({
    active: false,
    freq: 2000,
    age: 0,
    duration: 0,
    amp: 0
  }));

  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    const p = pink.next();

    // Constant muffled rain outside glass
    const exterior = drizzleLp.process(drizzleHp.process(p)) * 0.28;

    let glassTaps = 0;
    for (const d of drops) {
      // Poisson-like drop rate
      if (!d.active && Math.random() < 0.007) {
        d.active = true;
        d.freq = 1400 + Math.random() * 1600;
        d.age = 0;
        d.duration = Math.floor(sampleRate * (0.012 + Math.random() * 0.028));
        d.amp = 0.25 + Math.random() * 0.5;
      }
      if (d.active) {
        const dt = d.age / sampleRate;
        const decay = Math.exp(-d.age / (d.duration * 0.22));
        // Acoustic click + glass ringing body
        const click = Math.sin(2 * Math.PI * d.freq * dt) * decay * d.amp;
        glassTaps += click;
        d.age++;
        if (d.age >= d.duration) d.active = false;
      }
    }

    const glassBody = glassFilter.process(glassTaps) * 0.8;
    const dripBody = dripFilter.process(glassTaps) * 0.5;

    raw[i] = exterior + glassTaps * 0.4 + glassBody + dripBody;
  }

  makeSeamlessLoop(raw, Math.floor(sampleRate * 0.6));
  return normalizeAndExport(raw, 25500);
}

// Generate all 5 files
const generators = {
  stream: generateStream,
  birds: generateBirds,
  thunder: generateThunder,
  desert: generateDesert,
  droplets: generateDroplets,
};

const header = createWavHeader(numSamples, sampleRate);

for (const [name, fn] of Object.entries(generators)) {
  const pcmData = fn();
  const finalFile = Buffer.concat([header, pcmData]);
  const destPath = path.join(__dirname, '..', 'assets', 'ambient', `${name}.wav`);
  fs.writeFileSync(destPath, finalFile);
  console.log(`Generated ${name}.wav (${finalFile.length} bytes) at ${destPath}`);
}
