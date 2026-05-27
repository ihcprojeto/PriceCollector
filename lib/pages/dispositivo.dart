import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/dispositivo_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class DispositivoPage extends StatefulWidget {
  const DispositivoPage({super.key});

  static const String routeName = 'dispositivos';
  static const String routePath = '/dispositivos';

  @override
  State<DispositivoPage> createState() => _DispositivoPageState();
}

class _DispositivoPageState extends State<DispositivoPage> {
  final TextEditingController _searchController = TextEditingController();

  String _currentOrderBy = 'Utilização (Maior)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DispositivoProvider>().carregarDados();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUsageDetails(BuildContext context, String deviceId, String deviceName) {
    final stats = context.read<DispositivoProvider>().usageStats[deviceId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Histórico: $deviceName'),
        content: SizedBox(
          width: double.maxFinite,
          child: stats == null || stats.coletasPorUsuario.isEmpty
              ? const Text('Nenhuma utilização registrada.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: stats.coletasPorUsuario.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final userId = stats.coletasPorUsuario.keys.elementAt(index);
                    final count = stats.coletasPorUsuario[userId];
                    final nome = stats.nomesUsuarios[userId] ?? 'Usuário Desconhecido';
                    final matricula = stats.matriculasUsuarios[userId] ?? '---';
                    return ListTile(
                      title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Matrícula: $matricula'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$count coletas', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DispositivoProvider>();
    final user = context.watch<DashboardProvider>().usuario;

    if (user != null && user.funcao != 'administrador') {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Gestão de Dispositivos',
          style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: ResponsiveBody(
                  maxWidth: 1200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetrics(context, provider),
                      const SizedBox(height: 24),
                      _buildFilters(context, provider),
                      const SizedBox(height: 24),
                      _buildDeviceList(context, provider),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetrics(BuildContext context, DispositivoProvider provider) {
    final bool isMobile = Responsive.isMobile(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 0.9 : 1.1,
      children: [
        _buildMetricCard('Ativos', provider.totalAtivos.toString(), Icons.check_circle_rounded, Colors.green),
        _buildMetricCard('Inativos', provider.totalInativos.toString(), Icons.cancel_rounded, Colors.red),
        _buildMetricCard('Total Coletas', provider.totalOperacoes.toString(), Icons.analytics_rounded, AppTheme.primary),
        _buildMetricCard('Mais Utilizado', provider.mostUsedDevice, Icons.star_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha((0.1 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.interTight(
                    fontSize: value.length > 15 ? 14 : 20, 
                    fontWeight: FontWeight.bold, 
                    color: const Color(0xFF14181B)
                  )
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]), 
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, DispositivoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Buscar por modelo, marca ou serial...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildSortDropdown(provider),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(DispositivoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentOrderBy,
          items: ['Utilização (Maior)', 'Utilização (Menor)', 'Nome A-Z']
              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (val) {
             if (val != null) {
               setState(() => _currentOrderBy = val);
               provider.setOrderBy(val);
             }
          },
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, DispositivoProvider provider) {
    if (provider.dispositivos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.devices_other_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Nenhum dispositivo encontrado.', style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.dispositivos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = provider.dispositivos[index];
        final stats = provider.usageStats[device.id];
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: device.ativo ? Colors.transparent : Colors.red.withAlpha(50)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: device.ativo ? AppTheme.primary.withAlpha((0.1 * 255).toInt()) : Colors.red.withAlpha((0.1 * 255).toInt()),
              child: Icon(
                device.ativo ? Icons.smartphone_rounded : Icons.phonelink_erase_rounded, 
                color: device.ativo ? AppTheme.primary : Colors.red
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    device.modelo, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: device.ativo ? Colors.green.withAlpha((0.1 * 255).toInt()) : Colors.red.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    device.ativo ? 'ATIVO' : 'INATIVO', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: device.ativo ? Colors.green : Colors.red)
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${device.marca} • Serial: ${device.serial}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Uso: ${stats?.totalColetas ?? 0} coletas', 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                    if (stats?.ultimaAtividade != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Última: ${DateFormat('dd/MM HH:mm').format(stats!.ultimaAtividade!)}', 
                            style: const TextStyle(fontSize: 12)
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'status') {
                  final confirm = await _showConfirmDialog(
                    context, 
                    device.ativo ? 'Desativar Dispositivo?' : 'Ativar Dispositivo?',
                    'O dispositivo ${device.ativo ? 'não aparecerá' : 'voltará a aparecer'} na seleção de login.',
                    confirmColor: device.ativo ? Colors.red : Colors.green,
                  );
                  if (confirm) provider.toggleStatus(device.id, !device.ativo);
                } else if (val == 'details') {
                  _showUsageDetails(context, device.id, device.displayName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'details', child: Text('Ver Histórico de Uso')),
                PopupMenuItem(
                  value: 'status', 
                  child: Text(device.ativo ? 'Desativar Dispositivo' : 'Ativar Dispositivo', style: TextStyle(color: device.ativo ? Colors.red : Colors.green))
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, String content, {Color confirmColor = Colors.red}) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: const Text('Confirmar')
          ),
        ],
      ),
    ) ?? false;
  }
}
