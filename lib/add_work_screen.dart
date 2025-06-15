import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hckt/DatabaseHelper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'custom_appbar.dart';

class AddWordScreen extends StatefulWidget {
  @override
  _AddWordScreenState createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _vietnameseController = TextEditingController();
  final TextEditingController _fullFormController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isImporting = false;

  Future<void> _importFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.single.bytes;

      if (fileBytes == null && result.files.single.path != null) {
        fileBytes = await File(result.files.single.path!).readAsBytes();
      }

      if (fileBytes != null) {
        setState(() {
          _isImporting = true;
        });

        // Hiển thị loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(child: CircularProgressIndicator()),
        );

        try {
          var excel = Excel.decodeBytes(fileBytes);
          final dbHelper = DatabaseHelper();
          final allWords = await dbHelper.getAllWords();
          final existingMap = {
            for (var word in allWords)
              word['abbreviation'].toString(): word['meaning'].toString(),
          };

          int importedCount = 0;
          bool? applyToAll;

          for (var table in excel.tables.keys) {
            for (var row in excel.tables[table]!.rows) {
              if (row.length >= 2) {
                var abbreviation = row[0]?.value?.toString().trim() ?? '';
                var meaning = row[1]?.value?.toString().trim() ?? '';
                var fullForm =
                    row.length > 2
                        ? row[2]?.value?.toString().trim() ?? ''
                        : '';
                var category =
                    row.length > 3
                        ? row[3]?.value?.toString().trim() ?? ''
                        : '';

                if (abbreviation.isEmpty || meaning.isEmpty) continue;

                if (existingMap.containsKey(abbreviation)) {
                  if (applyToAll == null) {
                    final result = await showDialog<String>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Từ "$abbreviation" đã tồn tại'),
                            content: Text(
                              'Nghĩa cũ: "${existingMap[abbreviation]}"\nNghĩa mới: "$meaning"',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'skip'),
                                child: Text('Bỏ qua'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(context, 'overwrite'),
                                child: Text('Ghi đè'),
                              ),
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.pop(context, 'overwrite_all'),
                                child: Text('Ghi đè tất cả'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(context, 'skip_all'),
                                child: Text('Bỏ qua tất cả'),
                              ),
                            ],
                          ),
                    );

                    if (result == 'overwrite') {
                      await dbHelper.insertWord({
                        DatabaseHelper.COLUMN_ABBREVIATION: abbreviation,
                        DatabaseHelper.COLUMN_MEANING: meaning,
                        DatabaseHelper.COLUMN_FULL_FORM: fullForm,
                        DatabaseHelper.COLUMN_CATEGORY: category,
                      });
                      importedCount++;
                    } else if (result == 'overwrite_all') {
                      applyToAll = true;
                      await dbHelper.insertWord({
                        DatabaseHelper.COLUMN_ABBREVIATION: abbreviation,
                        DatabaseHelper.COLUMN_MEANING: meaning,
                        DatabaseHelper.COLUMN_FULL_FORM: fullForm,
                        DatabaseHelper.COLUMN_CATEGORY: category,
                      });
                      importedCount++;
                    } else if (result == 'skip_all') {
                      applyToAll = false;
                    }
                  } else if (applyToAll == true) {
                    await dbHelper.insertWord({
                      DatabaseHelper.COLUMN_ABBREVIATION: abbreviation,
                      DatabaseHelper.COLUMN_MEANING: meaning,
                      DatabaseHelper.COLUMN_FULL_FORM: fullForm,
                      DatabaseHelper.COLUMN_CATEGORY: category,
                    });
                    importedCount++;
                  }
                } else {
                  await dbHelper.insertWord({
                    DatabaseHelper.COLUMN_ABBREVIATION: abbreviation,
                    DatabaseHelper.COLUMN_MEANING: meaning,
                    DatabaseHelper.COLUMN_FULL_FORM: fullForm,
                    DatabaseHelper.COLUMN_CATEGORY: category,
                  });
                  importedCount++;
                }
              }
            }
          }

          Navigator.of(context).pop(); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã import $importedCount từ từ Excel.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi khi đọc file Excel.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } finally {
          setState(() {
            _isImporting = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Chưa chọn file Excel.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addWordManually() async {
    final abbreviation = _englishController.text.trim();
    final meaning = _vietnameseController.text.trim();
    final fullForm = _fullFormController.text.trim();
    final category = _categoryController.text.trim();

    if (abbreviation.isNotEmpty && meaning.isNotEmpty) {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertWord({
        DatabaseHelper.COLUMN_ABBREVIATION: abbreviation,
        DatabaseHelper.COLUMN_MEANING: meaning,
        DatabaseHelper.COLUMN_FULL_FORM: fullForm,
        DatabaseHelper.COLUMN_CATEGORY: category,
      });

      _englishController.clear();
      _vietnameseController.clear();
      _fullFormController.clear();
      _categoryController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã thêm từ "$abbreviation".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Vui lòng nhập ít nhất từ viết tắt và nghĩa.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadSampleExcel() async {
    try {
      // 1. Đọc file từ assets
      final byteData = await rootBundle.load('assets/sample_words.xlsx');

      // 2. Lấy thư mục tạm
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/sample_words.xlsx');

      // 3. Ghi file
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // 4. Lưu file về máy người dùng (Android/iOS/Web)
      final saved = await FileSaver.instance.saveFile(
        name: "sample_words",
        bytes: byteData.buffer.asUint8List(),
        ext: "xlsx",
        // mimeType: MimeType(
        //   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', name: '',
        // ),
      );

      print('✅ File đã lưu: $saved');
    } catch (e) {
      print('❌ Lỗi khi tải file mẫu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'Thêm từ mới'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SectionTitle(
              icon: Icons.info_outline,
              title: 'Hướng dẫn định dạng file',
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📄 Cấu trúc file Excel cần có:',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Cột A: Từ viết tắt (bắt buộc)',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    '• Cột B: Nghĩa rõ (bắt buộc)',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    '• Cột C: Từ viết đủ (tuỳ chọn)',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    '• Cột D: Loại chuyên ngành (tuỳ chọn)',
                    style: textTheme.bodyMedium,
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _downloadSampleExcel,
                      icon: Icon(Icons.download, color: colorScheme.primary),
                      label: Text(
                        'Tải file mẫu',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _importFromExcel,
              icon: Icon(Icons.upload_file),
              label: Text('Chọn file Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: Size.fromHeight(48),
                textStyle: textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 32),

            SectionTitle(icon: Icons.edit_note, title: 'Nhập Từ Thủ Công'),
            SizedBox(height: 8),
            _buildTextField(_englishController, 'Từ viết tắt', context),
            SizedBox(height: 12),
            _buildTextField(_vietnameseController, 'Nghĩa rõ', context),
            SizedBox(height: 12),
            _buildTextField(_fullFormController, 'Từ viết đủ', context),
            SizedBox(height: 12),
            _buildTextField(_categoryController, 'Loại chuyên ngành', context),
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addWordManually,
                icon: Icon(Icons.add_circle_outline),
                label: Text('Thêm Từ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  // textStyle: textTheme.titleMedium,
                ),
              ),
            ),

            Container(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.labelLarge,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
