# Noor

Noor is a Quran reader and audio player built with Flutter. Follow a recitation with the Arabic text, switch between reciters, or settle in with a mix of ambient sounds.

The interface is available in English and Arabic. It includes a verse-by-verse reader, word highlighting synced to the audio, light and dark themes, and short focus sessions. Your preferences and playback position are saved on your device.

## Run Noor

You'll need Flutter installed. From the project directory, fetch the packages and start the app:

```sh
flutter pub get
flutter run -d chrome
```

To run the Windows desktop build instead:

```sh
flutter run -d windows
```

## Audio and Quran text

Noor loads Quran text, translations, recitation audio, and word timing data from the [Quran.com API](https://api.quran.com/). An internet connection is needed to load a surah and its recitation. Ambient sound loops are bundled with the app.

## Tests

Run the Flutter tests with:

```sh
flutter test
```
