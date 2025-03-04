import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../arms_updater.dart';


abstract class ArmsUpdaterPlatform extends PlatformInterface {
  ArmsUpdaterPlatform() : super(token: _token);
  
  static final Object _token = Object();
  static final ArmsUpdaterPlatform _instance = MethodChannelArmsUpdater();
  static ArmsUpdaterPlatform get instance => _instance;
  
  Future<String?> getPlatformVersion();
  Future<String?> getAppVersion();
  Future<int?> getAppVersionCode();
  Future<bool> installUpdate(String filePath);
  Future<String> getExternalStoragePath();
}
