import 'dart:convert';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static const String TABLE_NAME = 'dictionary';
  static const String COLUMN_ID = 'id';
  static const String COLUMN_ABBREVIATION = 'abbreviation';
  static const String COLUMN_FULL_FORM = 'full_form';
  static const String COLUMN_MEANING = 'meaning';
  static const String COLUMN_CATEGORY = 'category';

  static DatabaseHelper? _instance;

  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  DatabaseHelper._internal();

  Future<sqflite.Database?>? _sqfliteDatabase;

  Future<sqflite.Database?> get sqfliteDb async {
    if (UniversalPlatform.isWeb) return null;
    _sqfliteDatabase ??= _initSqfliteDatabase();
    return await _sqfliteDatabase;
  }

  Future<sqflite.Database?> _initSqfliteDatabase() async {
    if (UniversalPlatform.isWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'dictionary.db');
    return await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _createSqfliteDb,
    );
  }

  Future<void> _createSqfliteDb(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE $TABLE_NAME (
        $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $COLUMN_ABBREVIATION TEXT NOT NULL,
        $COLUMN_FULL_FORM TEXT,
        $COLUMN_MEANING TEXT NOT NULL,
        $COLUMN_CATEGORY TEXT
      )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS recent_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      abbreviation TEXT,
      full_form TEXT,
      meaning TEXT,
      timestamp INTEGER
    )
  ''');
    await db.execute('''
     CREATE TABLE saved_words (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  abbreviation TEXT,
  full_form TEXT,
  meaning TEXT,
  category TEXT
)

    ''');
  }

  Future<void> deleteSavedWordByFullForm(String fullForm) async {
    final db = await sqfliteDb;
    await db?.delete(
      'saved_words',
      where: 'full_form = ?',
      whereArgs: [fullForm],
    );
  }

  Future<void> addSavedWord(Map<String, dynamic> word) async {
    final db = await sqfliteDb;

    final existing = await db?.query(
      'saved_words',
      where: 'full_form = ?', // 👈 chỉ kiểm tra trùng full_form
      whereArgs: [word['full_form']],
    );

    if (existing!.isEmpty) {
      // Tạo bản sao không có trường 'id'
      final wordToSave = Map<String, dynamic>.from(word);
      wordToSave.remove('id');

      await db!.insert('saved_words', wordToSave);
    }
  }

  Future<bool?> isRecentWordExists(String abbreviation) async {
    final db = await sqfliteDb;
    final result = await db?.query(
      'recent_words',
      where: 'abbreviation = ?',
      whereArgs: [abbreviation],
      limit: 1,
    );
    return result?.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>?> getRecentWords() async {
    final db = await sqfliteDb;
    return await db?.query('recent_words');
  }

  Future<void> addRecentWord(Map<String, dynamic> word) async {
    final db = await sqfliteDb;
    await db?.insert('recent_words', {
      'abbreviation': word['abbreviation'],
      'full_form': word['full_form'],
      'meaning': word['meaning'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  // Mobile
  Future<int> insertWordMobile(Map<String, String> word) async {
    if (UniversalPlatform.isWeb) return -1;
    final db = await sqfliteDb;
    if (db == null) return -1;
    return await db.insert(
      TABLE_NAME,
      word,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllWordsMobile() async {
    final db = await sqfliteDb;
    if (db == null) return [];
    return await db.query(TABLE_NAME);
  }

  Future<int> saveWordMobile(Map<String, String> word) async {
    final db = await sqfliteDb;
    if (db == null) return -1;
    return await db.insert(
      'saved_words',
      word,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllSavedWordsMobile() async {
    final db = await sqfliteDb;
    if (db == null) return [];
    return await db.query('saved_words');
  }

  // Web
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> insertWordWeb(Map<String, String> word) async {
    final prefs = await _prefs;
    String key = word[COLUMN_ABBREVIATION]!;
    await prefs.setString(key, jsonEncode(word));
  }

  Future<List<Map<String, dynamic>>> getAllWordsWeb() async {
    final prefs = await _prefs;
    final allKeys = prefs.getKeys().where((k) => !k.startsWith('saved_'));
    List<Map<String, dynamic>> words = [];
    for (String key in allKeys) {
      String? json = prefs.getString(key);
      if (json != null) {
        final map = jsonDecode(json);
        words.add({
          COLUMN_ABBREVIATION: key,
          COLUMN_FULL_FORM: map[COLUMN_FULL_FORM],
          COLUMN_MEANING: map[COLUMN_MEANING],
          COLUMN_CATEGORY: map[COLUMN_CATEGORY],
        });
      }
    }
    return words;
  }

  Future<void> saveWordWeb(Map<String, String> word) async {
    final prefs = await _prefs;
    await prefs.setString(
      'saved_${word[COLUMN_ABBREVIATION]}',
      jsonEncode(word),
    );
  }

  Future<List<Map<String, dynamic>>> getAllSavedWordsWeb() async {
    final prefs = await _prefs;
    final savedKeys = prefs.getKeys().where((k) => k.startsWith('saved_'));
    List<Map<String, dynamic>> savedWords = [];
    for (String key in savedKeys) {
      String? json = prefs.getString(key);
      if (json != null) {
        final map = jsonDecode(json);
        savedWords.add({
          COLUMN_ABBREVIATION: key.substring(6),
          COLUMN_FULL_FORM: map[COLUMN_FULL_FORM],
          COLUMN_MEANING: map[COLUMN_MEANING],
          COLUMN_CATEGORY: map[COLUMN_CATEGORY],
        });
      }
    }
    print("Dữ liệu đã lưu (Web): $savedWords");
    return savedWords;
  }

  // Cross-platform
  Future<int> insertWord(Map<String, String> word) async {
    if (UniversalPlatform.isWeb) {
      await insertWordWeb(word);
      return 1;
    } else {
      return await insertWordMobile(word);
    }
  }

  Future<List<Map<String, dynamic>>> getAllWords() async {
    return UniversalPlatform.isWeb
        ? await getAllWordsWeb()
        : await getAllWordsMobile();
  }

  Future<void> saveWord(Map<String, String> word) async {
    if (UniversalPlatform.isWeb) {
      await saveWordWeb(word);
    } else {
      await saveWordMobile(word);
    }
  }

  Future<List<Map<String, dynamic>>> getAllSavedWords() async {
    return UniversalPlatform.isWeb
        ? await getAllSavedWordsWeb()
        : await getAllSavedWordsMobile();
  }

  Future<void> deleteSavedWord(String abbreviation) async {
    if (UniversalPlatform.isWeb) {
      final prefs = await _prefs;
      await prefs.remove('saved_$abbreviation');
    } else {
      final db = await sqfliteDb;
      if (db != null) {
        await db.delete(
          'saved_words',
          where: 'abbreviation = ?',
          whereArgs: [abbreviation],
        );
      }
    }
  }

  Future<Map<String, dynamic>?> getWordByAbbreviation(
    String abbreviation,
  ) async {
    if (UniversalPlatform.isWeb) {
      final prefs = await _prefs;
      final json = prefs.getString(abbreviation);
      if (json != null) {
        final map = jsonDecode(json);
        return {
          COLUMN_ABBREVIATION: abbreviation,
          COLUMN_FULL_FORM: map[COLUMN_FULL_FORM],
          COLUMN_MEANING: map[COLUMN_MEANING],
          COLUMN_CATEGORY: map[COLUMN_CATEGORY],
        };
      }
      return null;
    } else {
      final db = await sqfliteDb;
      if (db == null) return null;
      final result = await db.query(
        TABLE_NAME,
        where: '$COLUMN_ABBREVIATION = ?',
        whereArgs: [abbreviation],
      );
      return result.isNotEmpty ? result.first : null;
    }
  }

  Future<void> updateWord(
    int id,
    String abbreviation,
    String fullForm,
    String meaning,
    String category,
  ) async {
    final db = await sqfliteDb;
    await db?.update(
      TABLE_NAME,
      {
        COLUMN_ABBREVIATION: abbreviation,
        COLUMN_FULL_FORM: fullForm,
        COLUMN_MEANING: meaning,
        COLUMN_CATEGORY: category,
      },
      where: '$COLUMN_ID = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWord(int id) async {
    final db = await sqfliteDb;
    await db?.delete(TABLE_NAME, where: '$COLUMN_ID = ?', whereArgs: [id]);
  }
}
