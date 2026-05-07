import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static const String routeName = 'scanner';
  static const String routePath = '/scanner';

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Scanner',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_sharp, color: Colors.white, size: 24),
              onPressed: () => context.pushNamed('dashboard'),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 600,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                BarcodeWidget(
                  data: '7891025115656',
                  barcode: Barcode.code128(),
                  width: Responsive.isDesktop(context) ? 300 : 200,
                  height: Responsive.isDesktop(context) ? 300 : 200,
                  color: Colors.black,
                  backgroundColor: Colors.transparent,
                  drawText: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aponte a câmera para o código de barras',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushNamed('coleta'),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    label: Text(
                      'Aperte para Scannear',
                      style: GoogleFonts.interTight(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Digitar o código de barras',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF666666),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF666666), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F4F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
