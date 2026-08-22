import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/services/contact_qr_service.dart';
import 'contact_qr_preview_page.dart';

class ContactQrScannerPage extends StatefulWidget {
  const ContactQrScannerPage({super.key});

  @override
  State<ContactQrScannerPage> createState() => _ContactQrScannerPageState();
}

class _ContactQrScannerPageState extends State<ContactQrScannerPage> {
  final ContactQrService _service = ContactQrService();
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _processing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleCapture,
          ),
          const _ScannerOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ScannerActionButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close scanner',
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _ScannerActionButton(
                        icon: Icons.flash_on_rounded,
                        tooltip: 'Toggle flashlight',
                        onTap: _scannerController.toggleTorch,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: colors.inverseSurface.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: colors.onInverseSurface,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _processing
                                ? 'Checking VonoTalky profile...'
                                : 'Place a VonoTalky profile QR code inside the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onInverseSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) return;

    setState(() => _processing = true);
    await _scannerController.stop();

    try {
      final uid = _service.parseUserId(rawValue);

      if (uid == null) {
        _showMessage('This is not a valid VonoTalky profile QR code.');
        await _resumeScanner();
        return;
      }

      final lookup = await _service.lookup(rawValue);

      if (lookup == null) {
        _showMessage('This VonoTalky profile could not be found.');
        await _resumeScanner();
        return;
      }

      if (!mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ContactQrPreviewPage(lookup: lookup)),
      );

      if (mounted) {
        await _resumeScanner();
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not check this QR code. Please try again.');
        await _resumeScanner();
      }
    }
  }

  Future<void> _resumeScanner() async {
    if (!mounted) return;

    setState(() => _processing = false);

    try {
      await _scannerController.start();
    } catch (_) {
      if (mounted) {
        _showMessage('Camera could not be restarted.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScannerActionButton extends StatelessWidget {
  const _ScannerActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: .42),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      color: Colors.white,
      icon: Icon(icon),
    ),
  );
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shortest = constraints.biggest.shortestSide;
      final size = (shortest * .68).clamp(220.0, 310.0).toDouble();

      return Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: .48),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _ScannerFramePainter(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const corner = 34.0;
    const radius = 24.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(corner, 0)
      ..moveTo(size.width - corner, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, corner)
      ..moveTo(size.width, size.height - corner)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(size.width - corner, size.height)
      ..moveTo(corner, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
