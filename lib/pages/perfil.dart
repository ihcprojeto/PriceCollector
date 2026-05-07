import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  static const String routeName = 'perfil';
  static const String routePath = '/perfil';

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> with TickerProviderStateMixin {
  late TabController _tabBarController;
  final TextEditingController _matriculaController = TextEditingController(text: '189004');
  final TextEditingController _nomeController = TextEditingController(text: 'João Souza');
  final TextEditingController _emailController = TextEditingController(text: 'joaosouza@gmail.com');
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();

  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;

  String? _filterLoja;
  String? _orderBy;

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabBarController.dispose();
    _matriculaController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
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
          child: ResponsiveBody(
            maxWidth: 1000,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(context),
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
                          _buildDispositivosTab(),
                          _buildEditarPerfilTab(),
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

  Widget _buildUserHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'João Souza',
          style: GoogleFonts.interTight(
            fontSize: Responsive.isDesktop(context) ? 36 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              'joaosouza@gmail.com',
              style: GoogleFonts.inter(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#189004',
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

  Widget _buildMinhasColetasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _filterLoja,
                  hint: 'Todas as Lojas',
                  items: ['Todas as Lojas', 'Carrefour', 'Atacadão', 'Ninki'],
                  onChanged: (val) => setState(() => _filterLoja = val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  value: _orderBy,
                  hint: 'Ordenar por',
                  items: ['Nome A-Z', 'Nome Z-A', 'Código: Menor-Maior', 'Código: Maior-Menor'],
                  onChanged: (val) => setState(() => _orderBy = val),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildColetaList(context),
        ),
      ],
    );
  }

  Widget _buildColetaList(BuildContext context) {
    final List<Map<String, String>> coletas = [
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
        itemCount: coletas.length,
        itemBuilder: (context, index) {
          final c = coletas[index];
          return _buildColetaCard(
            name: c['name']!,
            store: c['store']!,
            price: c['price']!,
            imagePath: c['imagePath']!,
          );
        },
      );
    } else {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: coletas.length,
        itemBuilder: (context, index) {
          final c = coletas[index];
          return _buildColetaCard(
            name: c['name']!,
            store: c['store']!,
            price: c['price']!,
            imagePath: c['imagePath']!,
          );
        },
      );
    }
  }

  Widget _buildDispositivosTab() {
    return _buildDeviceList(context);
  }

  Widget _buildDeviceList(BuildContext context) {
    final List<Map<String, String>> devices = [
      {'name': 'IPhone 15 Pro Max', 'id': '11111'},
    ];

    if (Responsive.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: devices.length,
        itemBuilder: (context, index) => _buildDeviceCard(devices[index]['name']!, devices[index]['id']!),
      );
    } else {
      return GridView.builder(
        padding: const EdgeInsets.only(top: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4,
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) => _buildDeviceCard(devices[index]['name']!, devices[index]['id']!),
      );
    }
  }

  Widget _buildEditarPerfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          if (Responsive.isDesktop(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Matrícula',
                    hint: 'Número de matrícula',
                    icon: Icons.app_registration_rounded,
                    controller: _matriculaController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Nome',
                    hint: 'Nome completo',
                    icon: Icons.person_rounded,
                    controller: _nomeController,
                  ),
                ),
              ],
            )
          else ...[
            CustomTextField(
              label: 'Matrícula',
              hint: 'Número de matrícula',
              icon: Icons.app_registration_rounded,
              controller: _matriculaController,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Nome',
              hint: 'Nome completo',
              icon: Icons.person_rounded,
              controller: _nomeController,
            ),
          ],
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Email',
            hint: 'exemplo@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
          ),
          const SizedBox(height: 14),
          if (Responsive.isDesktop(context))
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Senha Atual',
                    hint: 'Senha atual',
                    icon: Icons.lock_outline_rounded,
                    controller: _senhaAtualController,
                    obscure: !_isPasswordVisible1,
                    toggleVisibility: () => setState(() => _isPasswordVisible1 = !_isPasswordVisible1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Alterar senha',
                    hint: 'Nova senha',
                    icon: Icons.lock_outline_rounded,
                    controller: _novaSenhaController,
                    obscure: !_isPasswordVisible2,
                    toggleVisibility: () => setState(() => _isPasswordVisible2 = !_isPasswordVisible2),
                  ),
                ),
              ],
            )
          else ...[
            CustomTextField(
              label: 'Senha Atual',
              hint: 'Senha atual',
              icon: Icons.lock_outline_rounded,
              controller: _senhaAtualController,
              obscure: !_isPasswordVisible1,
              toggleVisibility: () => setState(() => _isPasswordVisible1 = !_isPasswordVisible1),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Alterar senha',
              hint: 'Nova senha',
              icon: Icons.lock_outline_rounded,
              controller: _novaSenhaController,
              obscure: !_isPasswordVisible2,
              toggleVisibility: () => setState(() => _isPasswordVisible2 = !_isPasswordVisible2),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _confirmSave(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Salvar', style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
        ],
      ),
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x17000000), width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
          isExpanded: true,
          items: items.map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildColetaCard({
    required String name,
    required String store,
    required String price,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_rounded, color: AppTheme.primary, size: 12),
                          const SizedBox(width: 4),
                          Text(store, style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(price, style: GoogleFonts.interTight(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pushNamed('coleta'),
                              icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmDeleteColeta(),
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
      ),
    );
  }

  Widget _buildDeviceCard(String name, String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                    children: [
                      TextSpan(text: '$name #'),
                      TextSpan(text: id, style: const TextStyle(color: AppTheme.primary)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Color(0xFFF64736), size: 20),
                onPressed: () => _confirmDeleteDevice(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSave() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja salvar alterações?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteColeta() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja deletar produto coletado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDevice() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja deletar dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
  }
}
