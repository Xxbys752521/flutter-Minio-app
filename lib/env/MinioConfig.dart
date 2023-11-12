class MinioConfig {
  static const String endPoint = 'localhost'; // ip
  static const int port = 9005; // 端口
  static const String accessKey = '3YuDPF308jVbo2gdEiSS'; // 用户名
  static const String secretKey =
      'sPdpXLqlk5rQbNQxwRJuBlK4FbCHI6wFd0sJ3BAc'; // 密码
  static const bool useSSL = false; // 是否开启https
  static get url {
    return "http://${endPoint}:${port}/openim/"; // 最后使用时，资源的前缀
  }
}

class FileStorgeConfig {
  static const String storageBucket = 'fileStorage'; // 存储桶名称
  static const String fileHashBucket = 'fileHash'; // 文件哈希桶名称
  static const String fileInfoBucket = 'fileInfo'; // 文件信息桶名称
}
