import 'package:flutter/material.dart';
import 'package:hckt/ExportWordsScreen.dart';
import 'package:hckt/add_work_screen.dart';
import 'package:hckt/home_screen.dart';
import 'package:hckt/save_word_screen.dart';
import 'package:animations/animations.dart';
import 'dart:ui';

import 'RecentlyViewedScreen.dart';
import 'SettingsScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    SavedWordsScreen(),
    AddWordScreen(),
    ExportWordsScreen(),
    RecentlyViewedScreen(),
    SettingsScreen(), // 👈 Thêm dòng này
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder:
              (child, animation, secondaryAnimation) => SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                child: child,
              ),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              backgroundColor: Colors.white.withOpacity(0.6),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Tra cứu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark),
                  label: 'Đã lưu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  label: 'Thêm từ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.file_download),
                  label: 'Xuất từ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Đã xem',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Cài đặt',
                ),
              ],

              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.primary,

              unselectedItemColor: Colors.grey[600],
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
