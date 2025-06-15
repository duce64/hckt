import 'package:flutter/material.dart';
import 'package:hckt/DatabaseHelper.dart';

import 'AbbreviationDetailScreen.dart';
import 'custom_appbar.dart';

class RecentlyViewedScreen extends StatefulWidget {
  @override
  _RecentlyViewedScreenState createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  List<Map<String, dynamic>> _recentWords = [];

  @override
  void initState() {
    super.initState();
    _loadRecentWords();
  }

  Future<void> _loadRecentWords() async {
    final recent = await DatabaseHelper().getRecentWords();
    setState(() {
      _recentWords = recent ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'Từ đã xem gần đây'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _recentWords.isEmpty
                ? Center(
                  child: Text(
                    'Bạn chưa xem từ nào gần đây.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
                : ListView.separated(
                  itemCount: _recentWords.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final word = _recentWords[index];
                    final abbr = word['abbreviation'] ?? '';
                    final fullForm = word['full_form'] ?? '';
                    final meaning = word['meaning'] ?? '';

                    return Card(
                      // color: colorScheme.surfaceVariant.withOpacity(0.3),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: Icon(
                          Icons.history,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          abbr,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Từ viết đủ: $fullForm',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'Nghĩa: $meaning',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final allWords = await DatabaseHelper().getAllWords();
                          final relatedWords =
                              allWords
                                  .where(
                                    (w) =>
                                        (w['abbreviation'] ?? '')
                                            .toLowerCase() ==
                                        abbr.toLowerCase(),
                                  )
                                  .toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AbbreviationDetailScreen(
                                    abbreviation: abbr,
                                    fullWord: fullForm,
                                    words: relatedWords,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
