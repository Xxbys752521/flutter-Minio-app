// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'state/uploaded_files_model.dart';

class UploadPage extends StatefulWidget {
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  @override
  Widget build(BuildContext context) {
    final uploadedFilesModel = Provider.of<UploadedFilesModel>(context);
    List<UploadedFile> uploadedFiles = uploadedFilesModel.uploadedFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text('上传文件'),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        actions: [
          IconButton(
              icon: Icon(Icons.file_upload),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null) {
                  for (var file in result.files) {
                    UploadTask task = UploadTask(
                      filePath: file.path!,
                      onCompleted: () {
                        showUploadResult(
                            context, '上传结果', '${file.name} 文件上传成功');
                      },
                      onProgress: (progress) {
                        double progressValue = double.tryParse(progress) ?? 0.0;
                        uploadedFilesModel.updateFileProgress(
                            file.name, progressValue);
                      },
                      onError: (error) {
                        showUploadResult(
                            context, '上传结果', '${file.name} 文件上传失败: $error');
                      },
                    );
                    uploadedFilesModel.enqueueUpload(task);
                  }
                } else {
                  showUploadResult(context, '上传结果', '未选择文件');
                }
              }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: uploadedFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.upload_file, color: Colors.grey, size: 100),
                        Text('没有上传历史',
                            style: TextStyle(fontSize: 24, color: Colors.grey)),
                        Text('点击右上角的按钮来上传文件',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: uploadedFiles.length,
                    itemBuilder: (context, index) {
                      UploadedFile uploadHistory = uploadedFiles[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                                value: uploadHistory.uploadProgress),
                            ListTile(
                              title: Text(uploadHistory.fileName),
                              subtitle:
                                  Text('上传状态: ${uploadHistory.uploadStatus}'
                                      '\n消息: ${uploadHistory.uploadMessage}'
                                      '\n时间: ${uploadHistory.uploadTime}'),
                              leading: Icon(
                                uploadHistory.uploadStatus == '成功'
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: uploadHistory.uploadStatus == '成功'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
