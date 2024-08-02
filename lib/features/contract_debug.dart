import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:share_plus/share_plus.dart';

class ContractFeatureDebug extends StatefulWidget {
  @override
  _ContractFeatureDebugState createState() => _ContractFeatureDebugState();
}

class _ContractFeatureDebugState extends State<ContractFeatureDebug> {
  SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  ui.Image? contractImage;
  ui.Image? combinedImage; // Initialize combinedImage
  bool isImageLoaded = false;
  bool isSignatureMode = false;
  bool isTextInputMode = false;

  Rect? selectedArea;
  TextEditingController textEditingController = TextEditingController();
  List<Rect> predefinedAreas = [];
  double signatureHeight = 0.0;

  @override
  void initState() {
    super.initState();
    copyAssetFileToLocalDir('assets/contract.xlsx', 'contract.xlsx');
    loadContractImage();
  }

  Future<void> loadContractImage() async {
    ByteData data = await rootBundle.load('assets/contract_image.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      contractImage = frame.image;
      isImageLoaded = true;
      predefinedAreas = _calculatePredefinedAreas(
          contractImage!.width.toDouble(), contractImage!.height.toDouble());
    });
  }

  List<Rect> _calculatePredefinedAreas(double imageWidth, double imageHeight) {
    return [
      Rect.fromLTWH(imageWidth * 0.6, imageHeight * 0.12, imageWidth * 0.1,
          imageHeight * 0.023), // H5 양도인 이름
      Rect.fromLTWH(imageWidth * 0.6, imageHeight * 0.143, imageWidth * 0.1,
          imageHeight * 0.023), // H6 양수인 이름
      Rect.fromLTWH(imageWidth * 0.85, imageHeight * 0.115, imageWidth * 0.15,
          imageHeight * 0.023), // K5 양도인 서명
      Rect.fromLTWH(imageWidth * 0.85, imageHeight * 0.138, imageWidth * 0.15,
          imageHeight * 0.023), // K6 양수인 서명
      Rect.fromLTWH(imageWidth * 0.125, imageHeight * 0.196, imageWidth * 0.311,
          imageHeight * 0.023), // C9 자동차등록번호
      Rect.fromLTWH(imageWidth * 0.545, imageHeight * 0.196, imageWidth * 0.452,
          imageHeight * 0.023), // G9 매매금액
      Rect.fromLTWH(imageWidth * 0.125, imageHeight * 0.221, imageWidth * 0.16,
          imageHeight * 0.023), // C10 차종
      Rect.fromLTWH(imageWidth * 0.125, imageHeight * 0.244, imageWidth * 0.311,
          imageHeight * 0.023), // G10-K10 차명
      Rect.fromLTWH(imageWidth * 0.125, imageHeight * 0.267, imageWidth * 0.311,
          imageHeight * 0.023), // C12 차대번호
      Rect.fromLTWH(imageWidth * 0.125, imageHeight * 0.290, imageWidth * 0.311,
          imageHeight * 0.023), // C13 등록비용
      Rect.fromLTWH(imageWidth * 0.545, imageHeight * 0.221, imageWidth * 0.452,
          imageHeight * 0.023), // G10-K10 리스승계
      Rect.fromLTWH(imageWidth * 0.545, imageHeight * 0.244, imageWidth * 0.452,
          imageHeight * 0.023), // G11-K11 인도금
      Rect.fromLTWH(imageWidth * 0.545, imageHeight * 0.267, imageWidth * 0.452,
          imageHeight * 0.023), // G12-K12 잔금
      Rect.fromLTWH(imageWidth * 0.545, imageHeight * 0.290, imageWidth * 0.452,
          imageHeight * 0.023), // G13 비고
      Rect.fromLTWH(imageWidth * 0.285, imageHeight * 0.132, imageWidth * 0.2,
          imageHeight * 0.023), // A5 상단 날짜
      // 하단
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.770, imageWidth * 0.72,
          imageHeight * 0.023), // A5 계약년월일
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.794, imageWidth * 0.482,
          imageHeight * 0.023), // D43 양도인 성명
      Rect.fromLTWH(imageWidth * 0.764, imageHeight * 0.794, imageWidth * 0.238,
          imageHeight * 0.023), // J43 양도인 서명 또는 날인
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.818, imageWidth * 0.482,
          imageHeight * 0.023), // D44 양도인 주민등록(사업자)번호
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.843, imageWidth * 0.482,
          imageHeight * 0.023), // D45 양도인 주소및전화번호
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.867, imageWidth * 0.482,
          imageHeight * 0.023), // D46 양수인 성명
      Rect.fromLTWH(imageWidth * 0.764, imageHeight * 0.867, imageWidth * 0.238,
          imageHeight * 0.023), // J46 양수인 서명 또는 날인
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.892, imageWidth * 0.482,
          imageHeight * 0.023), // D47 양수인 주민등록(사업자)번호
      Rect.fromLTWH(imageWidth * 0.282, imageHeight * 0.916, imageWidth * 0.482,
          imageHeight * 0.023), // D48 양수인 주소민전화번호
    ];
  }

  Future<ui.Image> _signatureToImage() async {
    final signatureBytes = await _controller.toPngBytes();
    final codec = await ui.instantiateImageCodec(signatureBytes!);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _textToImage(
      String text, double width, double height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));
    final picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }

  Future<ui.Image> _combineImages(
      ui.Image baseImage, ui.Image overlayImage, Rect rect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromLTWH(
            0, 0, baseImage.width.toDouble(), baseImage.height.toDouble()));
    final paint = Paint();

    canvas.drawImage(baseImage, Offset(0, 0), paint);

    final srcRect = Rect.fromLTWH(
        0, 0, overlayImage.width.toDouble(), overlayImage.height.toDouble());
    canvas.drawImageRect(overlayImage, srcRect, rect, paint);

    final picture = recorder.endRecording();
    return picture.toImage(baseImage.width, baseImage.height);
  }

  Future<String> getFilePath(String fileName) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path;
    return '$path/$fileName';
  }

  Future<void> _saveImage(ui.Image image, String fileName) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(buffer);
    print('Image saved at $filePath');
  }

  void _saveSignatureOrText() async {
    if (selectedArea != null) {
      ui.Image? overlayImage;

      if (isSignatureMode) {
        overlayImage = await _signatureToImage();
      } else if (isTextInputMode) {
        overlayImage = await _textToImage(textEditingController.text,
            selectedArea!.width, selectedArea!.height);
      }

      if (overlayImage != null) {
        final updatedImage =
            await _combineImages(contractImage!, overlayImage, selectedArea!);
        await _saveImage(updatedImage, 'contract_with_overlay.png');

        setState(() {
          combinedImage = updatedImage;
          contractImage =
              updatedImage; // Update contractImage to the combined image
        });
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('셀을 선택하세요.')));
    }
  }

  Future<void> copyAssetFileToLocalDir(
      String assetPath, String localFileName) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    String localPath = await getFilePath(localFileName);
    File localFile = File(localPath);
    await localFile.writeAsBytes(bytes);
  }

  void _handleCellSelection(Rect area) {
    setState(() {
      selectedArea = area;
      isSignatureMode = false;
      isTextInputMode = false;

      if (selectedArea != null) {
        double aspectRatio = selectedArea!.width / selectedArea!.height;
        signatureHeight = MediaQuery.of(context).size.width / aspectRatio;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('계약서 서명 기능'),
      ),
      body: Column(
        children: [
          if (isImageLoaded)
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  final imageScale =
                      MediaQuery.of(context).size.width / contractImage!.width;
                  final scaledHeight = contractImage!.height * imageScale;
                  final imageTopOffset = (MediaQuery.of(context).size.height -
                          scaledHeight * 1.23) /
                      2;

                  final touchPosition = Offset(
                    details.localPosition.dx / imageScale,
                    (details.localPosition.dy - imageTopOffset) / imageScale,
                  );

                  final tappedArea = predefinedAreas.firstWhere(
                    (area) => (area).contains(touchPosition),
                  );

                  if (tappedArea != null) {
                    _handleCellSelection(tappedArea);
                  }
                },
                child: CustomPaint(
                  size: Size(double.infinity, double.infinity),
                  painter: ContractPainter(
                    contractImage!,
                    predefinedAreas,
                    selectedArea,
                    combinedImage, // Pass the combinedImage to the painter
                  ),
                ),
              ),
            ),
          if (isSignatureMode)
            Container(
              width: MediaQuery.of(context).size.width,
              height: signatureHeight,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.lightBlueAccent,
              ),
            ),
          if (isTextInputMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '텍스트를 입력하세요',
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isSignatureMode = true;
                      isTextInputMode = false;
                    });
                  },
                  child: Text('서명'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isTextInputMode = true;
                      isSignatureMode = false;
                    });
                  },
                  child: Text('텍스트 입력'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveSignatureOrText();
                  },
                  child: Text('저장'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    String localPath = await getFilePath('contract.xlsx');
                    String newFilePath = await getFilePath('new_contract.xlsx');
                    File localFile = File(localPath);
                    File newFile = File(newFilePath);
                    await newFile.writeAsBytes(await localFile.readAsBytes());
                    Share.shareFiles([newFilePath], text: '새로운 계약서 엑셀 파일');
                  },
                  child: Text('내보내기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContractPainter extends CustomPainter {
  final ui.Image contractImage;
  final List<Rect> predefinedAreas;
  final Rect? selectedArea;
  final ui.Image? combinedImage;

  ContractPainter(
    this.contractImage,
    this.predefinedAreas,
    this.selectedArea,
    this.combinedImage,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final imageScale = size.width / contractImage.width;
    final scaledHeight = contractImage.height * imageScale;
    final centeredTop = (size.height - scaledHeight) / 2;

    // 계약서 이미지 그리기
    canvas.drawImageRect(
      contractImage,
      Rect.fromLTWH(0, 0, contractImage.width.toDouble(),
          contractImage.height.toDouble()),
      Rect.fromLTWH(0, centeredTop, size.width, scaledHeight),
      paint,
    );

    // Draw combined image if available
    if (combinedImage != null) {
      canvas.drawImageRect(
        combinedImage!,
        Rect.fromLTWH(0, 0, combinedImage!.width.toDouble(),
            combinedImage!.height.toDouble()),
        Rect.fromLTWH(0, centeredTop, size.width, scaledHeight),
        paint,
      );
    }

    // 미리 정의된 영역 그리기
    for (Rect area in predefinedAreas) {
      final scaledRect = Rect.fromLTWH(
        area.left * imageScale,
        centeredTop + area.top * imageScale,
        area.width * imageScale,
        area.height * imageScale,
      );
      final rectPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(scaledRect, rectPaint);
    }

    // 선택된 영역 그리기
    if (selectedArea != null) {
      final scaledSelectedRect = Rect.fromLTWH(
        selectedArea!.left * imageScale,
        centeredTop + selectedArea!.top * imageScale,
        selectedArea!.width * imageScale,
        selectedArea!.height * imageScale,
      );
      final selectedPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(scaledSelectedRect, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}