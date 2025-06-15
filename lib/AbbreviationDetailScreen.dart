import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 👈 thêm dòng này

import 'DatabaseHelper.dart';
import 'custom_appbar.dart';

class AbbreviationDetailScreen extends StatefulWidget {
  final String abbreviation;
  final String fullWord;
  final List<Map<String, dynamic>> words;

  const AbbreviationDetailScreen({
    required this.abbreviation,
    required this.fullWord,
    required this.words,
  });

  @override
  State<AbbreviationDetailScreen> createState() =>
      _AbbreviationDetailScreenState();
}

class _AbbreviationDetailScreenState extends State<AbbreviationDetailScreen> {
  late Map<String, List<Map<String, dynamic>>> groupedByCategory;
  final FlutterTts _flutterTts = FlutterTts(); // 👈 thêm dòng này
  String _selectedLanguage = 'ru-RU';
  List<String> _supportedLanguages = [
    'ru-RU', // Russian
    'vi-VN', // Vietnamese
    'en-US', // English (US)
    'ja-JP', // Japanese
    'zh-CN', // Chinese (Simplified)
  ];
  final Map<String, String> _languageLabels = {
    'ru-RU': 'Tiếng Nga',
    'vi-VN': 'Tiếng Việt',
    'en-US': 'English (US)',
    'ja-JP': '日本語 (Tiếng Nhật)',
    'zh-CN': '中文 (Giản thể)',
  };
  @override
  void initState() {
    super.initState();
    _groupWordsByCategory();
    _groupWordsByCategory();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.4);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // 👈 dọn tài nguyên khi thoát màn
    super.dispose();
  }

  void _groupWordsByCategory() {
    groupedByCategory = {};
    for (var word in widget.words) {
      final category = (word['category'] ?? 'Khác').toString().trim();
      groupedByCategory.putIfAbsent(category, () => []).add(word);
    }
  }

  // Future<void> _speak(String text) async {
  //   await _flutterTts.speak(text);
  // }

  Widget _buildWordItem(Map<String, dynamic> word) {
    final fullForm = word['full_form'] ?? '';
    final meaning = word['meaning'] ?? '';

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Từ đầy đủ:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.green),
                  tooltip: 'Đọc từ',
                  onPressed: () => _speak(fullForm), // 👈 gọi TTS
                ),
                IconButton(
                  icon: Icon(Icons.bookmark_add, color: Colors.orange),
                  tooltip: 'Lưu từ này',
                  onPressed: () async {
                    await DatabaseHelper().addSavedWord(word);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã lưu từ "$fullForm"')),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                fullForm,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.translate, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Nghĩa:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                meaning,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Chi tiết từ viết tắt'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'abbr_${widget.abbreviation}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.abbreviation,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Danh sách từ theo chuyên ngành:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Chọn ngôn ngữ đọc:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(width: 12),

                DropdownButton<String>(
                  value: _selectedLanguage,
                  items:
                      _supportedLanguages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(_languageLabels[lang] ?? lang),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                      _flutterTts.setLanguage(value);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 12),

            Expanded(
              child: ListView(
                children:
                    groupedByCategory.entries.map((entry) {
                      final category = entry.key;
                      final words = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '🔹 $category',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...words.map(_buildWordItem).toList(),
                          SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
