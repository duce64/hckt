import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hckt/DatabaseHelper.dart';

import 'AbbreviationDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allWords = [];
  bool _isAscending = true;
  String _selectedInitial = '';
  bool _isLoading = true;
  String _alphabetMode = 'latin'; // hoặc 'cyrillic'

  @override
  void initState() {
    super.initState();
    _loadDictionaryData();
    _searchController.addListener(() => _sortAndFilter());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDictionaryData() async {
    final allWords = await DatabaseHelper().getAllWords();
    setState(() {
      _allWords = allWords;
      _isLoading = false;
      _sortAndFilter();
    });
  }

  void _sortAndFilter() {
    List<Map<String, dynamic>> filtered = List.from(_allWords);

    if (_selectedInitial.isNotEmpty) {
      filtered =
          filtered.where((word) {
            final abbreviation = (word['abbreviation'] ?? '').toLowerCase();
            return abbreviation.startsWith(_selectedInitial.toLowerCase());
          }).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered =
          filtered
              .where(
                (word) =>
                    (word['abbreviation'] ?? '').toLowerCase().contains(
                      query,
                    ) ||
                    (word['full_form'] ?? '').toLowerCase().contains(query),
              )
              .toList();
    }

    final seen = <String>{};
    filtered =
        filtered.where((word) {
          final abbr = (word['abbreviation'] ?? '').toLowerCase();
          if (seen.contains(abbr)) return false;
          seen.add(abbr);
          return true;
        }).toList();

    filtered.sort(
      (a, b) =>
          _isAscending
              ? (a['abbreviation'] ?? '').toLowerCase().compareTo(
                (b['abbreviation'] ?? '').toLowerCase(),
              )
              : (b['abbreviation'] ?? '').toLowerCase().compareTo(
                (a['abbreviation'] ?? '').toLowerCase(),
              ),
    );

    setState(() {
      _searchResults = filtered;
    });
  }

  void _navigateToDetailScreen(Map<String, dynamic> word) async {
    final abbr = word['abbreviation'];
    final full = word['full_form'];
    final relatedWords =
        _allWords
            .where(
              (w) =>
                  (w['abbreviation'] ?? '').toLowerCase() ==
                  (abbr ?? '').toLowerCase(),
            )
            .toList();

    // 👉 Kiểm tra nếu từ đã có trong bảng recent_words thì không thêm nữa
    final exists = await DatabaseHelper().isRecentWordExists(
      word['abbreviation'],
    );
    if (!exists!) {
      await DatabaseHelper().addRecentWord(word);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AbbreviationDetailScreen(
              abbreviation: abbr ?? '',
              fullWord: full ?? '',
              words: relatedWords,
            ),
      ),
    );
  }

  Widget _buildInitialFilter() {
    final letters =
        _alphabetMode == 'latin'
            ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            : 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lọc theo chữ cái:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _alphabetMode,
              items: [
                DropdownMenuItem(value: 'latin', child: Text('Chữ Latin')),
                DropdownMenuItem(value: 'cyrillic', child: Text('Chữ Nga')),
              ],
              onChanged: (value) {
                setState(() {
                  _alphabetMode = value!;
                  _selectedInitial = '';
                  _sortAndFilter();
                });
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: letters.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (context, index) {
              final char = index == 0 ? '' : letters[index - 1];
              final isSelected = _selectedInitial == char;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedInitial = char;
                    _sortAndFilter();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      char.isEmpty ? 'Tất cả' : char,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          'Từ điển chuyên ngành',
          style: TextStyle(
            color: Colors.white, // ✅ Chữ trắng để nổi bật
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,

        foregroundColor: Colors.white, // ✅ Đảm bảo icon và text đều trắng
        actions: [
          IconButton(
            icon: Icon(Icons.sort_by_alpha),
            tooltip: _isAscending ? 'Sắp xếp A-Z' : 'Sắp xếp Z-A',
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortAndFilter();
              });
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),

                decoration: InputDecoration(
                  hintText: 'Tìm từ chuyên ngành...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _sortAndFilter();
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).inputDecorationTheme.fillColor ??
                      Theme.of(context).cardColor,
                ),
              ),
            ),

            SizedBox(height: 12),
            _buildInitialFilter(),
            SizedBox(height: 12),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SVG image
                            SizedBox(
                              height: 120,
                              child: SvgPicture.asset(
                                'assets/empty.svg',
                                semanticsLabel: 'Empty State',
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy từ nào',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final word = _searchResults[index];
                          final abbr = word['abbreviation'];
                          final count =
                              _allWords
                                  .where(
                                    (w) =>
                                        (w['abbreviation'] ?? '')
                                            .toLowerCase() ==
                                        (abbr ?? '').toLowerCase(),
                                  )
                                  .length;

                          return Slidable(
                            key: ValueKey(word['id']),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (_) async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            title: Text('Xác nhận xóa'),
                                            content: Text(
                                              'Bạn có chắc muốn xóa "${word['abbreviation']}" không?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      ctx,
                                                    ).pop(false),
                                                child: Text('Hủy'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      ctx,
                                                    ).pop(true),
                                                child: Text(
                                                  'Xóa',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm == true) {
                                      await DatabaseHelper().deleteWord(
                                        word['id'],
                                      );
                                      _loadDictionaryData();
                                    }
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Xóa',
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () => _navigateToDetailScreen(word),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (Theme.of(context).brightness ==
                                        Brightness.light)
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                      Icons.bookmark,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Hero(
                                    tag: 'abbr_${abbr ?? ''}',
                                    child: Text(
                                      abbr ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Có $count nghĩa với viết tắt "$abbr"',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  trailing: Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
