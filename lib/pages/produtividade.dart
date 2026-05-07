import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class ProdutividadePage extends StatefulWidget {
  const ProdutividadePage({super.key});

  static const String routeName = 'produtividade';
  static const String routePath = '/produtividade';

  @override
  State<ProdutividadePage> createState() => _ProdutividadePageState();
}

class _ProdutividadePageState extends State<ProdutividadePage> {
  final List<Map<String, String>> _equipePerformance = [
    {
      'nome': 'João Souza',
      'id': '189004',
      'dispositivo': 'IPhone 15 Pro Max',
      'data': '10/03/2026',
      'itens': '9 itens',
      'velocidade': '4 itens/hr',
    },
    {
      'nome': 'Maria Silva',
      'id': '270246',
      'dispositivo': 'Galaxy S25 Ultra',
      'data': '17/03/2026',
      'itens': '18 itens',
      'velocidade': '7 itens/hr',
    },
    {
      'nome': 'Julia Gomes',
      'id': '335794',
      'dispositivo': 'IdeaPad Slim 3',
      'data': '24/04/2026',
      'itens': '9 itens',
      'velocidade': '4 itens/hr',
    },
  ];

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
            'Visão Geral',
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
          child: SingleChildScrollView(
            child: ResponsiveBody(
              maxWidth: 1200,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Desempenho da Equipe',
                      style: GoogleFonts.interTight(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildPerformanceList(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _buildSummaryItem(
            'Total Coletado (Equipe)',
            '29',
            isDesktop,
          ),
          _buildSummaryItem(
            'Velocidade Média Global',
            '5 i/hr',
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isDesktop) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.interTight(
            fontSize: isDesktop ? 60 : 48,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceList(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: _equipePerformance.map((performance) => _buildPerformanceCard(performance)).toList(),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: _equipePerformance.length,
        itemBuilder: (context, index) {
          return _buildPerformanceCard(_equipePerformance[index]);
        },
      );
    }
  }

  Widget _buildPerformanceCard(Map<String, String> data) {
    return Container(
      width: double.infinity,
      margin: Responsive.isMobile(context) ? const EdgeInsets.fromLTRB(16, 0, 16, 12) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        TextSpan(text: '${data['nome']} # '),
                        TextSpan(
                          text: data['id'],
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
                  data['itens']!,
                  style: GoogleFonts.interTight(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['dispositivo']!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF666666),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  data['velocidade']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
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
                data['data']!,
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
