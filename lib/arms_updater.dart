/// Arms 应用内更新插件
///
/// 一个跨平台应用内更新解决方案，支持 Android、iOS 和 Windows 平台。
/// 提供灵活的网络适配器接口，允许使用不同的网络库实现。
/// 支持自定义UI和更新流程。
library;

// 导出主类实现
export 'src/arms_updater_impl.dart';

// 导出平台接口
export 'src/arms_updater_platform_interface.dart';
export 'src/arms_updater_method_channel.dart';

// 导出模型
export 'model/update_info.dart';
export 'model/update_error.dart';
export 'model/update_response_config.dart';

// 导出枚举
export 'enum/update_status.dart';

// 导出接口
export 'interface/network_adapter.dart';