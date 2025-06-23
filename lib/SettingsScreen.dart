import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';

import 'ExportedFilesScreen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String? lastExportedPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      lastExportedPath = prefs.getString('lastExportedFilePath');
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          SwitchListTile(
            title: Text('Chế độ tối', style: textTheme.titleMedium),
            subtitle: Text(
              'Khởi động lại ứng dụng để áp dụng thay đổi',
              style: textTheme.bodySmall,
            ),
            value: isDarkMode,
            onChanged: (value) {
              setState(() => isDarkMode = value);
              _saveSetting('isDarkMode', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔄 Khởi động lại để áp dụng chế độ tối'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            activeColor: colorScheme.primary,
          ),

          Divider(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quản lý',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.folder_copy, color: colorScheme.primary),
              title: Text(
                'Thư mục đã xuất',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  lastExportedPath != null
                      ? Text(
                        'Gần nhất: ${File(lastExportedPath!).uri.pathSegments.last}',
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      )
                      : Text(
                        'Chưa có file nào được xuất',
                        style: textTheme.bodySmall,
                      ),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExportedFilesScreen()),
                );
              },
              onLongPress: () async {
                if (lastExportedPath != null &&
                    await File(lastExportedPath!).exists()) {
                  OpenFile.open(lastExportedPath!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Không tìm thấy file gần nhất')),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 32),
          Center(
            child: Text(
              '© Bản quyền thuộc Trung đoàn 64',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
