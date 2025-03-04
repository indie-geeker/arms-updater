/// 网络适配器接口
/// 
/// 抽象网络请求操作，允许使用不同的网络库实现，如http、dio等。
/// 由调用方实现并在初始化插件时提供。
abstract class NetworkAdapter {
  /// 发送GET请求
  /// 
  /// [url] 请求URL
  /// [headers] 可选的请求头
  /// 
  /// 返回响应数据，通常是解析后的JSON
  Future<dynamic> get(String url, {Map<String, String>? headers});
  
  /// 发送POST请求
  /// 
  /// [url] 请求URL
  /// [headers] 可选的请求头
  /// [body] 请求体
  /// 
  /// 返回响应数据，通常是解析后的JSON
  Future<dynamic> post(String url, {Map<String, String>? headers, dynamic body});
  
  /// 下载文件
  /// 
  /// [url] 下载URL
  /// [savePath] 保存路径
  /// [headers] 可选的请求头
  /// [onProgress] 下载进度回调，received为已下载字节数，total为总字节数
  Future<void> download(
    String url, 
    String savePath, {
    Map<String, String>? headers,
    Function(int received, int total)? onProgress,
  });
}

/// Http包实现的网络适配器示例
/// 
/// ```dart
/// // 使用http包实现
/// class HttpNetworkAdapter implements NetworkAdapter {
///   @override
///   Future<dynamic> get(String url, {Map<String, String>? headers}) async {
///     final response = await http.get(Uri.parse(url), headers: headers);
///     if (response.statusCode == 200) {
///       return json.decode(response.body);
///     } else {
///       throw Exception('请求失败: ${response.statusCode}');
///     }
///   }
///   
///   // 其他方法实现...
/// }
/// ```
/// 
/// Dio包实现的网络适配器示例
/// 
/// ```dart
/// // 使用dio包实现
/// class DioNetworkAdapter implements NetworkAdapter {
///   final Dio _dio;
///   
///   DioNetworkAdapter(this._dio);
///   
///   @override
///   Future<dynamic> get(String url, {Map<String, String>? headers}) async {
///     final response = await _dio.get(url, options: Options(headers: headers));
///     return response.data;
///   }
///   
///   // 其他方法实现...
/// }
/// ```
