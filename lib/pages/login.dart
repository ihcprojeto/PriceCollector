import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/dispositivo_model.dart';
import '../providers/login_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_header.dart';
import '../widgets/responsive_body.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _colaboradorController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginProvider>().carregarDispositivos();
    });
  }

  @override
  void dispose() {
    _colaboradorController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final provider = context.read<LoginProvider>();
    final success = await provider.login(
      _colaboradorController.text.trim(),
      _senhaController.text.trim(),
    );

    if (success && mounted) {
      context.goNamed('dashboard');
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              const ResponsiveHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'Colaborador',
                          hint: 'Número de matrícula ou email',
                          icon: Icons.person,
                          controller: _colaboradorController,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Senha',
                          hint: 'Senha',
                          icon: Icons.lock_outline_rounded,
                          controller: _senhaController,
                          obscure: !_isPasswordVisible,
                          toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dispositivo',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<DispositivoModel>(
                              isExpanded: true,
                              value: loginProvider.dispositivoSelecionado,
                              hint: loginProvider.isLoadingDevices 
                                  ? const Text('Carregando dispositivos...')
                                  : const Text('Selecione...', overflow: TextOverflow.ellipsis),
                              items: loginProvider.dispositivos.map((DispositivoModel dev) {
                                return DropdownMenuItem<DispositivoModel>(
                                  value: dev,
                                  child: Text(
                                    dev.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: loginProvider.isLoading ? null : (val) => loginProvider.setDispositivo(val),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primary),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                              icon: loginProvider.isLoadingDevices 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Não possui uma conta? ',
                                  style: TextStyle(color: Color(0xFF666666)),
                                ),
                                TextSpan(
                                  text: 'Cadastro',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.pushNamed('cadastro');
                                    },
                                ),
                              ],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loginProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: loginProvider.isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Login',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                          ),
                        ),
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
}
