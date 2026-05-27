import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/loja_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/produto_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_body.dart';

class ScannerPage extends StatefulWidget {
  final LojaModel loja;
  const ScannerPage({super.key, required this.loja});

  static const String routeName = 'scanner';
  static const String routePath = '/scanner';

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A permissão da câmera é necessária para escanear.')),
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _validateBarcode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _validateBarcode(String barcode) async {
    setState(() => _isScanning = false);
    _scannerController.stop();

    if (!_isBarcodeValid(barcode)) {
      _showWarningDialog('Código de barras inválido');
      return;
    }

    final provider = context.read<ProdutoProvider>();
    final user = context.read<DashboardProvider>().usuario;
    final isAdmin = user?.funcao == 'administrador';

    final demanda = await provider.validarBarcode(widget.loja.id!, barcode);

    if (!mounted) return;

    if (demanda == null) {
      _showNotFoundDialog(isAdmin, barcode);
    } else if (demanda.status == 'cancelado') {
      _showWarningDialog('Este produto foi cancelado na demanda atual.');
    } else if (demanda.status == 'coletado') {
      _showWarningDialog('Este produto já foi coletado na demanda atual.');
    } else {
      context.pushNamed('coleta', extra: {
        'loja': widget.loja,
        'demanda': demanda,
      });
    }
  }

  bool _isBarcodeValid(String barcode) {
    if (barcode.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false;

    final validLengths = [6, 8, 12, 13, 14];
    if (!validLengths.contains(barcode.length)) return false;

    if (barcode.length == 8 || barcode.length == 12 || barcode.length == 13) {
      return _validateChecksum(barcode);
    }

    return true;
  }

  bool _validateChecksum(String barcode) {
    try {
      int sum = 0;
      int length = barcode.length;
      int checkDigit = int.parse(barcode[length - 1]);

      for (int i = 0; i < length - 1; i++) {
        int digit = int.parse(barcode[length - 2 - i]);
        int weight = (i % 2 == 0) ? 3 : 1;
        sum += digit * weight;
      }

      int calculatedCheckDigit = (10 - (sum % 10)) % 10;
      return calculatedCheckDigit == checkDigit;
    } catch (_) {
      return false;
    }
  }

  void _showNotFoundDialog(bool isAdmin, String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Produto Não Encontrado'),
        content: Text(isAdmin
            ? 'Este item não está nas demandas atuais. Deseja abrir o gerenciamento para localizá-lo ou cadastrá-lo?'
            : 'Este item não está nas demandas atuais. Para adicioná-lo, entre em contato com um administrador.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanner();
            },
            child: const Text('Cancelar'),
          ),
          if (isAdmin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pushNamed('gerenciamento_produtos', extra: barcode);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Abrir gerenciamento', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanner();
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  void _resumeScanner() {
    setState(() => _isScanning = true);
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProdutoProvider>().isLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Scanner de Preços',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveBody(
              maxWidth: 600,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: _onDetect,
                          ),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primary.withAlpha(150), width: 4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          if (isLoading)
                            Container(
                              color: Colors.black54,
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Código de Barras',
                    hint: 'Digitar manualmente...',
                    icon: Icons.keyboard_rounded,
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _validateBarcode(_barcodeController.text.trim()),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: Text(
                        'Ler e Prosseguir',
                        style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
