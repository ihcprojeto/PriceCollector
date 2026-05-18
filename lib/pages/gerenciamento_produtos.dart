import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/gerenciamento_produto_provider.dart';
import '../providers/loja_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class GerenciamentoProdutosPage extends StatefulWidget {
  const GerenciamentoProdutosPage({super.key});

  static const String routeName = 'gerenciamento_produtos';
  static const String routePath = '/gerenciamento_produtos';

  @override
  State<GerenciamentoProdutosPage> createState() => _GerenciamentoProdutosPageState();
}

class _GerenciamentoProdutosPageState extends State<GerenciamentoProdutosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _orderBy = 'Nome';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GerenciamentoProdutoProvider>().fetchProdutos();
      context.read<LojaProvider>().fetchLojas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onImportExcel() async {
    final provider = context.read<GerenciamentoProdutoProvider>();
    final result = await provider.importarExcel();
    
    if (result.isNotEmpty && mounted) {
      _showImportReport(result);
    }
  }

  void _showImportReport(Map<String, int> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de Importação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Adicionados'),
              trailing: Text('${result['adicionados']}'),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.orange),
              title: const Text('Ignorados (Já existem)'),
              trailing: Text('${result['ignorados']}'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _onAddDemandas() async {
    final provider = context.read<GerenciamentoProdutoProvider>();
    if (provider.selectedBarcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um produto')),
      );
      return;
    }

    final lojaProvider = context.read<LojaProvider>();
    List<String> selectedLojaIds = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar em Demandas'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Selecione as lojas (${provider.selectedBarcodes.length} produtos selecionados):'),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lojaProvider.lojas.length,
                    itemBuilder: (context, index) {
                      final loja = lojaProvider.lojas[index];
                      return CheckboxListTile(
                        title: Text(loja.nome),
                        value: selectedLojaIds.contains(loja.id),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val!) {
                              selectedLojaIds.add(loja.id!);
                            } else {
                              selectedLojaIds.remove(loja.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedLojaIds.isEmpty ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final result = await provider.adicionarEmLojas(selectedLojaIds);
        if (mounted) _showDemandasReport(result);
      }
    });
  }

  void _showDemandasReport(Map<String, int> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultado da Operação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Demandas processadas com sucesso.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildReportRow(Icons.add_task, Colors.green, 'Adicionadas', result['adicionados']!),
            _buildReportRow(Icons.copy, Colors.orange, 'Ignoradas (Já existiam)', result['ignorados']!),
            _buildReportRow(Icons.error_outline, Colors.red, 'Falhas', result['falhas']!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Concluir')),
        ],
      ),
    );
  }

  Widget _buildReportRow(IconData icon, Color color, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _onExcluir() async {
    final provider = context.read<GerenciamentoProdutoProvider>();
    if (provider.selectedBarcodes.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produtos?'),
        content: Text('Deseja excluir permanentemente os ${provider.selectedBarcodes.length} produtos selecionados? Eles também serão removidos de todas as demandas.'),
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

    if (confirm == true) {
      await provider.excluirSelecionados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GerenciamentoProdutoProvider>();
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Gerenciamento de Produtos', style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold))
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: provider.isLoading ? null : _onImportExcel,
            tooltip: 'Importar Excel',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red[50],
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.red), onPressed: provider.fetchProdutos),
                  ],
                ),
              ),
            _buildActionBar(provider),
            _buildFilters(provider),
            if (provider.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: provider.produtos.isEmpty && !provider.isLoading
                  ? const Center(child: Text('Nenhum produto encontrado.'))
                  : ResponsiveBody(
                      maxWidth: 1200,
                      padding: EdgeInsets.zero,
                      child: isDesktop ? _buildTable(provider) : _buildList(provider),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(GerenciamentoProdutoProvider provider) {
    if (provider.selectedBarcodes.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('${provider.selectedBarcodes.length} selecionados', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.add_business, size: 18),
              label: const Text('Add em Demandas'),
              onPressed: _onAddDemandas,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
              label: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: _onExcluir,
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.close), onPressed: provider.clearSelection),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(GerenciamentoProdutoProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Tooltip(
            message: 'Selecionar todos',
            child: Checkbox(
              value: provider.isAllSelected,
              onChanged: (_) => provider.toggleSelectAll(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
          const SizedBox(width: 12),
          _buildSortDropdown(provider),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(GerenciamentoProdutoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _orderBy,
          items: ['Nome', 'Marca'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _orderBy = val);
              provider.setOrderBy(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildList(GerenciamentoProdutoProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.produtos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prod = provider.produtos[index];
        final isSelected = provider.selectedBarcodes.contains(prod.barcode);
        
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) => provider.toggleSelection(prod.barcode),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(prod.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${prod.marca} • ${prod.barcode}'),
                Text(prod.descricao, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _buildLojasBadge(prod.totalLojas),
              ],
            ),
            secondary: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(prod.imagemUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(GerenciamentoProdutoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10)],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.grey[200],
          ),
          child: DataTable(
            showCheckboxColumn: true,
            onSelectAll: (_) => provider.toggleSelectAll(),
            headingRowColor: WidgetStateProperty.all(AppTheme.primary.withAlpha((0.05 * 255).toInt())),
            headingTextStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
              fontSize: 14,
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('PRODUTO')),
              DataColumn(label: Text('MARCA')),
              DataColumn(label: Text('BARCODE')),
              DataColumn(label: Text('PRESENÇA')),
            ],
            rows: provider.produtos.map((prod) {
              final isSelected = provider.selectedBarcodes.contains(prod.barcode);
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => provider.toggleSelection(prod.barcode),
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            prod.imagemUrl,
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(prod.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  DataCell(Text(prod.marca)),
                  DataCell(Text(prod.barcode, style: GoogleFonts.robotoMono(fontSize: 13, color: Colors.grey[600]))),
                  DataCell(_buildLojasBadge(prod.totalLojas)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLojasBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: count > 0 ? Colors.blue.withAlpha((0.1 * 255).toInt()) : Colors.grey.withAlpha((0.1 * 255).toInt()), borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$count lojas',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: count > 0 ? Colors.blue : Colors.grey),
      ),
    );
  }
}
