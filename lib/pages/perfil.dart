import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';
import '../providers/dashboard_provider.dart';
import '../providers/coleta_provider.dart';
import '../providers/perfil_provider.dart';
import '../providers/loja_provider.dart';
import '../providers/produto_provider.dart';
import '../models/coleta_model.dart';
import '../models/demanda_model.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  static const String routeName = 'perfil';
  static const String routePath = '/perfil';

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> with TickerProviderStateMixin {
  late TabController _tabBarController;
  
  // Controllers para Edição de Perfil
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();

  // Controllers para Filtro de Coletas
  final TextEditingController _searchColetaController = TextEditingController();
  String? _filterLoja;
  String _orderBy = 'Nome A-Z';

  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<DashboardProvider>().usuario;
      if (user != null) {
        _nomeController.text = user.nome;
        _emailController.text = user.email;
        _matriculaController.text = user.matricula;
        
        // Iniciar carregamento de dados das abas
        context.read<ColetaProvider>().fetchColetas(usuarioId: user.id);
        context.read<PerfilProvider>().fetchDispositivos(user.id!);
        context.read<LojaProvider>().fetchLojas();
      }
    });

    _searchColetaController.addListener(() {
      context.read<ColetaProvider>().setSearchQuery(_searchColetaController.text);
    });
  }

  @override
  void dispose() {
    _tabBarController.dispose();
    _matriculaController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _searchColetaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DashboardProvider>().usuario;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Perfil',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: user == null 
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveBody(
                maxWidth: 1000,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(blurRadius: 4, color: Color(0x33000000), offset: Offset(0, 2))
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserHeader(user.nome, user.email, user.matricula),
                        const SizedBox(height: 12),
                        TabBar(
                          controller: _tabBarController,
                          isScrollable: Responsive.isMobile(context),
                          labelColor: AppTheme.primary,
                          unselectedLabelColor: const Color(0xFF666666),
                          indicatorColor: AppTheme.primary,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          tabs: const [
                            Tab(text: 'Minhas Coletas'),
                            Tab(text: 'Dispositivos'),
                            Tab(text: 'Editar perfil'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            controller: _tabBarController,
                            children: [
                              _buildMinhasColetasTab(),
                              _buildDispositivosTab(user.id!),
                              _buildEditarPerfilTab(user.id!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(String nome, String email, String matricula) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: GoogleFonts.interTight(
            fontSize: Responsive.isDesktop(context) ? 36 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              email,
              style: GoogleFonts.inter(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#$matricula',
              style: GoogleFonts.inter(
                color: const Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB: MINHAS COLETAS ---
  Widget _buildMinhasColetasTab() {
    final coletaProvider = context.watch<ColetaProvider>();
    final lojaProvider = context.watch<LojaProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              TextFormField(
                controller: _searchColetaController,
                decoration: InputDecoration(
                  hintText: 'Buscar nas minhas coletas...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppTheme.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: _filterLoja,
                      hint: 'Todas as Lojas',
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas as Lojas')),
                        ...lojaProvider.lojas.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome))),
                      ],
                      onChanged: (val) {
                        setState(() => _filterLoja = val);
                        coletaProvider.setLojaFiltro(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
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
                          coletaProvider.setOrderBy(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (coletaProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (coletaProvider.coletas.isEmpty)
          const Expanded(child: Center(child: Text('Nenhuma coleta encontrada.')))
        else
          Expanded(
            child: _buildColetaList(coletaProvider.coletas),
          ),
      ],
    );
  }

  Widget _buildColetaList(List<ColetaModel> coletas) {
    return ListView.builder(
      itemCount: coletas.length,
      itemBuilder: (context, index) => _buildColetaCard(coletas[index]),
    );
  }

  Widget _buildColetaCard(ColetaModel coleta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80, height: 80, color: AppTheme.inputBg,
                  child: (coleta.produtoImagemUrl != null && coleta.produtoImagemUrl!.isNotEmpty)
                    ? Image.network(
                        coleta.produtoImagemUrl!,
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coleta.produtoNome, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.interTight(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('R\$ ${coleta.preco.toStringAsFixed(2)}', style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleEditColeta(coleta),
                              icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 20),
                              constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmDeleteColeta(coleta),
                              icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 22),
                              constraints: const BoxConstraints(), padding: EdgeInsets.zero,
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
      ),
    );
  }

  // --- TAB: DISPOSITIVOS ---
  Widget _buildDispositivosTab(String userId) {
    final perfilProvider = context.watch<PerfilProvider>();

    if (perfilProvider.dispositivos.isEmpty) {
      return const Center(child: Text('Nenhum dispositivo registrado.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: perfilProvider.dispositivos.length,
      itemBuilder: (context, index) {
        final dev = perfilProvider.dispositivos[index];
        return _buildDeviceCard(
          userId, 
          dev['id'], 
          dev['modeloDispositivo'] ?? 'Desconhecido', 
          dev['serialDispositivo'] ?? 'S/N'
        );
      },
    );
  }

  Widget _buildDeviceCard(String userId, String docId, String modelo, String serial) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(modelo, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Serial: $serial', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 20),
                onPressed: () => _confirmDeleteDevice(userId, docId, modelo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB: EDITAR PERFIL ---
  Widget _buildEditarPerfilTab(String uid) {
    final provider = context.watch<PerfilProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          CustomTextField(label: 'Matrícula', hint: 'Matrícula', icon: Icons.badge_outlined, controller: _matriculaController),
          const SizedBox(height: 14),
          CustomTextField(label: 'Nome', hint: 'Nome completo', icon: Icons.person_rounded, controller: _nomeController),
          const SizedBox(height: 14),
          CustomTextField(label: 'Email', hint: 'Email', icon: Icons.email_outlined, controller: _emailController),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text('Segurança', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Senha Atual (Obrigatória)', hint: 'Confirme sua senha atual', 
            icon: Icons.lock_outline_rounded, controller: _senhaAtualController,
            obscure: !_isPasswordVisible1,
            toggleVisibility: () => setState(() => _isPasswordVisible1 = !_isPasswordVisible1),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Alterar senha (Opcional)', hint: 'Nova senha', 
            icon: Icons.lock_reset_rounded, controller: _novaSenhaController,
            obscure: !_isPasswordVisible2,
            toggleVisibility: () => setState(() => _isPasswordVisible2 = !_isPasswordVisible2),
          ),
          const SizedBox(height: 24),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => _handleSaveProfile(uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: provider.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Salvar Alterações', style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE AÇÕES ---

  Future<void> _handleSaveProfile(String uid) async {
    if (_senhaAtualController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe sua senha atual para salvar.')));
      return;
    }

    final perfilProvider = context.read<PerfilProvider>();
    final success = await perfilProvider.atualizarPerfil(
      uid: uid,
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      matricula: _matriculaController.text.trim(),
      senhaAtual: _senhaAtualController.text,
      novaSenha: _novaSenhaController.text.isNotEmpty ? _novaSenhaController.text : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(perfilProvider.successMessage ?? 'Perfil atualizado!'))
      );
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      await context.read<DashboardProvider>().carregarDadosUsuario(); // Atualizar header
    } else if (mounted) {
      // O erro já está no provider.errorMessage e é exibido na Tab de edição
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<PerfilProvider>().errorMessage ?? 'Erro ao atualizar perfil.'))
      );
    }
  }

  Future<void> _handleEditColeta(ColetaModel coleta) async {
    final loja = context.read<LojaProvider>().lojas.firstWhere((l) => l.id == coleta.lojaId);
    final demanda = await context.read<ProdutoProvider>().validarBarcode(coleta.lojaId, coleta.produtoBarcode);

    if (demanda != null && mounted) {
      context.pushNamed('coleta', extra: {
        'loja': loja,
        'demanda': demanda,
        'coleta': coleta,
      });
    }
  }

  Future<void> _confirmDeleteColeta(ColetaModel coleta) async {
    final confirm = await _showConfirmDialog('Excluir Coleta?', 'Deseja remover esta coleta? O produto voltará para pendente.');
    if (confirm == true && mounted) {
      await context.read<ColetaProvider>().excluirColeta(coleta);
    }
  }

  Future<void> _confirmDeleteDevice(String userId, String docId, String modelo) async {
    final confirm = await _showConfirmDialog('Remover Dispositivo?', 'Deseja remover "$modelo" da sua lista de dispositivos utilizados?');
    if (confirm == true && mounted) {
      await context.read<PerfilProvider>().removerDispositivo(userId, docId);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title), content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Confirmar')),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({required T? value, required String hint, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      height: 45, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(value: value, hint: Text(hint, style: const TextStyle(fontSize: 14)), icon: const Icon(Icons.keyboard_arrow_down_rounded), isExpanded: true, items: items, onChanged: onChanged),
      ),
    );
  }
}
