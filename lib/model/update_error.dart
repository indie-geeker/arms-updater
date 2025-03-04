/// 更新错误
/// 
/// 表示应用更新过程中可能发生的错误
class UpdateError implements Exception {
  /// 错误代码
  final String code;
  
  /// 错误消息
  final String message;
  
  /// 额外的错误详情
  final dynamic details;

  /// 构造函数
  UpdateError({
    required this.code,
    required this.message,
    this.details,
  });
  
  /// 预定义错误：网络错误
  static UpdateError network({String? message, dynamic details}) {
    return UpdateError(
      code: 'NETWORK_ERROR',
      message: message ?? '网络连接错误',
      details: details,
    );
  }
  
  /// 预定义错误：解析错误
  static UpdateError parsing({String? message, dynamic details}) {
    return UpdateError(
      code: 'PARSING_ERROR',
      message: message ?? '无法解析更新信息',
      details: details,
    );
  }
  
  /// 预定义错误：下载错误
  static UpdateError download({String? message, dynamic details}) {
    return UpdateError(
      code: 'DOWNLOAD_ERROR',
      message: message ?? '下载更新文件失败',
      details: details,
    );
  }
  
  /// 预定义错误：安装错误
  static UpdateError install({String? message, dynamic details}) {
    return UpdateError(
      code: 'INSTALL_ERROR',
      message: message ?? '安装更新文件失败',
      details: details,
    );
  }
  
  /// 预定义错误：校验错误
  static UpdateError validation({String? message, dynamic details}) {
    return UpdateError(
      code: 'VALIDATION_ERROR',
      message: message ?? 'MD5校验失败',
      details: details,
    );
  }
  
  /// 预定义错误：网络适配器未初始化
  static UpdateError networkAdapterNotInitialized({String? message, dynamic details}) {
    return UpdateError(
      code: 'NETWORK_ADAPTER_NOT_INITIALIZED',
      message: message ?? '网络适配器未初始化',
      details: details,
    );
  }
  
  /// 预定义错误：解析响应失败
  static UpdateError parseResponseFailed({String? message, dynamic details}) {
    return UpdateError(
      code: 'PARSE_RESPONSE_FAILED',
      message: message ?? '解析更新响应失败',
      details: details,
    );
  }
  
  /// 预定义错误：下载失败
  static UpdateError downloadFailed({String? message, dynamic details}) {
    return UpdateError(
      code: 'DOWNLOAD_FAILED',
      message: message ?? '下载更新失败',
      details: details,
    );
  }
  
  /// 预定义错误：未知错误
  static UpdateError unknown(String errorMessage, {dynamic details}) {
    return UpdateError(
      code: 'UNKNOWN_ERROR',
      message: errorMessage,
      details: details,
    );
  }
  
  @override
  String toString() {
    return 'UpdateError: [$code] $message${details != null ? ' - $details' : ''}';
  }
}