import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String? _dispositivoSelecionado;

  bool _isPasswordVisible = false;

  final List<String> _dispositivos = [
    'IPhone 15 Pro Max',
    'Galaxy S25 Ultra',
    'IdeaPad Slim 3'
  ];

  @override
  void dispose() {
    _colaboradorController.dispose();
    _senhaController.dispose();
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
                            DropdownButtonFormField<String>(
                              value: _dispositivoSelecionado,
                              hint: const Text('Selecione...'),
                              items: _dispositivos.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _dispositivoSelecionado = val),
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
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.primary,
                              ),
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
                            onPressed: () {
                              context.pushNamed('dashboard');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
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
