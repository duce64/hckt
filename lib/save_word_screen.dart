import 'package:flutter/material.dart';
import 'package:hckt/DatabaseHelper.dart';

import 'custom_appbar.dart';

class SavedWordsScreen extends StatefulWidget {
  @override
  _SavedWordsScreenState createState() => _SavedWordsScreenState();
}

class _SavedWordsScreenState extends State<SavedWordsScreen> {
  List<Map<String, dynamic>> _savedWords = [];
  List<Map<String, dynamic>> _filteredWords = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedWords();
    _searchController.addListener(() {
      _filterWords(_searchController.text);
    });
  }

  Future<void> _loadSavedWords() async {
    final dbHelper = DatabaseHelper();
    final savedWordsData = await dbHelper.getAllSavedWords();

    final wasEmpty = _savedWords.isEmpty; // Trước khi load mới

    setState(() {
      _savedWords = savedWordsData;
      _isLoading = false;
      _filteredWords = List.from(savedWordsData);
    });

    // 👇 Phản hồi cảm xúc nếu là từ đầu tiên được lưu
    if (wasEmpty && savedWordsData.length == 1) {
      Future.delayed(Duration(milliseconds: 300), () {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text('🎉 Chúc mừng!'),
                content: Text('Bạn vừa lưu từ đầu tiên thành công.'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      });
    }
  }

  void _filterWords(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredWords = List.from(_savedWords);
      });
    } else {
      final filtered =
          _savedWords.where((word) {
            final abbreviation = (word['abbreviation'] ?? '').toLowerCase();
            final fullForm = (word['full_form'] ?? '').toLowerCase();
            final meaning = (word['meaning'] ?? '').toLowerCase();
            return abbreviation.contains(query.toLowerCase()) ||
                fullForm.contains(query.toLowerCase()) ||
                meaning.contains(query.toLowerCase());
          }).toList();
      setState(() {
        _filteredWords = filtered;
      });
    }
  }

  Future<void> _deleteWordByFullForm(String fullForm) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteSavedWordByFullForm(fullForm); // 👈 sửa tên hàm
    _loadSavedWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Từ đã lưu'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,

              decoration: InputDecoration(
                hintText: 'Tìm kiếm từ đã lưu...',
                prefixIcon: Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterWords('');
                          },
                        )
                        : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Đã lưu ${_filteredWords.length} từ',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child:
                            _filteredWords.isEmpty
                                ? Center(
                                  child: Text('🙁 Không có từ nào phù hợp.'),
                                )
                                : ListView.builder(
                                  itemCount: _filteredWords.length,
                                  itemBuilder: (context, index) {
                                    final word = _filteredWords[index];
                                    final abbreviation =
                                        word['abbreviation'] ?? '';
                                    final fullForm = word['full_form'] ?? '';
                                    final meaning = word['meaning'] ?? '';

                                    return Card(
                                      margin: EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.bookmark,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        isThreeLine: true,
                                        title: Text(
                                          abbreviation,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Từ viết đủ: $fullForm',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            Text(
                                              'Nghĩa: $meaning',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (_) => AlertDialog(
                                                    title: Text('Xoá từ?'),
                                                    content: Text(
                                                      'Bạn có chắc muốn xoá từ "$fullForm" không?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: Text('Huỷ'),
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                      ),
                                                      ElevatedButton(
                                                        child: Text('Xoá'),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (confirm == true) {
                                              _deleteWordByFullForm(fullForm);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
