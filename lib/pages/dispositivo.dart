import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class DispositivoPage extends StatefulWidget {
  const DispositivoPage({super.key});

  static const String routeName = 'dispositivo';
  static const String routePath = '/dispositivo';

  @override
  State<DispositivoPage> createState() => _DispositivoPageState();
}

class _DispositivoPageState extends State<DispositivoPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, String>> _dispositivos = [
    {'nome': 'IPhone 15 Pro Max', 'id': '11111'},
    {'nome': 'Galaxy S25 Ultra', 'id': '22222'},
    {'nome': 'IdeaPad Slim 3', 'id': '33333'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja deletar dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _dispositivos.removeAt(index);
      });
    }
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
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Dispositivos',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_sharp, color: Colors.white, size: 25),
              onPressed: () => context.pushNamed('lojas'),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 1200,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar dispositivo...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF666666),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF666666), size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4B39EF), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: _buildDeviceList(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _dispositivos.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(index, _dispositivos[index]);
        },
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.5,
        ),
        itemCount: _dispositivos.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(index, _dispositivos[index]);
        },
      );
    }
  }

  Widget _buildDeviceCard(int index, Map<String, String> device) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      margin: Responsive.isMobile(context) ? const EdgeInsets.only(bottom: 12) : EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  children: [
                    TextSpan(text: '${device['nome']} #'),
                    TextSpan(
                      text: device['id'],
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 24),
              onPressed: () => _confirmDelete(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
