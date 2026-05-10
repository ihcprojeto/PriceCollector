import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_body.dart';
import '../widgets/responsive_header.dart';
import '../utils/responsive.dart';
import '../providers/cadastro_provider.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  static const String routeName = 'cadastro';
  static const String routePath = '/cadastro';

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _matriculaController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      final cadastroProvider = context.read<CadastroProvider>();

      final success = await cadastroProvider.registrarUsuario(
        matricula: _matriculaController.text,
        nome: _nomeController.text,
        email: _emailController.text,
        senha: _senhaController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pushNamed('login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cadastroProvider.errorMessage ?? 'Erro ao criar conta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _senhaController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const ResponsiveHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveBody(
                    maxWidth: 900,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Criar Conta de Colaborador',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildFormFields(context),
                          const SizedBox(height: 24),
                          _buildBottomSection(context),
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
            label: 'Matrícula',
            hint: 'Número de matrícula',
            icon: Icons.app_registration_rounded,
            controller: _matriculaController,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Nome',
            hint: 'Nome completo',
            icon: Icons.person_rounded,
            controller: _nomeController,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Email',
            hint: 'exemplo@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            validator: _emailValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Senha',
            hint: 'Criar senha',
            icon: Icons.lock_outline_rounded,
            controller: _senhaController,
            obscure: !_isPasswordVisible,
            toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Confirmar senha',
            hint: 'Confirmar senha',
            icon: Icons.lock_outline_rounded,
            controller: _confirmarSenhaController,
            obscure: !_isConfirmPasswordVisible,
            toggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            validator: _confirmPasswordValidator,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Matrícula',
                  hint: 'Número de matrícula',
                  icon: Icons.app_registration_rounded,
                  controller: _matriculaController,
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Nome',
                  hint: 'Nome completo',
                  icon: Icons.person_rounded,
                  controller: _nomeController,
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email',
            hint: 'exemplo@gmail.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            validator: _emailValidator,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Senha',
                  hint: 'Criar senha',
                  icon: Icons.lock_outline_rounded,
                  controller: _senhaController,
                  obscure: !_isPasswordVisible,
                  toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Confirmar senha',
                  hint: 'Confirmar senha',
                  icon: Icons.lock_outline_rounded,
                  controller: _confirmarSenhaController,
                  obscure: !_isConfirmPasswordVisible,
                  toggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  validator: _confirmPasswordValidator,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBottomSection(BuildContext context) {
    return Consumer<CadastroProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Já possui uma conta? ',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed('login'),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Criar conta',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
