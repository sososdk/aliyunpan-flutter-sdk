import 'dart:async';

import 'package:aliyunpan_sdk/aliyunpan_sdk.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_system/file_system.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:slugid/slugid.dart';

import 'widget/breadcrumbs.dart';

class SubFolder {
  final String title;
  final String driveId;
  final String? fileId;

  SubFolder(this.title, this.driveId, this.fileId);
}

class DrivesPage extends StatefulWidget {
  const DrivesPage({
    super.key,
    required this.client,
    required this.title,
    required this.driveId,
    this.parentFileId,
  });

  final AliyunpanClient client;
  final String title;
  final String driveId;
  final String? parentFileId;

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  var key = UniqueKey();

  late StreamSubscription uploadUpdatesSubscription;

  late final root = SubFolder('root', widget.driveId, widget.parentFileId);

  late final folders = [root];

  SubFolder get folder => folders.last;

  void add(SubFolder folder) => setState(() => folders.add(folder));

  @override
  void initState() {
    super.initState();
    uploadUpdatesSubscription = widget.client.uploader.updates.listen((event) {
      if (event is UploadTaskStatusUpdate &&
          event.status == TaskStatus.complete &&
          event.result?.driveId == folder.driveId &&
          event.result?.parentFileId == (folder.fileId ?? 'root')) {
        setState(() => key = UniqueKey());
      }
    });
  }

  @override
  void dispose() {
    uploadUpdatesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(
          onPressed: () {
            if (folders.length > 1) {
              setState(() => folders.removeLast());
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () => uploadFile(context),
            icon: const Icon(Icons.upload),
          ),
          IconButton(
            onPressed: () => createFolder(context),
            icon: const Icon(Icons.create_new_folder),
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Breadcrumbs<SubFolder>(
              items: folders
                  .map((e) => BreadcrumbItem<SubFolder>(text: e.title, data: e))
                  .toList(),
              onSelect: (value) {
                if (value == null) return;
                final start = folders.indexOf(value);
                if (start == -1) return;
                folders.removeRange(start + 1, folders.length);
                setState(() {});
              },
            )),
      ),
      body: DrivePage(
        key: key,
        client: widget.client,
        folder: folder,
      ),
      bottomSheet: UpdatesIndicator(client: widget.client),
    );
  }

  Future<void> uploadFile(BuildContext context) async {
    final file = await openFile();
    if (file == null) return;

    // 上传文件
    widget.client.uploader.enqueue(UploadTask(
      Slugid.nice().toString(),
      UploadFile(const LocalFileSystem().file(file.path)),
      folder.driveId,
      file.name,
      parentFileId: folder.fileId,
      checkNameMode: CheckNameMode.autoRename,
      useProof: true,
    ));
  }

  Future<void> createFolder(BuildContext context) async {
    final nameController = TextEditingController();
    context.showModalFlash(
        builder: (context, controller) => Flash(
              controller: controller,
              dismissDirections: FlashDismissDirection.values,
              child: AlertDialog(
                title: const Text('创建文件夹'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: '请输入文件夹名称',
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () async {
                        final name = nameController.text;
                        if (name.isEmpty) return;
                        final created = await widget.client.send(CreateFile(
                            name: name,
                            driveId: folder.driveId,
                            parentFileId: folder.fileId,
                            type: FileType.folder));
                        debugPrint(created.toString());
                        if (context.mounted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (created.exist == true) {
                              Toast.show(context, const Text('文件已存在'));
                            } else {
                              setState(() => key = UniqueKey());
                              Toast.show(context, const Text('成功创建文件夹'));
                            }
                          }
                        }
                      },
                      child: const Text('确定')),
                ],
              ),
            ));
  }
}

class UpdatesIndicator extends StatefulWidget {
  const UpdatesIndicator({super.key, required this.client});

  final AliyunpanClient client;

  @override
  State<UpdatesIndicator> createState() => _UpdatesIndicatorState();
}

class _UpdatesIndicatorState extends State<UpdatesIndicator> {
  Uploader get uploader => widget.client.uploader;

  Downloader get downloader => widget.client.downloader;
  late StreamSubscription uploadTaskUpdateSubscription;
  late StreamSubscription downloadTaskUpdateSubscription;

  final _uploadTasks = <UploadTask>{};
  final _uploadTaskStatuses = <UploadTask, UploadTaskStatusUpdate>{};
  final _uploadTaskProgresses = <UploadTask, UploadTaskProgressUpdate>{};

  final _downloadTasks = <DownloadTask>{};
  final _downloadTaskStatuses = <DownloadTask, DownloadTaskStatusUpdate>{};
  final _downloadTaskProgresses = <DownloadTask, DownloadTaskProgressUpdate>{};

