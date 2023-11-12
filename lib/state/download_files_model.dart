import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:minio/minio.dart';

import '../env/MinioConfig.dart';

class DownloadTask {
  String filePath;
  Function() onCompleted;
  Function(String) onProgress;
  Function(String) onError;

  DownloadTask({
    required this.filePath,
    required this.onCompleted,
    required this.onProgress,
    required this.onError,
  });
}

class DownloadFilesModel extends ChangeNotifier {
  String? _downloadPath;

  Map<String, String> _downloadProgress = {};

  void updateProgress(String fileName, String progress) {
    _downloadProgress[fileName] = progress;
    print(_downloadProgress[fileName]);
    notifyListeners();
  }

  String getProgress(String fileName) {
    return _downloadProgress[fileName] ?? "0.0";
  }

  Future<String?> getDownloadPath() async {
    _downloadPath ??= await selectFolder();
    return _downloadPath;
  }

  Future<String?> selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _downloadPath = selectedDirectory;
      notifyListeners();
    }
    return selectedDirectory;
  }

  final List<DownloadTask> _downloadQueue = [];
  int _activeDownloads = 0;

  void enqueueDownload(DownloadTask task) {
    print(task.filePath);
    _downloadQueue.add(task);
    _processDownloadQueue();
  }

  void _processDownloadQueue() {
    while (_activeDownloads < 3 && _downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeAt(0);
      _activeDownloads++;
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    try {
      await downloadFile(task.filePath, task.onProgress);
      task.onCompleted();
    } catch (e) {
      task.onError(e.toString());
    } finally {
      _downloadCompleted();
    }
  }

  void _downloadCompleted() {
    _activeDownloads--;
    _processDownloadQueue();
  }

  Future<void> downloadFile(
      String fileName, Function(String) onProgress) async {
    final minio = Minio(
      endPoint: MinioConfig.endPoint,
      port: MinioConfig.port,
      accessKey: MinioConfig.accessKey,
      secretKey: MinioConfig.secretKey,
      useSSL: MinioConfig.useSSL,
    );

    final file = File('$_downloadPath\\$fileName');

    final stream = await minio.getObject(
        FileStorgeConfig.storageBucket.toLowerCase(), fileName);

    final totalSize = await minio.statObject(
        FileStorgeConfig.storageBucket.toLowerCase(), fileName);
    int downloadedSize = 0;

    final fileSink = file.openWrite();
    await for (var data in stream) {
      fileSink.add(data);
      downloadedSize += data.length;
      final progress =
          (downloadedSize / (totalSize.size ?? 1) * 100).toStringAsFixed(2);
      onProgress('$progress%');
    }

    await fileSink.close();
  }
}
