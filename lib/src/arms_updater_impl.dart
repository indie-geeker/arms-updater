import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../arms_updater.dart';
import '../enum/update_status.dart';
import '../interface/network_adapter.dart';
import '../model/update_info.dart';
import '../model/update_error.dart';
import '../model/update_response_config.dart';

/// Arms应用内更新插件主类
class ArmsUpdater {
  // 单例模式
  static final ArmsUpdater _instance = ArmsUpdater._internal();
  factory ArmsUpdater() => _instance;
  ArmsUpdater._internal();

  /// 响应解析配置
  UpdateResponseConfig? _responseConfig;
  
  /// 平台接口实例
  final ArmsUpdaterPlatform _platform = ArmsUpdaterPlatform.instance;
  
  /// 网络适配器
  NetworkAdapter? _networkAdapter;
  
  /// 更新状态控制器
  final _updateStatusController = StreamController<UpdateStatus>.broadcast();
  
  /// 更新状态流
  Stream<UpdateStatus> get updateStatus => _updateStatusController.stream;
  
  /// 下载进度控制器
  final _downloadProgressController = StreamController<double>.broadcast();
  
  /// 下载进度流
  Stream<double> get downloadProgress => _downloadProgressController.stream;
  
  /// 当前更新信息
  UpdateInfo? _currentUpdateInfo;
  
  /// 自定义更新对话框构建器
  Widget Function(BuildContext, UpdateInfo, VoidCallback, VoidCallback)? _customUpdateDialog;
  
  /// 自定义下载进度对话框构建器
  Widget Function(BuildContext, Stream<double>, VoidCallback)? _customProgressDialog;

  /// 当前是否已初始化
  bool _initialized = false;
  
  /// 初始化任务
  Future<void>? _initTask;

  /// 初始化插件
  ///
  /// [networkAdapter] 网络适配器
  /// [config] 响应解析配置
  /// [customUpdateDialog] 自定义更新对话框构建器
  /// [customProgressDialog] 自定义下载进度对话框构建器
  ///
  /// 返回 ArmsUpdater 以支持链式调用
  ArmsUpdater init({
    NetworkAdapter? networkAdapter,
    UpdateResponseConfig? config,
    Widget Function(BuildContext, UpdateInfo, VoidCallback, VoidCallback)? customUpdateDialog,
    Widget Function(BuildContext, Stream<double>, VoidCallback)? customProgressDialog,
  }) {
    if (_networkAdapter == null && networkAdapter == null) {
      throw ArgumentError('必须提供一个网络适配器');
    }
    
    _initTask = Future(() async {
      _networkAdapter = networkAdapter ?? _networkAdapter;
      _responseConfig = config ?? _responseConfig ?? const UpdateResponseConfig();
      _customUpdateDialog = customUpdateDialog;
      _customProgressDialog = customProgressDialog;
      
      // 更新状态为空闲
      _updateStatusController.add(UpdateStatus.idle);
      _initialized = true;
    });
    
    return this;
  }

  /// 获取平台版本
  Future<String?> getPlatformVersion() async {
    await _ensureInitialized();
    return _platform.getPlatformVersion();
  }
  
