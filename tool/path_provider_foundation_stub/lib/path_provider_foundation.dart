import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class PathProviderFoundation extends PathProviderPlatform {
  static void registerWith() {}

  Future<String?> getContainerPath({required String appGroupIdentifier}) async {
    return null;
  }
}
