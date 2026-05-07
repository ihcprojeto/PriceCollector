import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ListaProdutosPage extends StatefulWidget {
  const ListaProdutosPage({super.key});

  static const String routeName = 'listaProdutos';
  static const String routePath = '/listaProdutos';

  @override
  State<ListaProdutosPage> createState() => _ListaProdutosPageState();
}

class _ListaProdutosPageState extends State<ListaProdutosPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _filterValue;

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
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Lista Produtos',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_sharp, color: Colors.white, size: 25),
              onPressed: () {
                // Upload logic
              },
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lista de produtos que devem ser coletados na loja',
                          style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            flex: 2,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filterValue,
                                  hint: const Text('Filtrar por', style: TextStyle(fontSize: 14)),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                                  isExpanded: true,
                                  items: ['Geral', 'Pendentes', 'Coletados']
                                      .map((label) => DropdownMenuItem(
                                            value: label,
                                            child: Text(label, style: const TextStyle(fontSize: 14)),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(() => _filterValue = val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              '1/3 produtos coletados',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                Expanded(
                  child: _buildProductList(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.pushNamed('scanner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Coletar',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
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
        'brand': 'Danone',
        'description': 'Bebida proteica - 500g',
        'code': '7891025115656',
        'imagePath': 'assets/images/yopro.webp',
      },
      {
        'name': 'Pão de Forma',
        'brand': 'Pullman',
        'description': 'Pão fatiado - 480g',
        'code': '7896002360326',
        'imagePath': 'assets/images/pao-de-forma-pullman-500g-1.webp',
      },
      {
        'name': 'Coca-Cola',
        'brand': 'Coca-Cola',
        'description': 'Refrigerante - 2L',
        'code': '7894900027013',
        'imagePath': 'assets/images/coca-cola.png',
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
            brand: p['brand']!,
            description: p['description']!,
            code: p['code']!,
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
          childAspectRatio: 2,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return _buildProductCard(
            context,
            name: p['name']!,
            brand: p['brand']!,
            description: p['description']!,
            code: p['code']!,
            imagePath: p['imagePath']!,
          );
        },
      );
    }
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String name,
    required String brand,
    required String description,
    required String code,
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
        border: Border.all(color: AppTheme.primary),
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
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                        const Icon(Icons.workspace_premium_outlined, color: AppTheme.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          brand,
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
                  Text(
                    description,
                    style: GoogleFonts.interTight(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        code,
                        style: GoogleFonts.interTight(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 20),
                        onPressed: () => _confirmDeleteProduct(context),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
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
        title: const Text('Deseja deletar produto?'),
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
