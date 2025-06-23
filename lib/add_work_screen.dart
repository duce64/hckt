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
import 'dart:convert';
import 'package:csv/csv.dart';

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

  Future<void> _importFromCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Chưa chọn file CSV.')));
      return;
    }

    Uint8List? fileBytes = result.files.single.bytes;
    if (fileBytes == null && result.files.single.path != null) {
      fileBytes = await File(result.files.single.path!).readAsBytes();
    }

    if (fileBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Không thể đọc file CSV.')));
      return;
    }

    setState(() => _isImporting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      String csvString = utf8.decode(fileBytes);

      // Làm sạch toàn bộ dấu ngoặc kép " để tránh lỗi
      csvString = csvString.replaceAll('"', '');

      final rows = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ';',
      );

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('❌ File CSV không có dữ liệu.');
      }

      final dbHelper = DatabaseHelper();
      final allWords = await dbHelper.getAllWords();

      final existingMap = {
        for (var word in allWords) word['abbreviation'].toString().trim(): word,
      };

      int importedCount = 0;
      bool? applyToAllOverwrite;
      bool? applyToAllSkip;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        try {
          final abbreviation = row[0]?.toString().trim() ?? '';
          final meaning = row[1]?.toString().trim() ?? '';
          final fullForm =
              row.length > 2 ? row[2]?.toString().trim() ?? '' : '';
          final category =
              row.length > 3
                  ? row[3].toString().replaceAll(',', '').trim()
                  : '';

          if (abbreviation.isEmpty || meaning.isEmpty) continue;

          if (existingMap.containsKey(abbreviation)) {
            if (applyToAllSkip == true) continue;
            if (applyToAllOverwrite == true) {
              await dbHelper.insertWord({
                'abbreviation': abbreviation,
                'meaning': meaning,
                'full_form': fullForm,
                'category': category,
              });
              importedCount++;
              continue;
            }

            final result = await showDialog<String>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Từ "$abbreviation" đã tồn tại'),
                    content: Text(
                      'Nghĩa cũ: "${existingMap[abbreviation]?['meaning']}"\n'
                      'Nghĩa mới: "$meaning"',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'skip'),
                        child: Text('Bỏ qua'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'overwrite'),
                        child: Text('Ghi đè'),
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pop(context, 'overwrite_all'),
                        child: Text('Ghi đè tất cả'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'skip_all'),
                        child: Text('Bỏ qua tất cả'),
                      ),
                    ],
                  ),
            );

            if (result == 'skip') continue;
            if (result == 'skip_all') {
              applyToAllSkip = true;
              continue;
            }

            await dbHelper.insertWord({
              'abbreviation': abbreviation,
              'meaning': meaning,
              'full_form': fullForm,
              'category': category,
            });
            importedCount++;

            if (result == 'overwrite_all') {
              applyToAllOverwrite = true;
            }
          } else {
            await dbHelper.insertWord({
              'abbreviation': abbreviation,
              'meaning': meaning,
              'full_form': fullForm,
              'category': category,
            });
            importedCount++;
          }
        } catch (e) {
          print('⚠️ Lỗi dòng ${i + 1}: $row');
          print('Chi tiết: $e');
          continue;
        }
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Đã import $importedCount từ từ CSV.')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Lỗi khi đọc file CSV: $e')));
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Chưa chọn file Excel.')));
      return;
    }

    Uint8List? fileBytes = result.files.single.bytes;
    if (fileBytes == null && result.files.single.path != null) {
      fileBytes = await File(result.files.single.path!).readAsBytes();
    }

    if (fileBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Không thể đọc file Excel.')));
      return;
    }

    setState(() => _isImporting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final excel = Excel.decodeBytes(fileBytes);
      final dbHelper = DatabaseHelper();
      final allWords = await dbHelper.getAllWords();

      final existingMap = {
        for (var word in allWords) word['abbreviation'].toString().trim(): word,
      };

      int importedCount = 0;
      bool? applyToAllOverwrite;
      bool? applyToAllSkip;

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          if (row.length < 2 || row[0] == null || row[1] == null) continue;

          var abbreviation =
              row.length > 0 ? row[0]?.value?.toString().trim() ?? '' : '';
          var meaning =
              row.length > 1 ? row[1]?.value?.toString().trim() ?? '' : '';
          var fullForm =
              row.length > 2 ? row[2]?.value?.toString().trim() ?? '' : '';
          var category =
              row.length > 3 ? row[3]?.value?.toString().trim() ?? '' : '';

          if (abbreviation.isEmpty || meaning.isEmpty) continue;

          if (existingMap.containsKey(abbreviation)) {
            if (applyToAllSkip == true) continue;
            if (applyToAllOverwrite == true) {
              await dbHelper.insertWord({
                'abbreviation': abbreviation,
                'meaning': meaning,
                'full_form': fullForm,
                'category': category,
              });
              importedCount++;
              continue;
            }

            // hỏi người dùng
            final result = await showDialog<String>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Từ "$abbreviation" đã tồn tại'),
                    content: Text(
                      'Nghĩa cũ: "${existingMap[abbreviation]?['meaning']}"\n'
                      'Nghĩa mới: "$meaning"',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'skip'),
                        child: Text('Bỏ qua'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'overwrite'),
                        child: Text('Ghi đè'),
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pop(context, 'overwrite_all'),
                        child: Text('Ghi đè tất cả'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'skip_all'),
                        child: Text('Bỏ qua tất cả'),
                      ),
                    ],
                  ),
            );

            if (result == 'skip') {
              continue;
            } else if (result == 'overwrite') {
              await dbHelper.insertWord({
                'abbreviation': abbreviation,
                'meaning': meaning,
                'full_form': fullForm,
                'category': category,
              });
              importedCount++;
            } else if (result == 'overwrite_all') {
              applyToAllOverwrite = true;
              await dbHelper.insertWord({
                'abbreviation': abbreviation,
                'meaning': meaning,
                'full_form': fullForm,
                'category': category,
              });
              importedCount++;
            } else if (result == 'skip_all') {
              applyToAllSkip = true;
              continue;
            }
          } else {
            await dbHelper.insertWord({
              'abbreviation': abbreviation,
              'meaning': meaning,
              'full_form': fullForm,
              'category': category,
            });
            importedCount++;
          }
        }
      }

      Navigator.of(context).pop(); // đóng loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Đã import $importedCount từ từ Excel.')),
      );
    } catch (e) {
      Navigator.of(context).pop(); // đóng loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Lỗi khi đọc file Excel.')));
    } finally {
      setState(() => _isImporting = false);
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
      final byteData = await rootBundle.load('assets/sample_csv.csv');

      // 2. Lấy thư mục tạm
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/sample_csv.csv');

      // 3. Ghi file
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // 4. Lưu file về máy người dùng (Android/iOS/Web)
      final saved = await FileSaver.instance.saveFile(
        name: "sample_words2",
        bytes: byteData.buffer.asUint8List(),
        ext: "csv",
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
                          '📄 Cấu trúc file cần có (Excel hoặc CSV):',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Cột 1: Từ viết tắt (bắt buộc)',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          '• Cột 2: Nghĩa rõ (bắt buộc)',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          '• Cột 3: Từ viết đủ (tuỳ chọn)',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          '• Cột 4: Loại chuyên ngành (tuỳ chọn)',
                          style: textTheme.bodyMedium,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '📌 Lưu ý đối với file CSV:',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          '• Dùng dấu `;` để phân cách các cột.',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          '• Nếu dữ liệu có dấu `;`, hãy đặt toàn bộ ô đó trong dấu ngoặc kép "..."',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          '• Mã hóa UTF-8 để tránh lỗi ký tự.',
                          style: textTheme.bodyMedium,
                        ),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _downloadSampleExcel,
                            icon: Icon(
                              Icons.download,
                              color: colorScheme.primary,
                            ),
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
                ],
              ),
            ),

            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _importFromCsv,
              icon: Icon(Icons.upload_file),
              label: Text('Chọn file CSV'),
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
            _buildCategoryInputField(context),

            // _buildTextField(_categoryController, 'Loại chuyên ngành', context),
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

  Widget _buildCategoryInputField(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Loại chuyên ngành',
              border: OutlineInputBorder(),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: _selectCategoryFromList,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          ),
          child: Icon(Icons.list_alt),
        ),
      ],
    );
  }

  Future<void> _selectCategoryFromList() async {
    final categories = await _getAllCategories();
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Chưa có chuyên ngành nào trong dữ liệu.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => Divider(height: 1),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category),
              onTap: () => Navigator.pop(context, category),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _categoryController.text = selected;
      });
    }
  }

  Future<List<String>> _getAllCategories() async {
    final allWords = await DatabaseHelper().getAllWords();
    final categories = <String>{};
    for (var word in allWords) {
      final cat = word['category']?.toString().trim();
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    return categories.toList()..sort();
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
