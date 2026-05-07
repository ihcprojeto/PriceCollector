import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';

class LojaAddPage extends StatefulWidget {
  const LojaAddPage({super.key});

  static const String routeName = 'lojaAdd';
  static const String routePath = '/lojaAdd';

  @override
  State<LojaAddPage> createState() => _LojaAddPageState();
}

class _LojaAddPageState extends State<LojaAddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();

  @override
  void dispose() {
    _cnpjController.dispose();
    _nomeController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final bool? confirmSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deseja salvar loja?'),
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

    if (confirmSave == true) {
      if (!mounted) return;
      context.pushNamed('lojas');
    }
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
            'Loja',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_sharp, color: Colors.white),
              onPressed: () => context.pushNamed('dashboard'),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveBody(
                    maxWidth: 800,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildFormFields(context),
                          const SizedBox(height: 20),
                          const Divider(height: 8, thickness: 1, color: AppTheme.border),
                          const SizedBox(height: 20),
                          _buildActionButtons(context),
                        ],
                      ),
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

  Widget _buildFormFields(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          CustomTextField(
            label: 'CNPJ',
            hint: 'Digite o CNPJ',
            icon: Icons.payment_outlined,
            controller: _cnpjController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'NOME',
            hint: 'Entre com o nome da loja',
            icon: Icons.store_outlined,
            controller: _nomeController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'ENDEREÇO',
            hint: 'Digite o endereço da loja',
            icon: Icons.location_pin,
            controller: _enderecoController,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'CNPJ',
                  hint: 'Digite o CNPJ',
                  icon: Icons.payment_outlined,
                  controller: _cnpjController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'NOME',
                  hint: 'Entre com o nome da loja',
                  icon: Icons.store_outlined,
                  controller: _nomeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'ENDEREÇO',
            hint: 'Digite o endereço da loja',
            icon: Icons.location_pin,
            controller: _enderecoController,
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Salvar Loja',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _cnpjController.clear();
                _nomeController.clear();
                _enderecoController.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Limpar formulário',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
