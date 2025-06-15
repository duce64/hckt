import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hckt/DatabaseHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportWordsScreen extends StatefulWidget {
  @override
  _ExportWordsScreenState createState() => _ExportWordsScreenState();
}

class _ExportWordsScreenState extends State<ExportWordsScreen> {
  List<Map<String, dynamic>> _savedWords = [];
  Set<String> _selectedFullForms = Set();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final dbHelper = DatabaseHelper();
    final words =
        await dbHelper
            .getAllSavedWords(); // 👈 dùng đúng hàm load từ bảng saved_words
    setState(() {
      _savedWords = words ?? [];
    });
  }

  void _toggleSelection(String fullForm) {
    setState(() {
      if (_selectedFullForms.contains(fullForm)) {
        _selectedFullForms.remove(fullForm);
      } else {
        _selectedFullForms.add(fullForm);
      }
    });
  }

  Future<bool> _checkStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<String?> _promptFileName() async {
    String fileName = '';
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Đặt tên file'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nhập tên file (không cần .xlsx)',
            ),
            onChanged: (value) {
              fileName = value.trim();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(fileName.isEmpty ? null : fileName);
              },
              child: Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToExcel() async {
    if (!await _checkStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Không có quyền truy cập bộ nhớ.')),
      );
      return;
    }

    final fileName = await _promptFileName();
    if (fileName == null) return; // Người dùng bấm Hủy

    var excel = Excel.createExcel();
    Sheet sheet = excel['Saved Words'];
    sheet.appendRow(['Từ viết tắt', 'Từ viết đủ', 'Nghĩa', 'Chuyên ngành']);

    for (var word in _savedWords) {
      if (_selectedFullForms.isEmpty ||
          _selectedFullForms.contains(word['full_form'])) {
        sheet.appendRow([
          word['abbreviation'] ?? '',
          word['meaning'] ?? '',
          word['full_form'] ?? '',
          word['category'] ?? '',
        ]);
      }
    }

    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/$fileName.xlsx';
    final file =
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);

    // ✅ Lưu đường dẫn
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastExportedFilePath', filePath);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('✅ Xuất thành công'),
            content: Text('File đã lưu tại:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Đóng'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Xuất Từ Đã Lưu',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.file_download_outlined,
              color: colorScheme.onPrimary,
            ),
            tooltip: 'Xuất Excel',
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body:
          _savedWords.isEmpty
              ? Center(
                child: Text(
                  'Chưa có từ nào để xuất.',
                  style: textTheme.bodyMedium,
                ),
              )
              : ListView.builder(
                itemCount: _savedWords.length,
                itemBuilder: (context, index) {
                  final word = _savedWords[index];
                  final fullForm = word['full_form'] ?? '';
                  return Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor:
                          Colors.grey, // màu viền khi chưa tích
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        word['abbreviation'] ?? '',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Từ viết đủ: $fullForm',
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            'Nghĩa: ${word['meaning'] ?? ''}',
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            'Chuyên ngành: ${word['category'] ?? 'Không rõ'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      value:
                          fullForm.isNotEmpty &&
                          _selectedFullForms.contains(fullForm),

                      onChanged: (_) => _toggleSelection(fullForm),
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                    ),
                  );
                },
              ),
    );
  }
}
