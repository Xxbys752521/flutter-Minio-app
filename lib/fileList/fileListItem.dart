// ignore: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/download_files_model.dart';

class FileListItem extends StatelessWidget {
  final String fileName;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const FileListItem(
      {Key? key,
      required this.fileName,
      required this.onDownload,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloadModel =
        Provider.of<DownloadFilesModel>(context, listen: false);

    // 使用 Provider.of 来获取下载进度
    String downloadProgress =
        Provider.of<DownloadFilesModel>(context).getProgress(fileName);
    String progressText = '$downloadProgress下载中';

    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: Icon(Icons.insert_drive_file, color: Colors.blue),
        title: Text(fileName, style: TextStyle(fontSize: 16.0)),
        subtitle: downloadProgress != "0.0" && downloadProgress != "100.00%"
            ? Text(progressText)
            : downloadProgress == "100.00%"
                ? Text('下载完成')
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download, color: Colors.blue),
              onPressed: () async {
                String? downloadPath = await downloadModel.getDownloadPath();
                if (downloadPath != null) {
                  onDownload();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.orange),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () {
          // 点击事件处理
        },
      ),
    );
  }
}