  /// 检查更新并自动处理整个更新流程
  /// 
  /// [context] Flutter上下文，用于显示对话框
  /// [updateUrl] 更新信息请求URL
  /// [headers] 可选的请求头
  /// [responseConfig] 可选的自定义响应解析配置
  /// [autoDownload] 是否在用户确认后自动下载，默认为true
  /// [autoInstall] 是否在下载完成后自动安装，默认为true
  /// [onUpdateAvailable] 发现更新时的回调
  /// [onUpdateNotAvailable] 没有更新时的回调
  /// [onDownloadProgress] 下载进度回调
  /// [onDownloadComplete] 下载完成回调
  /// [onInstallComplete] 安装完成回调
  /// [onError] 错误回调
  /// 
  /// 返回 ArmsUpdater 以支持链式调用
  ArmsUpdater checkUpdate({
    required BuildContext context,
    required String updateUrl,
    Map<String, String>? headers,
    UpdateResponseConfig? responseConfig,
    bool autoDownload = true,
    bool autoInstall = true,
    Function(UpdateInfo)? onUpdateAvailable,
    Function()? onUpdateNotAvailable,
    Function(double)? onDownloadProgress,
    Function(String)? onDownloadComplete,
    Function(bool)? onInstallComplete,
    Function(UpdateError)? onError,
  }) {
    _ensureInitialized().then((_) async {
      if (_networkAdapter == null) {
        final error = UpdateError.networkAdapterNotInitialized();
        if (onError != null) onError(error);
        throw StateError('请先调用init方法初始化网络适配器');
      }
      
      final config = responseConfig ?? _responseConfig ?? const UpdateResponseConfig();
      
      try {
        _updateStatusController.add(UpdateStatus.checking);
        
        // 获取当前应用版本信息
        final currentVersion = await _platform.getAppVersionCode() ?? 0;
        
        // 请求更新信息
        final response = await _networkAdapter!.get(updateUrl, headers: headers);
        final updateInfo = _parseUpdateResponse(response, config);
        
        if (updateInfo == null) {
          _updateStatusController.add(UpdateStatus.error);
          if (onError != null) onError(UpdateError.parseResponseFailed());
          return;
        }
        
        // 比较版本，检查是否需要更新
        if (updateInfo.versionCode > currentVersion) {
          _updateStatusController.add(UpdateStatus.available);
          _currentUpdateInfo = updateInfo;
          
          if (onUpdateAvailable != null) onUpdateAvailable(updateInfo);
          
          // 显示更新对话框
          final shouldUpdate = await _showUpdateDialog(context, updateInfo);
          
          // 如果用户同意更新且设置了自动下载
          if (shouldUpdate && autoDownload) {
            // 注册下载进度回调
            if (onDownloadProgress != null) {
              final subscription = downloadProgress.listen(onDownloadProgress);
              subscription.onDone(() => subscription.cancel());
            }
            
            // 显示下载进度对话框
            _showDownloadProgressDialog(context, updateInfo.forceUpdate);
            
            // 下载更新
            final filePath = await _downloadUpdate(updateInfo, headers: headers);
            
            if (filePath != null) {
              if (onDownloadComplete != null) onDownloadComplete(filePath);
              
              // 如果设置了自动安装
              if (autoInstall) {
                final installResult = await _installUpdate(filePath);
                if (onInstallComplete != null) onInstallComplete(installResult);
              }
            } else {
              if (onError != null) onError(UpdateError.downloadFailed());
            }
          }
        } else {
          _updateStatusController.add(UpdateStatus.notAvailable);
          if (onUpdateNotAvailable != null) onUpdateNotAvailable();
        }
      } catch (e) {
        _updateStatusController.add(UpdateStatus.error);
        if (onError != null) onError(UpdateError.unknown(e.toString()));
      }
    }).catchError((e) {
      if (onError != null) onError(UpdateError.unknown(e.toString()));
    });
    
    return this;
  }
  
  /// 手动下载当前更新
  /// 
  /// [headers] 可选的下载请求头
  /// [onProgress] 下载进度回调
  /// 
  /// 返回下载文件的路径，下载失败则返回null
  Future<String?> download({
    Map<String, String>? headers,
    Function(double)? onProgress,
  }) async {
    await _ensureInitialized();
    
    if (_currentUpdateInfo == null) {
      throw StateError('没有可用的更新信息，请先调用checkUpdate方法');
    }
    
    // 注册下载进度回调
    StreamSubscription? subscription;
    if (onProgress != null) {
      subscription = downloadProgress.listen(onProgress);
    }
    
    final filePath = await _downloadUpdate(_currentUpdateInfo!, headers: headers);
    
    // 取消进度订阅
    subscription?.cancel();
    
    return filePath;
  }
  
  /// 手动安装更新
  /// 
  /// [filePath] 安装包文件路径，如果为null则尝试安装最近下载的更新
  /// 
  /// 返回安装是否成功
  Future<bool> install([String? filePath]) async {
    await _ensureInitialized();
    
    final path = filePath ?? (_currentUpdateInfo != null ? 
        '${await _platform.getExternalStoragePath()}/update_${_currentUpdateInfo!.versionCode}.apk' : 
        null);
    
    if (path == null) {
      throw StateError('没有指定安装文件路径，且没有可用的更新信息');
    }
    
    return _installUpdate(path);
  }
  
  /// 释放资源
  /// 
  /// 返回 ArmsUpdater 以支持链式调用
  ArmsUpdater dispose() {
    _updateStatusController.close();
    _downloadProgressController.close();
    return this;
  }
  
  // 内部方法：显示更新对话框
  Future<bool> _showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    bool shouldUpdate = false;
    
