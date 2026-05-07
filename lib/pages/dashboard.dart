import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_header.dart';
import '../widgets/responsive_body.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const String routeName = 'dashboard';
  static const String routePath = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const ResponsiveHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveBody(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                          child: Text(
                            'Bem vindo ao PriceCollector!\n\nSelecione uma opção abaixo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF14181B),
                              fontSize: Responsive.isDesktop(context) ? 20 : 15,
                            ),
                          ),
                        ),
                        _buildMenuLayout(context),
                        const SizedBox(height: 24),
                        _buildBottomActions(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuLayout(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Column(
        children: [
          _buildMenuButton(
            context,
            label: 'Nova Coleta',
            color: AppTheme.primary,
            onPressed: () => context.pushNamed('lojas'),
          ),
          const SizedBox(height: 14),
          _buildMenuButton(
            context,
            label: 'Produtos Coletados',
            color: const Color(0xFF9E72E4),
            onPressed: () => context.pushNamed('produtos_coletados'),
          ),
          const SizedBox(height: 14),
          _buildMenuButton(
            context,
            label: 'Operações de Coleta',
            color: const Color(0xFFB19FD8),
            onPressed: () => context.pushNamed('operacoes'),
          ),
        ],
      );
    } else {
      return GridView.count(
        crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3,
        children: [
          _buildMenuButton(
            context,
            label: 'Nova Coleta',
            color: AppTheme.primary,
            onPressed: () => context.pushNamed('lojas'),
          ),
          _buildMenuButton(
            context,
            label: 'Produtos Coletados',
            color: const Color(0xFF9E72E4),
            onPressed: () => context.pushNamed('produtos_coletados'),
          ),
          _buildMenuButton(
            context,
            label: 'Operações de Coleta',
            color: const Color(0xFFB19FD8),
            onPressed: () => context.pushNamed('operacoes'),
          ),
        ],
      );
    }
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(
            Icons.devices_sharp,
            color: Color(0xFF5A5A5A),
            size: 25,
          ),
          onPressed: () => context.pushNamed('dispositivos'),
        ),
        IconButton(
          icon: const Icon(
            Icons.person_rounded,
            color: Color(0xFF4B39EF),
            size: 27,
          ),
          onPressed: () => context.pushNamed('perfil'),
        ),
        IconButton(
          icon: const Icon(
            Icons.logout_sharp,
            color: Color(0xFFFF0404),
            size: 25,
          ),
          onPressed: () => context.pushNamed('login'),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: Responsive.isDesktop(context) ? 18 : 16,
          ),
        ),
      ),
    );
  }
}
