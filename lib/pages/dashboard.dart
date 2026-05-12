import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/login_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().carregarDadosUsuario();
    });
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja sair?'),
        content: const Text('Sua sessão será encerrada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DashboardProvider>().logout();
      if (mounted) context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final loginProvider = context.watch<LoginProvider>();
    final usuario = dashboardProvider.usuario;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        centerTitle: true,
        title: Text(
          'Price Collector',
          style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
        elevation: 0,
      ),
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveBody(
              maxWidth: 1000,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de Boas-vindas
                    _buildWelcomeHeader(usuario),
                    const SizedBox(height: 24),
                    
                    // Status do Dispositivo
                    _buildDeviceStatus(loginProvider.dispositivoSelecionado?.displayName),
                    const SizedBox(height: 32),

                    // Grid de Ações
                    Text(
                      'Acesso Rápido',
                      style: GoogleFonts.interTight(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionGrid(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader(usuario) {
    return InkWell(
      onTap: () => context.pushNamed('perfil'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 35, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${usuario?.nome ?? 'Usuário'}!',
                    style: GoogleFonts.interTight(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14181B),
                    ),
                  ),
                  Text(
                    usuario?.funcao?.toUpperCase() ?? 'COLETADOR',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF57636C)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatus(String? deviceName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.important_devices_rounded, color: Color(0xFF57636C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dispositivo em uso: ${deviceName ?? 'Nenhum selecionado'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF57636C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Iniciar Coleta',
        'subtitle': 'Selecione uma loja e comece',
        'icon': Icons.qr_code_scanner_rounded,
        'color': AppTheme.primary,
        'route': 'lojas',
      },
      {
        'title': 'Lojas',
        'subtitle': 'Gerenciar estabelecimentos',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFF39D2C0),
        'route': 'lojas',
      },
      {
        'title': 'Produtividade',
        'subtitle': 'Veja seus resultados',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFFEE8B60),
        'route': 'produtividade',
      },
      {
        'title': 'Operações',
        'subtitle': 'Configurações e logs',
        'icon': Icons.settings_suggest_rounded,
        'color': const Color(0xFF606AEE),
        'route': 'operacoes',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () => context.pushNamed(action['route']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action['icon'], color: action['color'], size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'],
                  style: GoogleFonts.interTight(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14181B),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    action['subtitle'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF57636C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
