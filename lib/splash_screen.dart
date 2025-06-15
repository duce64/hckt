import 'package:flutter/material.dart';
import 'package:hckt/home.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Chờ 2 giây rồi chuyển sang MainScreen
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            Lottie.asset(
              'assets/animation.json', // tải animation từ LottieFiles
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 30),

            // Hiệu ứng gõ chữ
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              child: AnimatedTextKit(
                // isRepeatingCursor: false,
                totalRepeatCount: 1,
                animatedTexts: [
                  TypewriterAnimatedText('TỪ ĐIỂN CHUYÊN NGÀNH',
                      speed: Duration(milliseconds: 100)),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Slogan
            AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 2),
              child: Text(
                '"Tra cứu mọi nơi - mọi lúc"',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.indigo[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