    await showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) {
        if (_customUpdateDialog != null) {
          return _customUpdateDialog!(
            context, 
            updateInfo,
            () {
              shouldUpdate = true;
              Navigator.pop(context);
            },
            () {
              Navigator.pop(context);
            },
          );
        }
        
        // 默认更新对话框
        return AlertDialog(
          title: Text('发现新版本 ${updateInfo.versionName ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('更新内容:'),
              Text(updateInfo.updateContent),
              if (updateInfo.fileSize != null)
                Text('文件大小: ${_formatFileSize(updateInfo.fileSize!)}'),
            ],
          ),
          actions: [
            if (!updateInfo.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('稍后再说'),
              ),
            TextButton(
              onPressed: () {
                shouldUpdate = true;
                Navigator.pop(context);
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
    
    return shouldUpdate;
  }
  
  // 内部方法：显示下载进度对话框
  void _showDownloadProgressDialog(BuildContext context, bool forceUpdate) {
    // 创建进度流控制器
    final controller = StreamController<double>();
    
    // 将进度流连接到全局进度流
    _downloadProgressController.stream.listen((progress) {
      if (!controller.isClosed) {
        controller.add(progress);
      }
    });
    
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        // 使用自定义对话框或默认对话框
        return _customProgressDialog != null
            ? _customProgressDialog!(context, controller.stream, () {
                controller.close();
                Navigator.of(context, rootNavigator: true).pop();
              })
            : AlertDialog(
                title: const Text('正在下载更新'),
                content: StreamBuilder<double>(
                  stream: controller.stream,
                  initialData: 0.0,
                  builder: (context, snapshot) {
                    final progress = snapshot.data ?? 0.0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 10),
                        Text('${(progress * 100).toStringAsFixed(1)}%'),
                      ],
                    );
                  },
                ),
                actions: forceUpdate
                    ? null
                    : [
                        TextButton(
                          onPressed: () {
                            controller.close();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text('取消'),
                        ),
                      ],
              );
      },
    );
    
    // 监听下载完成事件，自动关闭对话框
    StreamSubscription? progressSubscription;
    progressSubscription = downloadProgress.listen((progress) {
      if (progress >= 1.0) {
        Navigator.of(context, rootNavigator: true).pop();
        progressSubscription?.cancel();
      }
    });
  }
  
  // 内部方法：下载更新
  Future<String?> _downloadUpdate(
    UpdateInfo updateInfo, {
    Map<String, String>? headers,
  }) async {
    if (_networkAdapter == null) {
      throw StateError('请先调用init方法初始化网络适配器');
    }
    
    try {
      _updateStatusController.add(UpdateStatus.downloading);
      
      // 获取下载路径
      final savePath = await _platform.getExternalStoragePath();
      final filePath = '$savePath/update_${updateInfo.versionCode}.apk';
      
      // 下载文件
      await _networkAdapter!.download(
        updateInfo.downloadUrl,
        filePath,
        headers: headers,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgressController.add(received / total);
          }
        },
      );
      
      // 下载完成
      _updateStatusController.add(UpdateStatus.readyToInstall);
      _downloadProgressController.add(1.0);
      
      // 校验MD5（如果提供）
      if (updateInfo.md5Checksum != null && updateInfo.md5Checksum!.isNotEmpty) {
        // MD5校验逻辑（未实现）
      }
      
      return filePath;
    } catch (e) {
      _updateStatusController.add(UpdateStatus.error);
      return null;
    }
  }
  
  // 内部方法：安装更新
  Future<bool> _installUpdate(String filePath) async {
    try {
      _updateStatusController.add(UpdateStatus.installing);
      final result = await _platform.installUpdate(filePath);
      
      if (result) {
        _updateStatusController.add(UpdateStatus.idle);
      } else {
        _updateStatusController.add(UpdateStatus.error);
      }
      
      return result;
    } catch (e) {
      _updateStatusController.add(UpdateStatus.error);
      return false;
    }
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
  
  // 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (_initTask != null) {
        await _initTask;
      } else {
        throw StateError('请先调用init方法初始化');
      }
    }
  }
}

/// 解析更新响应
UpdateInfo? _parseUpdateResponse(dynamic response, UpdateResponseConfig config) {
  if (response == null) return null;

  // 如果提供了自定义解析器，优先使用
  if (config.customParser != null) {
    return config.customParser!(response is Map<String, dynamic> 
        ? response 
        : json.decode(response.toString()));
  }

  // 标准解析逻辑
  final Map<String, dynamic> responseMap = response is Map<String, dynamic>
      ? response
      : json.decode(response.toString());

  // 检查状态码
  if (responseMap.containsKey(config.statusCodeField)) {
    final statusCode = responseMap[config.statusCodeField];

    // 检查请求是否成功
    if (_isSuccessStatus(statusCode, config.successValue)) {
      // 获取更新信息字段
      final updateData = config.updateInfoField.isEmpty
          ? responseMap
          : responseMap[config.updateInfoField];

      if (updateData != null) {
        try {
          return UpdateInfo.fromJson(updateData is Map<String, dynamic>
              ? updateData
              : json.decode(updateData.toString()));
        } catch (e) {
          // 解析更新信息失败
          throw FormatException('无法解析更新信息: $e');
        }
      }
    }
  }

  return null;
}

/// 检查状态码是否表示成功
bool _isSuccessStatus(dynamic actual, dynamic expected) {
  if (actual == expected) return true;
  
  // 处理字符串与数字的比较
  if (actual is String && expected is int) {
    return int.tryParse(actual) == expected;
  }
  if (actual is int && expected is String) {
    return actual == int.tryParse(expected);
  }
  
  return false;
}
