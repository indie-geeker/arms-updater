/// 更新信息模型
class UpdateInfo {
  /// 版本名称，如 "1.0.0"
  final String? versionName;

  /// 版本号，用于版本比较，通常是一个整数，如 10
  final int versionCode;

  /// 更新内容描述
  final String updateContent;

  /// 下载地址
  final String downloadUrl;

  /// 是否强制更新
  final bool forceUpdate;

  /// 文件大小（字节）
  final int? fileSize;

  /// MD5校验和（可选）
  final String? md5Checksum;

  /// 构造函数
  UpdateInfo({
    required this.versionCode,
    required this.updateContent,
    required this.downloadUrl,
    this.versionName,
    this.forceUpdate = false,
    this.fileSize,
    this.md5Checksum,
  });

  /// 从JSON创建实例
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionCode: json['versionCode'] is String 
          ? int.parse(json['versionCode']) 
          : json['versionCode'] as int,
      updateContent: json['updateContent'] as String,
      downloadUrl: json['downloadUrl'] as String,
      versionName: json['versionName'] as String?,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      fileSize: json['fileSize'] is String 
          ? int.parse(json['fileSize']) 
          : json['fileSize'] as int?,
      md5Checksum: json['md5Checksum'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'versionCode': versionCode,
      'updateContent': updateContent,
      'downloadUrl': downloadUrl,
      'versionName': versionName,
      'forceUpdate': forceUpdate,
      'fileSize': fileSize,
      'md5Checksum': md5Checksum,
    };
  }

  @override
  String toString() {
    return 'UpdateInfo(versionName: $versionName, versionCode: $versionCode, '
        'updateContent: $updateContent, downloadUrl: $downloadUrl, '
        'forceUpdate: $forceUpdate, fileSize: $fileSize, md5Checksum: $md5Checksum)';
  }
}