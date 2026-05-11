import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
// Repositories
import 'repositories/auth_repository.dart';

// Providers
import 'providers/cadastro_provider.dart';
import 'providers/loja_provider.dart';

// Import de todas as páginas convertidas
import 'pages/login.dart';
import 'pages/cadastro.dart';
import 'pages/dashboard.dart';
import 'pages/loja.dart';
import 'pages/loja_add.dart';
import 'pages/lista_produtos.dart';
import 'pages/scanner.dart';
import 'pages/coleta.dart';
import 'pages/produtos_coletados.dart';
import 'pages/operacao.dart';
import 'pages/dispositivo.dart';
import 'pages/perfil.dart';
import 'pages/produtividade.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final cloudinary = Cloudinary.fromCloudName(cloudName: 'dgccbfglb');

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        ChangeNotifierProvider<CadastroProvider>(
          create: (context) => CadastroProvider(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<LojaProvider>(
          create: (_) => LojaProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Configuração do GoRouter
  static final _router = GoRouter(
    initialLocation: '/login', // Define o login como tela inicial
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: 'cadastro',
        path: '/cadastro',
        builder: (context, state) => const CadastroPage(),
      ),
      GoRoute(
        name: 'dashboard',
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        name: 'lojas',
        path: '/lojas',
        builder: (context, state) => const LojaPage(),
      ),
      GoRoute(
        name: 'lojaAdd',
        path: '/lojaAdd',
        builder: (context, state) => const LojaAddPage(),
      ),
      GoRoute(
        name: 'listaProdutos',
        path: '/listaProdutos',
        builder: (context, state) => const ListaProdutosPage(),
      ),
      GoRoute(
        name: 'scanner',
        path: '/scanner',
        builder: (context, state) => const ScannerPage(),
      ),
      GoRoute(
        name: 'coleta',
        path: '/coleta',
        builder: (context, state) => const ColetaPage(),
      ),
      GoRoute(
        name: 'produtos_coletados',
        path: '/produtos_coletados',
        builder: (context, state) => const ProdutosColetadosPage(),
      ),
      GoRoute(
        name: 'operacoes',
        path: '/operacoes',
        builder: (context, state) => const OperacaoPage(),
      ),
      GoRoute(
        name: 'dispositivos',
        path: '/dispositivos',
        builder: (context, state) => const DispositivoPage(),
      ),
      GoRoute(
        name: 'perfil',
        path: '/perfil',
        builder: (context, state) => const PerfilPage(),
      ),
      GoRoute(
        name: 'produtividade',
        path: '/produtividade',
        builder: (context, state) => const ProdutividadePage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router, // Usa a configuração do GoRouter
    );
  }
}