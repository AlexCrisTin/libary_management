import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'detail_book.dart';

class LibrarianScanner extends StatefulWidget {
  const LibrarianScanner({super.key});

  @override
  State<LibrarianScanner> createState() => _LibrarianScannerState();
}

class _LibrarianScannerState extends State<LibrarianScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _openingBook = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_openingBook || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _openingBook = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DetailBook()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
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
                        'Quét QR / mã vạch sách',
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
                  width: 250,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đưa mã QR hoặc mã vạch sách vào khung',
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
