import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../enum/update_status.dart';
import '../interface/network_adapter.dart';
import '../model/update_info.dart';
import '../model/update_response_config.dart';
import 'arms_updater_platform_interface.dart';

// 导出模型
export '../model/update_info.dart';
export '../model/update_error.dart';
export '../model/update_response_config.dart';

// 导出枚举
export '../enum/update_status.dart';

// 导出接口
export '../interface/network_adapter.dart';

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

  /// 初始化插件
  /// 
  /// [networkAdapter] 可选的网络适配器
  /// [config] 响应解析配置
  Future<void> init({
    NetworkAdapter? networkAdapter,
    UpdateResponseConfig? config,
  }) async {
    if (_networkAdapter == null && networkAdapter == null) {
      throw ArgumentError('必须提供一个网络适配器');
    }
    
    _networkAdapter = networkAdapter ?? _networkAdapter;
    _responseConfig = config ?? _responseConfig ?? const UpdateResponseConfig();
    
    // 更新状态为空闲
    _updateStatusController.add(UpdateStatus.idle);
  }

  /// 获取平台版本
  Future<String?> getPlatformVersion() async {
    return _platform.getPlatformVersion();
  }
  
  /// 检查更新
  /// 
  /// [updateUrl] 更新信息请求URL
  /// [headers] 可选的请求头
  /// [responseConfig] 可选的自定义响应解析配置，优先级高于初始化时提供的配置
  Future<UpdateInfo?> checkUpdate({
    required String updateUrl,
    Map<String, String>? headers,
    UpdateResponseConfig? responseConfig,
  }) async {
    if (_networkAdapter == null) {
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
        return null;
      }
      
      // 比较版本，检查是否需要更新
      if (updateInfo.versionCode > currentVersion) {
        _updateStatusController.add(UpdateStatus.available);
        return updateInfo;
      } else {
        _updateStatusController.add(UpdateStatus.notAvailable);
        return null;
      }
    } catch (e) {
      _updateStatusController.add(UpdateStatus.error);
      return null;
    }
  }
  
  /// 下载更新
  /// 
  /// [updateInfo] 更新信息
  /// [headers] 可选的下载请求头
  Future<String?> downloadUpdate(
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
  
  /// 安装更新
  /// 
  /// [filePath] 安装包文件路径
  Future<bool> installUpdate(String filePath) async {
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
  
  /// 显示更新对话框
  /// 
  /// [context] BuildContext
  /// [updateInfo] 更新信息
  /// [customUpdateDialog] 可选的自定义更新对话框构建器
  Future<bool> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo, {
    Widget Function(BuildContext, UpdateInfo, VoidCallback, VoidCallback)? customUpdateDialog,
  }) async {
    bool shouldUpdate = false;
    
    await showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) {
        if (customUpdateDialog != null) {
          return customUpdateDialog(
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
  
  /// 显示下载进度对话框
  Future<void> showDownloadProgressDialog(
    BuildContext context,
    bool forceUpdate, {
    Widget Function(BuildContext, Stream<double>, VoidCallback)? customProgressDialog,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        if (customProgressDialog != null) {
          return customProgressDialog(
            context,
            downloadProgress,
            () => Navigator.pop(context),
          );
        }
        
        // 默认下载进度对话框
        return AlertDialog(
          title: const Text('正在下载更新'),
          content: StreamBuilder<double>(
            stream: downloadProgress,
            builder: (context, snapshot) {
              final progress = snapshot.data ?? 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              );
            },
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
          ],
        );
      },
    );
  }
  
  /// 释放资源
  void dispose() {
    _updateStatusController.close();
    _downloadProgressController.close();
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
