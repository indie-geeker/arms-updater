import 'package:arms_updater/model/update_info.dart';

/// API响应解析配置
/// 
/// 用于配置如何从API响应中解析更新信息，支持自定义状态码字段和成功值。
class UpdateResponseConfig {
  /// 状态码字段名，如 'code'、'status'、'statusCode' 等
  final String statusCodeField;
  
  /// 请求成功的状态码值，如 0、200、'success' 等
  final dynamic successValue;
  
  /// 更新信息字段，如 'data'、'result'、'updateInfo' 等
  final String updateInfoField;
  
  /// 自定义响应解析器，支持更复杂的自定义处理
  final UpdateInfo? Function(Map<String, dynamic> response)? customParser;
  
  /// 构造函数
  const UpdateResponseConfig({
    this.statusCodeField = 'code',
    this.successValue = 0,
    this.updateInfoField = 'data',
    this.customParser,
  });
  
  /// 使用JSON路径表达式获取嵌套字段值
  /// 
  /// 例如: 'response.status.code' 表示 response['status']['code']
  dynamic getValueByPath(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic value = data;
    
    for (final key in keys) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    
    return value;
  }
  
  /// 创建一个新配置，覆盖部分属性
  UpdateResponseConfig copyWith({
    String? statusCodeField,
    dynamic successValue,
    String? updateInfoField,
    UpdateInfo? Function(Map<String, dynamic>)? customParser,
  }) {
    return UpdateResponseConfig(
      statusCodeField: statusCodeField ?? this.statusCodeField,
      successValue: successValue ?? this.successValue,
      updateInfoField: updateInfoField ?? this.updateInfoField,
      customParser: customParser ?? this.customParser,
    );
  }
  
  @override
  String toString() {
    return 'UpdateResponseConfig(statusCodeField: $statusCodeField, '
        'successValue: $successValue, updateInfoField: $updateInfoField, '
        'hasCustomParser: ${customParser != null})';
  }
}