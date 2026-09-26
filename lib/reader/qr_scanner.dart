import 'package:flutter/material.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:libary_management/core/api_client.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _isOpeningBook = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openBook(BarcodeCapture capture) async {
    if (_isOpeningBook || capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _isOpeningBook = true;
    try {
      String bookId = value;
      try {
        await ApiClient.get('/books/$value');
      } catch (_) {
        final result = apiMap(
          await ApiClient.get('/books', query: {'keyword': value, 'limit': 1}),
        );
        final books = apiList(result['items']);
        if (books.isEmpty) {
          throw const ApiException('Không tìm thấy sách từ mã đã quét.');
        }
        bookId = apiText(books.first['bib_id'], fallback: '');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DetailBook(bookId: bookId)),
      );
    } catch (error) {
      _isOpeningBook = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _openBook),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Quét mã QR sách',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => IconButton(
                        onPressed: _controller.toggleTorch,
                        icon: Icon(
                          _controller.value.torchState == TorchState.on
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đưa mã QR của sách vào khung để mở chi tiết sách',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
