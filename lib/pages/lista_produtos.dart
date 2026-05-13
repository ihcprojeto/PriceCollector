import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/loja_model.dart';
import '../models/demanda_model.dart';
import '../providers/produto_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ListaProdutosPage extends StatefulWidget {
  final LojaModel loja;
  const ListaProdutosPage({super.key, required this.loja});

  static const String routeName = 'listaProdutos';
  static const String routePath = '/listaProdutos';

  @override
  State<ListaProdutosPage> createState() => _ListaProdutosPageState();
}

class _ListaProdutosPageState extends State<ListaProdutosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'Geral';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoProvider>().fetchDemandas(widget.loja.id!);
    });
    _searchController.addListener(() {
      context.read<ProdutoProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onImportExcel() async {
    final lojaId = widget.loja.id;
    if (lojaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: ID da loja não encontrado.'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<ProdutoProvider>();
    final success = await provider.importarExcel(lojaId);
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produtos importados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    } else {
      // Caso o usuário tenha cancelado a seleção do arquivo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importação cancelada.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _confirmCancel(DemandaModel demanda) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Demanda?'),
        content: Text('Deseja realmente cancelar a coleta do produto "${demanda.produtoNome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ProdutoProvider>().cancelarDemanda(widget.loja.id!, demanda.id);
    }
  }

  Future<void> _confirmDelete(DemandaModel demanda) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Demanda?'),
        content: Text('Deseja realmente excluir permanentemente a demanda do produto "${demanda.produtoNome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ProdutoProvider>().deletarDemanda(widget.loja.id!, demanda.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtoProvider = context.watch<ProdutoProvider>();
    final user = context.watch<DashboardProvider>().usuario;
    final isAdmin = user?.funcao == 'administrador';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.loja.nome,
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontSize: Responsive.isDesktop(context) ? 26 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
              onPressed: produtoProvider.isLoading ? null : _onImportExcel,
              tooltip: 'Importar Excel (XLSX)',
            ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (produtoProvider.isLoading) const LinearProgressIndicator(),
            _buildHeader(produtoProvider),
            const Divider(height: 1, thickness: 1, color: AppTheme.border),
            Expanded(
              child: ResponsiveBody(
                maxWidth: 1200,
                padding: EdgeInsets.zero,
                child: _buildContent(produtoProvider),
              ),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProdutoProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar produtos...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF1F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      items: ['Geral', 'Pendente', 'Coletado', 'Cancelado']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _statusFilter = val);
                          provider.setStatusFilter(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${provider.totalColetados}/${provider.totalDemandas} coletados',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProdutoProvider provider) {
    if (provider.isLoading && provider.demandas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.demandas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhum produto encontrado', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.demandas.length,
        itemBuilder: (context, index) => _buildProductCard(provider.demandas[index]),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: provider.demandas.length,
        itemBuilder: (context, index) => _buildProductCard(provider.demandas[index]),
      );
    }
  }

  Widget _buildProductCard(DemandaModel demanda) {
    Color borderColor = AppTheme.primary; // Borda roxa para pendentes por padrão
    Widget? statusIcon;

    if (demanda.status == 'coletado') {
      borderColor = Colors.green;
      statusIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (demanda.status == 'cancelado') {
      borderColor = Colors.red;
      statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 20);
    }

    return Container(
      margin: Responsive.isMobile(context) ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x1A000000), offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: demanda.produtoImagemUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          demanda.produtoNome,
                          style: GoogleFonts.interTight(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (statusIcon != null) statusIcon,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          demanda.produtoMarca,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    demanda.produtoDescricao,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        demanda.barcode,
                        style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.grey),
                      ),
                      if (demanda.status == 'pendente')
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                          onPressed: () => _confirmCancel(demanda),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      if (demanda.status == 'cancelado')
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_rounded, color: Colors.green, size: 20),
                              onPressed: () => context.read<ProdutoProvider>().reativarDemanda(widget.loja.id!, demanda.id),
                              tooltip: 'Reativar Demanda',
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () => _confirmDelete(demanda),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => context.pushNamed('scanner', extra: widget.loja),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Coletar',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
