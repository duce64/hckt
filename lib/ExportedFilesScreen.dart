import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ExportedFilesScreen extends StatefulWidget {
  @override
  _ExportedFilesScreenState createState() => _ExportedFilesScreenState();
}

class _ExportedFilesScreenState extends State<ExportedFilesScreen> {
  List<FileSystemEntity> _xlsxFiles = [];

  @override
  void initState() {
    super.initState();
    _loadExportedFiles();
  }

  Future<void> _loadExportedFiles() async {
    final dir = await getExternalStorageDirectory();
    final files =
        dir!.listSync().where((f) {
          return f.path.endsWith('.xlsx') && File(f.path).existsSync();
        }).toList();

    files.sort(
      (a, b) => File(
        b.path,
      ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()),
    );

    setState(() {
      _xlsxFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý file đã xuất'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body:
          _xlsxFiles.isEmpty
              ? Center(child: Text('Không tìm thấy file Excel nào.'))
              : ListView.builder(
                itemCount: _xlsxFiles.length,
                itemBuilder: (context, index) {
                  final file = _xlsxFiles[index];
                  final filename = file.path.split('/').last;
                  final modified = File(file.path).lastModifiedSync();

                  return ListTile(
                    title: Text(filename),
                    subtitle: Text('Sửa đổi lần cuối: ${modified.toLocal()}'),
                    trailing: Icon(Icons.open_in_new),
                    onTap: () async {
                      await OpenFile.open(file.path);
                    },
                  );
                },
              ),
    );
  }
}
