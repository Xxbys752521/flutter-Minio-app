# Flutter 上机题

## MinIO 配置

### MinIO 环境初始化

    `.\minio.exe server D:\minioData --console-address ":9006" --address ":9005"`

### MinIO 环境变量

    `src/lib/env/MinioConfig.dart`

## 文件上传

    由于minio的环境限制，没有使用关系型数据库存储列表信息 ，上传历史部分使用的是provider进行的状态管理，导致每次重启app会清空。
    性能有待提升。

1. **文件选择和上传触发**

   - 通过界面上的上传按钮触发文件选择过程。
   - 使用 `FilePicker` 包允许用户从设备中选择文件。
   - 选定文件后，为每个文件创建一个 `UploadTask` 对象，并将其加入上传队列。

2. **上传队列管理**

   - 上传任务通过 `UploadedFilesModel` 类进行管理，该类包含一个上传队列和正在进行的上传任务计数器。
   - `UploadedFilesModel` 类中有一个 `enqueueUpload` 方法，用于将新的上传任务添加到队列中。
   - 队列中的任务按照先进先出的原则处理，同时确保最多只有三个任务同时进行。
   - 注意：由于本地上传速度较快 可以选择稍大的文件测试，可以看出上传队列的效果。

3. **文件上传逻辑**

   - 每个上传任务由 `_startUpload` 方法处理，该方法包含文件上传的核心逻辑。
   - 首先，对文件进行哈希计算以检查其在 Minio 存储中是否已经存在。
   - 如果文件不存在，那么将文件上传到 Minio 存储。上传过程中，通过`StreamTransformer`监控上传进度，并实时更新进度信息。
   - 文件上传成功或失败后，更新上传历史记录，包括上传状态、消息和进度。

4. **上传状态和进度更新**

   - 在上传过程中，使用 `UploadedFile` 对象来跟踪和更新每个文件的上传状态和进度。
   - 进度更新通过 `updateFileProgress` 方法实现，该方法在 `UploadedFilesModel` 类中定义。
   - 文件上传完成或出错时，将通过 `UploadTask` 中的回调函数通知调用者。

## 文件列表

1. **数据获取**:

   - 使用 `Minio` 客户端与 Minio 服务器通信，获取指定存储桶中的所有文件。
   - `getFiles` 函数通过 `minio.listObjects` 方法异步获取文件列表，并将每个文件的键名存储在一个字符串列表中。

2. **状态管理**:

   - `FileListPage` 是一个 `StatefulWidget`，在其状态类 `_FileListPageState` 中，使用 `initState` 方法初始化文件列表的加载。
   - 文件列表存储在状态类的 `files` 成员变量中，这个列表在获取文件信息后更新。

3. **UI 渲染**:
   - 使用 `ListView.builder` 动态构建文件列表的 UI。每个文件对应列表中的一项，用 `FileListItem` 组件表示。
   - `FileListItem` 组件显示文件名，并提供下载和删除操作的图标按钮。

### 删除文件功能

1. **删除操作**:

   - 在每个 `FileListItem` 组件中，为删除图标按钮绑定了一个回调函数，该函数调用 `deleteFile` 方法。
   - `deleteFile` 方法使用 `Minio` 客户端的 `removeObject` 方法删除指定的文件。

2. **更新列表**:
   - 在文件成功删除后，`deleteFile` 方法返回 `true`，触发文件列表的更新。
   - 更新操作通过 `setState` 调用实现，从 `files` 列表中移除被删除的文件，这样就不会重新加载整个页面。

### 下载文件功能

1. **下载任务管理**:

   - `DownloadFilesModel` 作为一个 `ChangeNotifier`，负责管理下载任务队列和下载路径。
   - 包含下载队列 `_downloadQueue` 和下载进度映射 `_downloadProgress`。
   - 提供 `enqueueDownload` 方法将下载任务添加到队列。
   - `_startDownload` 方法处理队列中的每个下载任务，并更新下载进度。

2. **下载进度显示**:

   - 在 `DownloadFilesModel` 中，`updateProgress` 方法用于更新特定文件的下载进度。
   - `FileListItem` 组件监听 `DownloadFilesModel` 的状态，显示对应文件的下载进度或完成状态。

3. **下载文件到本地**

   - `downloadFile` 方法负责实际的文件下载逻辑，使用 `Minio` 客户端获取文件流并保存到本地文件系统。
   - 下载过程中，更新下载进度，并通过回调传递给 `FileListItem`。

4. **路径选择和状态更新**

   - 使用 `FilePicker` 提供的方法允许用户选择下载文件的保存路径。
   - 如果路径未选择，则在下载前弹出文件夹选择器。
