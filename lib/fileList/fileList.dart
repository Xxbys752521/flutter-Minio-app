// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:minio/minio.dart';
import 'package:provider/provider.dart';
import '../env/MinioConfig.dart';
import '../state/download_files_model.dart';
import 'fileListItem.dart';

class FileListPage extends StatefulWidget {
  const FileListPage({super.key});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  late List<String> files = [];

  @override
  void initState() {
    super.initState();
    getFiles().then((fileList) {
      setState(() {
        files = fileList;
      });
    });
  }

  Future<List<String>> getFiles() async {
    final minio = Minio(
      endPoint: MinioConfig.endPoint,
      port: MinioConfig.port,
      accessKey: MinioConfig.accessKey,
      secretKey: MinioConfig.secretKey,
      useSSL: MinioConfig.useSSL,
    );

    final files = <String>[];
    await for (var result
        in minio.listObjects(FileStorgeConfig.storageBucket.toLowerCase())) {
      for (var object in result.objects) {
        if (object.key != null) {
          files.add(object.key!);
        }
      }
    }
    return files;
  }

  @override
  Widget build(BuildContext context) {
    final downloadModel =
        Provider.of<DownloadFilesModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('文件列表'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: files.isEmpty
          ? Center(child: Text('没有文件'))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                String fileName = files[index];

                return FileListItem(
                  fileName: fileName,
                  onDownload: () {
                    DownloadTask task = DownloadTask(
                      filePath: fileName,
                      onCompleted: () {
                        showUploadResult(context, '下载结果', '$fileName 文件下载成功');
                      },
                      onProgress: (progress) {
                        downloadModel.updateProgress(fileName, progress);
                      },
                      onError: (error) {
                        showUploadResult(context, '下载结果', '$fileName 文件下载成功');
                      },
                    );
                    downloadModel.enqueueDownload(task);
                  },
                  onDelete: () async {
                    if (await deleteFile(fileName)) {
                      setState(() {
                        files.removeAt(index);
                      });
                    }
                  },
                );
              },
            ),
    );
  }
}

Future<bool> deleteFile(String fileName) async {
  final minio = Minio(
    endPoint: MinioConfig.endPoint,
    port: MinioConfig.port,
    accessKey: MinioConfig.accessKey,
    secretKey: MinioConfig.secretKey,
    useSSL: MinioConfig.useSSL,
  );
  try {
    // 检查文件是否存在
    var metaData = await minio.statObject(
        FileStorgeConfig.storageBucket.toLowerCase(), fileName);

    // 如果文件存在，删除文件
    await minio.removeObject(
        FileStorgeConfig.storageBucket.toLowerCase(), fileName);

    // 根据元数据删除哈希桶中的对应项
    var fileHash = metaData.metaData?['filehash'];
    if (fileHash != null) {
      await minio.removeObject(
          FileStorgeConfig.fileHashBucket.toLowerCase(), fileHash);
    }

    // 文件删除成功
    return true;
  } catch (e) {
    // 文件不存在或删除失败
    return false;
  }
}

void showUploadResult(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text('确定'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
