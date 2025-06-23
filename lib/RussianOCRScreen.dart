// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:tesseract_ocr/ocr_engine_config.dart';
// import 'package:tesseract_ocr/tesseract_ocr.dart';
//
// class RussianOCRScreen extends StatefulWidget {
//   @override
//   _RussianOCRScreenState createState() => _RussianOCRScreenState();
// }
//
// class _RussianOCRScreenState extends State<RussianOCRScreen> {
//   late CameraController _cameraController;
//   bool _isInitialized = false;
//   String _resultText = '';
//   bool _isProcessing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     _cameraController = CameraController(
//       cameras.first,
//       ResolutionPreset.medium,
//     );
//     await _cameraController.initialize();
//     setState(() {
//       _isInitialized = true;
//     });
//   }
//
//   Future<void> _captureAndRecognize() async {
//     if (!_isInitialized) return;
//
//     setState(() => _isProcessing = true);
//
//     final file = await _cameraController.takePicture();
//
//     try {
//       final text = await TesseractOcr.extractText(
//         file.path,
//         config: OCRConfig(language: 'rus'),
//       );
//       setState(() {
//         _resultText = text.trim();
//       });
//     } catch (e) {
//       setState(() {
//         _resultText = '❌ OCR lỗi: $e';
//       });
//     }
//
//     setState(() => _isProcessing = false);
//   }
//
//   @override
//   void dispose() {
//     _cameraController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('OCR Tiếng Nga')),
//       body:
//           _isInitialized
//               ? Column(
//                 children: [
//                   AspectRatio(
//                     aspectRatio: _cameraController.value.aspectRatio,
//                     child: CameraPreview(_cameraController),
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _isProcessing ? null : _captureAndRecognize,
//                     child: Text('📸 Nhận diện'),
//                   ),
//                   if (_isProcessing) CircularProgressIndicator(),
//                   if (_resultText.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         children: [
//                           Text(
//                             '📄 Văn bản nhận được:',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           SizedBox(height: 8),
//                           Text(_resultText),
//                           SizedBox(height: 12),
//                           ElevatedButton(
//                             onPressed:
//                                 () => Navigator.pop(context, _resultText),
//                             child: Text('🔍 Dùng để tìm kiếm'),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               )
//               : Center(child: CircularProgressIndicator()),
//     );
//   }
// }