  @override
  void initState() {
    super.initState();
    uploadTaskUpdateSubscription = uploader.updates.listen((event) {
      switch (event) {
        case UploadTaskStatusUpdate():
          if (event.status == TaskStatus.enqueued) {
            _uploadTasks.add(event.task);
          }
          _uploadTaskStatuses[event.task] = event;
        case UploadTaskProgressUpdate():
          _uploadTaskProgresses[event.task] = event;
      }
      setState(() {});
    });
    downloadTaskUpdateSubscription = downloader.updates.listen((event) {
      switch (event) {
        case DownloadTaskStatusUpdate():
          if (event.status == TaskStatus.enqueued) {
            _downloadTasks.add(event.task);
          }
          _downloadTaskStatuses[event.task] = event;
        case DownloadTaskProgressUpdate():
          _downloadTaskProgresses[event.task] = event;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    uploadTaskUpdateSubscription.cancel();
    downloadTaskUpdateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ..._uploadTasks.map((e) {
          final status = _uploadTaskStatuses[e];
          final progress = _uploadTaskProgresses[e];
          final progressText = progress?.progress == null
              ? '-'
              : '${(progress!.progress! * 100).toStringAsFixed(2)}%';
          final speedText = progress?.networkSpeed == null
              ? '-'
              : progress!.networkSpeed!.speedText;
          final remainingText = progress?.timeRemaining == null
              ? '-'
              : progress!.timeRemaining!.remainingText;
          return ListTile(
            leading: const Icon(Icons.upload),
            title: Text(e.name),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(progressText),
                Text(speedText),
                Text(remainingText),
              ],
            ),
            trailing: status == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.status != TaskStatus.complete)
                        IconButton(
                          onPressed: () {
                            if (status.status.isFinalState) {
                              widget.client.uploader.enqueue(e);
                            } else {
                              widget.client.uploader.cancel(e);
                            }
                          },
                          icon: status.status.isFinalState
                              ? const Icon(Icons.play_arrow)
                              : const Icon(Icons.pause),
                        ),
                      IconButton(
                        onPressed: status.status.isFinalState
                            ? () {
                                _uploadTasks.remove(e);
                                _uploadTaskStatuses.remove(e);
                                _uploadTaskProgresses.remove(e);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
          );
        }),
        ..._downloadTasks.map((e) {
          final status = _downloadTaskStatuses[e];
          final progress = _downloadTaskProgresses[e];
          final progressText = progress?.progress == null
              ? '-'
              : '${(progress!.progress! * 100).toStringAsFixed(2)}%';
          final speedText = progress?.networkSpeed == null
              ? '-'
              : progress!.networkSpeed!.speedText;
          final remainingText = progress?.timeRemaining == null
              ? '-'
              : progress!.timeRemaining!.remainingText;
          final resource = e.resource;
          final title = switch (resource) {
            DownloadFile() => path.basename(resource.file.path),
            _ => resource.toString(),
          };
          return ListTile(
            leading: const Icon(Icons.download),
            title: Text(title),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(progressText),
                Text(speedText),
                Text(remainingText),
              ],
            ),
            trailing: status == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.status != TaskStatus.complete)
                        IconButton(
                          onPressed: () {
                            if (status.status.isFinalState) {
                              widget.client.downloader.enqueue(e);
                            } else {
                              widget.client.downloader.cancel(e);
                            }
                          },
                          icon: status.status.isFinalState
                              ? const Icon(Icons.play_arrow)
                              : const Icon(Icons.pause),
                        ),
                      IconButton(
                        onPressed: status.status.isFinalState
                            ? () {
                                _downloadTasks.remove(e);
                                _downloadTaskStatuses.remove(e);
                                _downloadTaskProgresses.remove(e);
                                setState(() {});
                              }
                            : null,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
          );
        }),
      ],
    );
  }
}

class DrivePage extends StatefulWidget {
  const DrivePage({
    super.key,
    required this.client,
    required this.folder,
  });

  final AliyunpanClient client;
  final SubFolder folder;

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  late Future<FileInfos> future = getFiles();

  Future<FileInfos> getFiles() => widget.client.send(GetFiles(
        driveId: widget.folder.driveId,
        parentFileId: widget.folder.fileId,
        orderBy: FileOrder.name,
      ));

  _DrivesPageState get parent {
    return context.findAncestorStateOfType<_DrivesPageState>()!;
  }

