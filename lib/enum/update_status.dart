// 更新状态
enum UpdateStatus {
  idle,           // 空闲
  checking,       // 检查中
  available,      // 有更新可用
  notAvailable,   // 无更新
  downloading,    // 下载中 
  readyToInstall, // 准备安装
  installing,     // 安装中
  error           // 错误
}