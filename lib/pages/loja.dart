import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/loja_model.dart';
import '../providers/loja_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class LojaPage extends StatefulWidget {
  const LojaPage({super.key});

  static const String routeName = 'lojas';
  static const String routePath = '/lojas';

  @override
  State<LojaPage> createState() => _LojaPageState();
}

class _LojaPageState extends State<LojaPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LojaProvider>().fetchLojas();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<LojaProvider>().filterLojas(_searchController.text);
  }

  Future<void> _confirmDelete(LojaModel loja) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja deletar loja?'),
        content: Text('Tem certeza que deseja remover a loja "${loja.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<LojaProvider>().deleteLoja(loja.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loja removida com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lojaProvider = context.watch<LojaProvider>();

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
            'Lojas',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              onPressed: () => context.pushNamed('lojaAdd'),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: ResponsiveBody(
          maxWidth: 1200,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar lojas...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF666666),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF666666), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              if (lojaProvider.isLoading && lojaProvider.lojas.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (lojaProvider.lojas.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma loja encontrada',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: _buildStoreList(context, lojaProvider.lojas),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreList(BuildContext context, List<LojaModel> lojas) {
    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        itemCount: lojas.length,
        itemBuilder: (context, index) {
          return _buildStoreCard(context, lojas[index]);
        },
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: lojas.length,
        itemBuilder: (context, index) {
          return _buildStoreCard(context, lojas[index]);
        },
      );
    }
  }

  Widget _buildStoreCard(BuildContext context, LojaModel loja) {
    return InkWell(
      onTap: () => context.pushNamed('listaProdutos', extra: loja),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              color: Color(0x411D2429),
              offset: Offset(0, 1),
            )
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: loja.imagemUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.store),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loja.nome,
                      style: GoogleFonts.interTight(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loja.endereco,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF57636C), size: 20),
                    onPressed: () => context.pushNamed('lojaAdd', extra: loja),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 20),
                    onPressed: () => _confirmDelete(loja),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
