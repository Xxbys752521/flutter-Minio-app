import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import '../env/MinioConfig.dart';
import 'package:intl/intl.dart';
import 'package:minio/minio.dart';

class UploadedFile {
  String fileName;
  String uploadStatus;
  String uploadMessage;
  String uploadTime;
  double uploadProgress;

  UploadedFile({
    required this.fileName,
    required this.uploadStatus,
    required this.uploadMessage,
    required this.uploadTime,
    this.uploadProgress = 0.0,
  });
}

class UploadTask {
  String filePath;
  Function() onCompleted;
  Function(String) onProgress;
  Function(String) onError;

  UploadTask({
    required this.filePath,
    required this.onCompleted,
    required this.onProgress,
    required this.onError,
  });
}

class UploadedFilesModel extends ChangeNotifier {
  final List<UploadedFile> _uploadedFiles = [];
  final List<UploadTask> _uploadQueue = [];
  int _activeUploads = 0;

  List<UploadedFile> get uploadedFiles => _uploadedFiles;

  void addFile(UploadedFile file) {
    _uploadedFiles.add(file);
    notifyListeners();
  }

  void clearFiles() {
    _uploadedFiles.clear();
    notifyListeners();
  }

  void enqueueUpload(UploadTask task) {
    _uploadQueue.add(task);
    _processQueue();
  }

  void _processQueue() {
    while (_activeUploads < 3 && _uploadQueue.isNotEmpty) {
      final task = _uploadQueue.removeAt(0);
      _activeUploads++;
      _startUpload(task);
    }
  }

  Future<void> _startUpload(UploadTask task) async {
    String fileName = path.basename(task.filePath);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    UploadedFile uploadHistory = UploadedFile(
      fileName: fileName,
      uploadStatus: "正在上传",
      uploadMessage: "",
      uploadTime: formattedDate,
      uploadProgress: 0.0,
    );

    addFile(uploadHistory);

    try {
      String fileHash = await computeFileHash(task.filePath);
      final minio = Minio(
        endPoint: MinioConfig.endPoint,
        port: MinioConfig.port,
        accessKey: MinioConfig.accessKey,
        secretKey: MinioConfig.secretKey,
        useSSL: MinioConfig.useSSL,
      );

      // 检查并创建存储桶（如果不存在）
      if (!await minio
          .bucketExists(FileStorgeConfig.fileHashBucket.toLowerCase())) {
        await minio.makeBucket(FileStorgeConfig.fileHashBucket.toLowerCase());
      }
      if (!await minio
          .bucketExists(FileStorgeConfig.storageBucket.toLowerCase())) {
        await minio.makeBucket(FileStorgeConfig.storageBucket.toLowerCase());
      }

      bool exists = await doesObjectExist(
          minio, FileStorgeConfig.fileHashBucket.toLowerCase(), fileHash);

      if (!exists) {
        Map<String, String> metaData = {
          "fileHash": fileHash,
        };
        await minio.putObject(FileStorgeConfig.fileHashBucket.toLowerCase(),
            fileHash, Stream.value(Uint8List.fromList(utf8.encode(fileHash))));

        final fileStream = File(task.filePath).openRead();
        final fileLength = await File(task.filePath).length();
        int uploadedLength = 0;

        await minio
            .putObject(FileStorgeConfig.storageBucket.toLowerCase(), fileName,
                fileStream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              uploadedLength += data.length;
              task.onProgress((uploadedLength / fileLength).toString());
              sink.add(Uint8List.fromList(data));
            },
          ),
        ), metadata: metaData);

        uploadHistory.uploadStatus = "成功";
        uploadHistory.uploadMessage = "文件上传成功";
        task.onCompleted();
      } else {
        uploadHistory.uploadStatus = "已存在";
        uploadHistory.uploadMessage = "文件已存在";
      }
    } catch (e) {
      uploadHistory.uploadStatus = "失败";
      uploadHistory.uploadMessage = "文件上传失败: $e";
      task.onError(e.toString());
    }

    updateFileProgress(fileName, 1.0);
    _uploadCompleted();
    notifyListeners();
  }

  void _uploadCompleted() {
    _activeUploads--;
    _processQueue();
  }

  Future<String> computeFileHash(String path) async {
    final bytes = await File(path).readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> doesObjectExist(
      Minio minio, String bucketName, String fileHash) async {
    try {
      await minio.statObject(bucketName, fileHash);
      return true;
    } catch (e) {
      if (e is MinioError) {
        return false;
      } else {
        rethrow;
      }
    }
  }

  void updateFileProgress(String fileName, double progress) {
    for (var file in _uploadedFiles) {
      if (file.fileName == fileName) {
        file.uploadProgress = progress;
        notifyListeners();
        break;
      }
    }
  }
}