  @override
  void didUpdateWidget(covariant DrivePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folder != widget.folder) {
      future = getFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        return switch (snapshot.connectionState) {
          ConnectionState.done => () {
              if (snapshot.hasError) {
                return const Center(child: Icon(Icons.error_outline_rounded));
              } else if (!snapshot.hasData) {
                return const Center(
                  child: Text('空', style: TextStyle(fontSize: 48)),
                );
              } else if (snapshot.data?.items.isEmpty ?? true) {
                return const Center(
                  child: Text('空', style: TextStyle(fontSize: 48)),
                );
              }
              final data = snapshot.requireData;
              return ListView.separated(
                itemBuilder: (context, index) {
                  final item = data.items[index];
                  return ListTile(
                    leading: Icon(switch (item.type) {
                      FileType.file => Icons.description,
                      FileType.folder => Icons.folder,
                    }),
                    title: Text(item.name),
                    subtitle: item.size == null
                        ? null
                        : Text(item.size!.fileSizeText),
                    trailing: PopupMenuButton(
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            child: const Text('重命名'),
                            onTap: () => renameFile(context, item),
                          ),
                          PopupMenuItem(
                            child: const Text('移动到'),
                            onTap: () => moveFile(context, item),
                          ),
                          PopupMenuItem(
                            child: const Text('删除'),
                            onTap: () => deleteFile(context, item),
                          ),
                          PopupMenuItem(
                            child: const Text('移到回收站'),
                            onTap: () => trashFile(context, item),
                          ),
                        ];
                      },
                      child: const Icon(Icons.more_vert),
                    ),
                    onTap: () {
                      if (item.type case FileType.file) {
                        context.showModalFlash(
                          builder: (context, controller) => Flash(
                            controller: controller,
                            dismissDirections: FlashDismissDirection.values,
                            child: AlertDialog(
                              title: const Text('下载文件'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      downloadFile(context, item);
                                      controller.dismiss();
                                    },
                                    child: const Text('确定')),
                              ],
                            ),
                          ),
                        );
                      } else if (item.type case FileType.folder) {
                        parent.add(
                            SubFolder(item.name, item.driveId, item.fileId));
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                itemCount: data.items.length,
              );
            }(),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }

  Future<void> renameFile(BuildContext context, FileInfo item) async {
    final nameController = TextEditingController();
    context.showModalFlash(
        builder: (context, controller) => Flash(
              controller: controller,
              dismissDirections: FlashDismissDirection.values,
              child: AlertDialog(
                title: const Text('重命名'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: '请输入名称',
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () async {
                        final name = nameController.text;
                        if (name.isEmpty) return;
                        final created = await widget.client.send(UpdateFile(
                            name: name,
                            driveId: widget.folder.driveId,
                            fileId: item.fileId));
                        debugPrint(created.toString());
                        if (context.mounted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            // if (created.exist == true) {
                            //   Toast.show(context, const Text('文件已存在'));
                            // } else {
                            setState(() {
                              future = getFiles();
                            });
                            Toast.show(context, const Text('成功重命名'));
                            // }
                          }
                        }
                      },
                      child: const Text('确定')),
                ],
              ),
            ));
  }

  Future<void> moveFile(BuildContext context, FileInfo item) async {
    context.showModalFlash(
        builder: (context, controller) => Flash(
              controller: controller,
              dismissDirections: FlashDismissDirection.values,
              child: AlertDialog(
                title: const Text('移动到根目录'),
                actions: [
                  TextButton(
                      onPressed: () async {
                        final created = await widget.client.send(MoveFile(
                          driveId: widget.folder.driveId,
                          fileId: item.fileId,
                        ));
                        debugPrint(created.toString());
                        if (context.mounted) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            // if (created.exist == true) {
                            //   Toast.show(context, const Text('文件已存在'));
                            // } else {
                            setState(() {
                              future = getFiles();
                            });
                            Toast.show(context, const Text('成功重命名'));
                            // }
                          }
                        }
                      },
                      child: const Text('确定')),
                ],
              ),
            ));
  }

  Future<void> deleteFile(BuildContext context, FileInfo item) async {
    widget.client
        .send(DeleteFile(driveId: widget.folder.driveId, fileId: item.fileId))
        .then((value) {
      setState(() {
        future = getFiles();
      });
      Toast.show(context, const Text('删除成功'));
    }).catchError((e, s) {
      Toast.show(context, Text('删除失败: $e'));
    });
  }

  Future<void> trashFile(BuildContext context, FileInfo item) async {
    widget.client
        .send(TrashFile(driveId: widget.folder.driveId, fileId: item.fileId))
        .then((value) {
      setState(() {
        future = getFiles();
      });
      Toast.show(context, const Text('移到回收站成功'));
    }).catchError((e, s) {
      Toast.show(context, Text('移到回收站失败: $e'));
    });
  }

  Future<void> downloadFile(BuildContext context, FileInfo item) async {
    const fileSystem = LocalFileSystem();
    final file = fileSystem.systemTempDirectory.childFile(item.name);

    widget.client.downloader.enqueue(DownloadTask(
      Slugid.nice().toString(),
      DownloadFile(const LocalFileSystem().file(file.path)),
      item.driveId,
      item.fileId,
    ));
  }
}

extension StringFileSizeFormat on int {
  String get fileSizeText {
    const int scale = 1024;
    if (this < scale) return '$this B';

    var size = this / scale;
    if (size < scale) return '${size.toStringAsFixed(1)} KB';

    size /= scale;
    if (size < scale) return '${size.toStringAsFixed(1)} MB';

    size /= scale;
    return '${size.toStringAsFixed(1)} GB';
  }
}

extension StringSpeedFormat on double {
  String get speedText {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    final bytes = this * 1000;
    if (bytes < kb) {
      return '${bytes.toStringAsFixed(2)} B/s';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB/s';
    } else if (bytes < gb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB/s';
    } else {
      return '${(bytes / gb).toStringAsFixed(2)} GB/s';
    }
  }
}

extension StringRemainingFormat on Duration {
  String get remainingText {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
