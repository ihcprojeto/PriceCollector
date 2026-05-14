import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/coleta_model.dart';
import '../providers/coleta_provider.dart';
import '../providers/loja_provider.dart';
import '../providers/produto_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ProdutosColetadosPage extends StatefulWidget {
  final String? lojaId;
  const ProdutosColetadosPage({super.key, this.lojaId});

  static const String routeName = 'produtos_coletados';
  static const String routePath = '/produtos_coletados';

  @override
  State<ProdutosColetadosPage> createState() => _ProdutosColetadosPageState();
}

class _ProdutosColetadosPageState extends State<ProdutosColetadosPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _lojaIdFiltro;
  String _orderBy = 'Nome A-Z';

  @override
  void initState() {
    super.initState();
    _lojaIdFiltro = widget.lojaId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coletaProvider = context.read<ColetaProvider>();
      coletaProvider.fetchColetas();
      if (widget.lojaId != null) {
        coletaProvider.setLojaFiltro(widget.lojaId);
      }
      context.read<LojaProvider>().fetchLojas();
    });
    _searchController.addListener(() {
      context.read<ColetaProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(ColetaModel coleta) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Coleta?'),
        content: Text('Deseja realmente excluir a coleta do produto "${coleta.produtoNome}"? O status voltará para pendente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ColetaProvider>().excluirColeta(coleta);
    }
  }

  Future<void> _handleEdit(ColetaModel coleta) async {
    final lojaProvider = context.read<LojaProvider>();
    final produtoProvider = context.read<ProdutoProvider>();
    
    // Precisamos da LojaModel e DemandaModel para a tela de coleta
    final loja = lojaProvider.lojas.firstWhere((l) => l.id == coleta.lojaId);
    final demanda = await produtoProvider.validarBarcode(coleta.lojaId, coleta.produtoBarcode);

    if (demanda != null && mounted) {
      context.pushNamed('coleta', extra: {
        'loja': loja,
        'demanda': demanda,
        'coleta': coleta, // Passamos a coleta existente para edição
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coletaProvider = context.watch<ColetaProvider>();
    final lojaProvider = context.watch<LojaProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.home_sharp, color: Colors.white),
            onPressed: () => context.goNamed('dashboard'),
          ),
          title: Text(
            'Produtos Coletados',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: () => context.pushNamed('lojas'),
                tooltip: 'Nova Coleta',
              ),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (coletaProvider.isLoading) const LinearProgressIndicator(),
              if (coletaProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            coletaProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.red),
                          onPressed: () => context.read<ColetaProvider>().fetchColetas(lojaId: _lojaIdFiltro),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildFilters(coletaProvider, lojaProvider),
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
              Expanded(
                child: ResponsiveBody(
                  maxWidth: 1200,
                  padding: EdgeInsets.zero,
                  child: _buildContent(coletaProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ColetaProvider provider, LojaProvider lojaProvider) {
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
                child: _buildDropdown(
                  value: _lojaIdFiltro,
                  hint: 'Todas as Lojas',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas as Lojas')),
                    ...lojaProvider.lojas.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome))),
                  ],
                  onChanged: (val) {
                    setState(() => _lojaIdFiltro = val);
                    provider.setLojaFiltro(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _orderBy,
                  hint: 'Ordenar por',
                  items: ['Nome A-Z', 'Nome Z-A', 'Preço: Menor ao Maior', 'Preço: Maior ao Menor']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _orderBy = val);
                      provider.setOrderBy(val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(provider.progresso),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progresso da Coleta', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(percent * 100).toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          animation: true,
          lineHeight: 12.0,
          animationDuration: 1000,
          percent: percent.clamp(0.0, 1.0),
          barRadius: const Radius.circular(10),
          progressColor: AppTheme.primary,
          backgroundColor: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildContent(ColetaProvider provider) {
    if (provider.isLoading && provider.coletas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.coletas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhuma coleta realizada', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.coletas.length,
        itemBuilder: (context, index) => _buildColetaCard(provider.coletas[index]),
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
        itemCount: provider.coletas.length,
        itemBuilder: (context, index) => _buildColetaCard(provider.coletas[index]),
      );
    }
  }

  Widget _buildColetaCard(ColetaModel coleta) {
    return Container(
      margin: Responsive.isMobile(context) ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha((0.3 * 255).toInt())),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: coleta.produtoImagemUrl != null && coleta.produtoImagemUrl!.startsWith('http')
                    ? Image.network(
                        coleta.produtoImagemUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    coleta.produtoNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.interTight(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          coleta.lojaNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${coleta.preco.toStringAsFixed(2)}',
                        style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _handleEdit(coleta),
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 20),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _confirmDelete(coleta),
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
