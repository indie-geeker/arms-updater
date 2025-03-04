import 'package:flutter/services.dart';

import 'arms_updater_platform_interface.dart';


class MethodChannelArmsUpdater extends ArmsUpdaterPlatform {
  final methodChannel = const MethodChannel('arms_updater');
  
  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }
  
  @override
  Future<bool> installUpdate(String filePath) async {
    return await methodChannel.invokeMethod<bool>(
      'installUpdate', 
      {'filePath': filePath}
    ) ?? false;
  }

  @override
  Future<String?> getAppVersion() {
    // TODO: implement getAppVersion
    throw UnimplementedError();
  }

  @override
  Future<int?> getAppVersionCode() {
    // TODO: implement getAppVersionCode
    throw UnimplementedError();
  }

  @override
  Future<String> getExternalStoragePath() {
    // TODO: implement getExternalStoragePath
    throw UnimplementedError();
  }
  
  // 其他方法实现...
}
