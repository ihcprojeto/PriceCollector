import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/loja_provider.dart';
import '../providers/produtividade_provider.dart';
import '../services/produtividade_export_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutividadeProvider>().carregarDados();
      context.read<LojaProvider>().fetchLojas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProdutividadeProvider>();
    final lojaProvider = context.watch<LojaProvider>();

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
          'Painel de Gestão',
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                      _buildFilters(context, provider, lojaProvider),
                      const SizedBox(height: 24),
                      _buildSummaryGrid(context, provider),
                      const SizedBox(height: 32),
                      _buildEfficiencyCards(context, provider),
                      const SizedBox(height: 32),
                      _buildMainCharts(context, provider),
                      const SizedBox(height: 32),
                      _buildAlertsSection(context, provider),
                      const SizedBox(height: 32),
                      _buildStoreProgressSection(context, provider),
                      const SizedBox(height: 32),
                      _buildTeamRankingSection(context, provider),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : () => ProdutividadeExportService.exportToPdf(provider),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ProdutividadeProvider provider, LojaProvider lojaProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10)],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          // Filtro de Período
          _buildFilterItem(
            label: 'Período',
            child: InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: provider.periodo,
                );
                if (range != null) provider.setPeriodo(range);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      provider.periodo == null
                          ? 'Sempre'
                          : '${DateFormat('dd/MM').format(provider.periodo!.start)} - ${DateFormat('dd/MM').format(provider.periodo!.end)}',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filtro de Loja
          _buildFilterItem(
            label: 'Loja',
            child: SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: provider.lojaIdFiltro,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text('Todas as Lojas', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas as Lojas', style: TextStyle(fontSize: 13))),
                  ...lojaProvider.lojas.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome, style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (val) => provider.setLojaFiltro(val),
              ),
            ),
          ),
          // Filtro de Colaborador
          _buildFilterItem(
            label: 'Colaborador',
            child: SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: provider.usuarioIdFiltro,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text('Todos', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos', style: TextStyle(fontSize: 13))),
                  ...provider.usuarios.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome, style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: (val) => provider.setUsuarioFiltro(val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, ProdutividadeProvider provider) {
    final bool isMobile = Responsive.isMobile(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildSummaryCard('Total Coletado', provider.totalColetados.toString(), Icons.check_circle_rounded, Colors.green),
        _buildSummaryCard('Pendentes', provider.totalPendentes.toString(), Icons.pending_rounded, Colors.orange),
        _buildSummaryCard('Cancelados', provider.totalCancelados.toString(), Icons.cancel_rounded, Colors.red),
        _buildSummaryCard('Conclusão', '${(provider.percentualConclusao * 100).toStringAsFixed(1)}%', Icons.pie_chart_rounded, AppTheme.primary),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha((0.1 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF14181B))),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCards(BuildContext context, ProdutividadeProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'Velocidade Média',
            '${provider.velocidadeMediaGlobal.toStringAsFixed(1)} itens/hr',
            Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            'Tempo Médio p/ Item',
            provider.totalColetados > 1
                ? (provider.tempoMedioGlobal.inHours > 0 
                    ? '${provider.tempoMedioGlobal.inHours}h ${provider.tempoMedioGlobal.inMinutes % 60}m'
                    : '${provider.tempoMedioGlobal.inMinutes}m ${provider.tempoMedioGlobal.inSeconds % 60}s')
                : '--',
            Icons.timer_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white.withAlpha((0.8 * 255).toInt()), fontSize: 12)),
                Text(value, style: GoogleFonts.interTight(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCharts(BuildContext context, ProdutividadeProvider provider) {
    if (provider.evolucaoTemporal.isEmpty) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evolução de Coletas', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.fromLTRB(16, 32, 32, 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (provider.evolucaoTemporal.values.isNotEmpty ? provider.evolucaoTemporal.values.reduce((a, b) => a > b ? a : b) : 10).toDouble() + 5,
                        barGroups: provider.evolucaoTemporal.entries.map((e) {
                          return BarChartGroupData(
                            x: e.key.day,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                color: AppTheme.primary,
                                width: isMobile ? 12 : 16,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              )
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distribuição', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: provider.progressoPorLoja.where((s) => s.coletados > 0).map((s) {
                            return PieChartSectionData(
                              value: s.coletados.toDouble(),
                              title: '${((s.coletados / provider.totalColetados) * 100).toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              color: Colors.primaries[provider.progressoPorLoja.indexOf(s) % Colors.primaries.length],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distribuição por Loja', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: provider.progressoPorLoja.where((s) => s.coletados > 0).map((s) {
                      return PieChartSectionData(
                        value: s.coletados.toDouble(),
                        title: '${((s.coletados / provider.totalColetados) * 100).toStringAsFixed(0)}%',
                        radius: 40,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        color: Colors.primaries[provider.progressoPorLoja.indexOf(s) % Colors.primaries.length],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context, ProdutividadeProvider provider) {
    final criticalStores = provider.progressoPorLoja.where((s) => s.percentual < 0.3 && s.total > 0).toList();
    final inactiveUsers = provider.rankingEquipe.where((u) => u.ultimaAtividade != null && DateTime.now().difference(u.ultimaAtividade!).inHours > 2).toList();

    if (criticalStores.isEmpty && inactiveUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas Operacionais', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (criticalStores.isNotEmpty)
          ...criticalStores.map((s) => _buildAlertCard(
                'Loja Crítica: ${s.nome}',
                'Apenas ${(s.percentual * 100).toStringAsFixed(1)}% concluído.',
                Icons.warning_amber_rounded,
                Colors.red,
              )),
        if (inactiveUsers.isNotEmpty)
          ...inactiveUsers.map((u) => _buildAlertCard(
                'Inatividade: ${u.nome}',
                'Última coleta há ${DateTime.now().difference(u.ultimaAtividade!).inHours} horas.',
                Icons.person_off_rounded,
                Colors.orange,
              )),
      ],
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: color.withAlpha((0.8 * 255).toInt()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreProgressSection(BuildContext context, ProdutividadeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progresso por Loja', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.progressoPorLoja.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final store = provider.progressoPorLoja[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(store.nome, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                      Text('${store.coletados}/${store.total} itens', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 10.0,
                    percent: store.percentual,
                    backgroundColor: const Color(0xFFF1F4F8),
                    progressColor: store.percentual > 0.8 ? Colors.green : (store.percentual > 0.4 ? Colors.orange : Colors.red),
                    barRadius: const Radius.circular(10),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamRankingSection(BuildContext context, ProdutividadeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ranking da Equipe', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.rankingEquipe.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = provider.rankingEquipe[index];
              final isAboveAverage = user.velocidadeMedia >= provider.velocidadeMediaGlobal;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isAboveAverage ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  child: Text((index + 1).toString(), style: TextStyle(color: isAboveAverage ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(user.nome, style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                    if (isAboveAverage)
                      const Icon(Icons.trending_up_rounded, color: Colors.green, size: 16)
                    else
                      const Icon(Icons.trending_flat_rounded, color: Colors.orange, size: 16),
                  ],
                ),
                subtitle: Text('ID: ${user.matricula} • ${user.itensColetados} itens', style: GoogleFonts.inter(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${user.velocidadeMedia.toStringAsFixed(1)} i/h', style: GoogleFonts.interTight(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    Text(
                      user.tempoMedio.inSeconds > 0 
                          ? 'Ø ${user.tempoMedio.inMinutes}m' 
                          : 'Ø --', 
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
