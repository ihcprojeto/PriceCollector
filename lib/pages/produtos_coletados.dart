import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ProdutosColetadosPage extends StatefulWidget {
  const ProdutosColetadosPage({super.key});

  static const String routeName = 'produtos_coletados';
  static const String routePath = '/produtos_coletados';

  @override
  State<ProdutosColetadosPage> createState() => _ProdutosColetadosPageState();
}

class _ProdutosColetadosPageState extends State<ProdutosColetadosPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _filterLoja;
  String? _orderBy;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            'Produtos coletados',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 25),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar produtos...',
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _filterLoja,
                              hint: 'Carrefour',
                              items: ['Todas as Lojas', 'Carrefour', 'Atacadão', 'Ninki'],
                              onChanged: (val) => setState(() => _filterLoja = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              value: _orderBy,
                              hint: 'Ordenar por',
                              items: ['Preço: Menor ao Maior', 'Preço: Maior ao Menor', 'Nome A-Z', 'Nome Z-A'],
                              onChanged: (val) => setState(() => _orderBy = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return LinearPercentIndicator(
                            percent: 0.67,
                            width: constraints.maxWidth,
                            lineHeight: 25,
                            animation: true,
                            animateFromLastPercent: true,
                            progressColor: const Color(0x4C4B39EF),
                            backgroundColor: const Color(0xA5D2D2D2),
                            center: Text(
                              '67%',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                            barRadius: const Radius.circular(30),
                            padding: EdgeInsets.zero,
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                Expanded(
                  child: _buildProductList(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    final List<Map<String, String>> products = [
      {
        'name': 'YoPro',
        'store': 'Carrefour',
        'price': 'R\$ 6,99',
        'imagePath': 'assets/images/yopro.webp',
      },
      {
        'name': 'Pão de Forma Pullman',
        'store': 'Carrefour',
        'price': 'R\$ 7,19',
        'imagePath': 'assets/images/pao-de-forma-pullman-500g-1.webp',
      },
    ];

    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return _buildProductCard(
            context,
            name: p['name']!,
            store: p['store']!,
            price: p['price']!,
            imagePath: p['imagePath']!,
          );
        },
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
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return _buildProductCard(
            context,
            name: p['name']!,
            store: p['store']!,
            price: p['price']!,
            imagePath: p['imagePath']!,
          );
        },
      );
    }
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
          isExpanded: true,
          items: items.map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String name,
    required String store,
    required String price,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x0D000000),
            offset: Offset(0, 2),
          )
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4B39EF)),
      ),
      margin: Responsive.isMobile(context) ? const EdgeInsets.fromLTRB(16, 0, 16, 12) : EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFF1F4F8),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_rounded, color: AppTheme.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          store,
                          style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: GoogleFonts.interTight(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pushNamed('coleta'),
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _confirmDeleteProduct(context),
                            icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 20),
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

  Future<void> _confirmDeleteProduct(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja deletar produto coletado?'),
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
  }
}
