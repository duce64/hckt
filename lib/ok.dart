import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hckt/DatabaseHelper.dart';

class ImportExcelScreen extends StatefulWidget {
  @override
  _ImportExcelScreenState createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  List<Map<String, String>> dictionaryData = [];
  final dbHelper = DatabaseHelper(); // Tạo instance của DatabaseHelper

  Future<void> importDataFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      var bytes = result.files.single.bytes;
      if (bytes != null) {
        var excel = Excel.decodeBytes(bytes);

        if (excel.tables.isNotEmpty) {
          var table = excel.tables.keys.first;
          var sheetData = excel.tables[table]!.rows;

          int importedCount = 0;
          for (int i = 1; i < sheetData.length; i++) {
            var row = sheetData[i];
            if (row != null && row.length >= 2) {
              var englishWord = row[0]?.value?.toString() ?? '';
              var vietnameseMeaning = row[1]?.value?.toString() ?? '';
              if (englishWord.isNotEmpty && vietnameseMeaning.isNotEmpty) {
                await dbHelper.insertWord({
                  DatabaseHelper.COLUMN_ABBREVIATION: englishWord,
                  DatabaseHelper.COLUMN_MEANING: vietnameseMeaning,
                });
                importedCount++;
              }
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã import $importedCount từ vào database.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đọc nội dung file trên web.')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chưa chọn file.')));
    }
  }

  // Hàm để kiểm tra dữ liệu trong database (tùy chọn)
  void _checkDatabase() async {
    final allWords = await dbHelper.getAllWords();
    print('Dữ liệu trong database: $allWords');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Từ Điển từ Excel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: importDataFromExcel,
              child: Text('Chọn và Import File Excel vào Database'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              // Nút tùy chọn để kiểm tra database
              onPressed: _checkDatabase,
              child: Text('Kiểm tra Database'),
            ),
            // Bạn có thể thêm UI để hiển thị dữ liệu từ database ở đây
          ],
        ),
      ),
    );
  }
}
