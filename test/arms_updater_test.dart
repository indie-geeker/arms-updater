import 'package:flutter_test/flutter_test.dart';
import 'package:arms_updater/arms_updater.dart';
import 'package:arms_updater/src/arms_updater_platform_interface.dart';
import 'package:arms_updater/src/arms_updater_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockArmsUpdaterPlatform
    with MockPlatformInterfaceMixin
    implements ArmsUpdaterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

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

  @override
  Future<bool> installUpdate(String filePath) {
    // TODO: implement installUpdate
    throw UnimplementedError();
  }
}

void main() {
  final ArmsUpdaterPlatform initialPlatform = ArmsUpdaterPlatform.instance;

  test('$MethodChannelArmsUpdater is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelArmsUpdater>());
  });

  test('getPlatformVersion', () async {
    ArmsUpdater armsUpdaterPlugin = ArmsUpdater();
    // MockArmsUpdaterPlatform fakePlatform = MockArmsUpdaterPlatform();
    // ArmsUpdaterPlatform.instance = fakePlatform;

    expect(await armsUpdaterPlugin.getPlatformVersion(), '42');
  });
}
