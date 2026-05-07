import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class OperacaoPage extends StatefulWidget {
  const OperacaoPage({super.key});

  static const String routeName = 'operacao';
  static const String routePath = '/operacao';

  @override
  State<OperacaoPage> createState() => _OperacaoPageState();
}

class _OperacaoPageState extends State<OperacaoPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, String>> _operacoes = [
    {
      'nome': 'João Souza',
      'id': '189004',
      'email': 'joaosouza@gmail.com',
      'data': '10/03/2026',
      'dispositivo': 'IPhone 15 Pro Max',
    },
    {
      'nome': 'Maria Silva',
      'id': '270246',
      'email': 'mariasilva@gmail.com',
      'data': '17/03/2026',
      'dispositivo': 'Galaxy S25 Ultra',
    },
    {
      'nome': 'Julia Gomes',
      'id': '335794',
      'email': 'juliagomes@gmail.com',
      'data': '24/04/2026',
      'dispositivo': 'IdeaPad Slim 3',
    },
  ];

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
            'Operações',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: ResponsiveBody(
            maxWidth: 1200,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                            child: Text(
                              'Abaixo estão as operações de coleta realizadas pelos nossos colaboradores',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar operações...',
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
                          const SizedBox(height: 16),
                          _buildOperacaoList(context),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.pushNamed('produtividade'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Painel de Gestão',
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

  Widget _buildOperacaoList(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _operacoes.length,
        itemBuilder: (context, index) {
          return _buildOperacaoCard(_operacoes[index]);
        },
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: _operacoes.length,
        itemBuilder: (context, index) {
          return _buildOperacaoCard(_operacoes[index]);
        },
      );
    }
  }

  Widget _buildOperacaoCard(Map<String, String> op) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF1A1A1A),
                      ),
                      children: [
                        TextSpan(text: '${op['nome']} # '),
                        TextSpan(
                          text: op['id'],
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  op['dispositivo']!,
                  style: GoogleFonts.interTight(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              op['email']!,
              style: GoogleFonts.inter(
                color: const Color(0xFF666666),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: Text(
                op['data']!,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
