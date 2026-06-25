import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static String _version = "";
  static String _buildNumber = "";
  static String _appName = "";

  /// Initialize once when app starts
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();

    _version = info.version;
    _buildNumber = info.buildNumber;
    _appName = info.appName;
  }

  /// Get app version
  static String get version => _version;

  /// Get build number
  static String get buildNumber => _buildNumber;

  /// Get app name
  static String get appName => _appName;

  /// Full version string
  // static String get fullVersion => "v$_version ($_buildNumber)";
  static String get fullVersion => "v$_version";
}