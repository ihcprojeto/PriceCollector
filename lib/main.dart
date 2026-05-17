import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/coleta_model.dart';
import 'theme/app_theme.dart';
// Repositories
import 'repositories/auth_repository.dart';

// Models
import 'models/loja_model.dart';
import 'models/demanda_model.dart';

// Providers
import 'providers/cadastro_provider.dart';
import 'providers/loja_provider.dart';
import 'providers/login_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/produto_provider.dart';
import 'providers/coleta_provider.dart';
import 'providers/perfil_provider.dart';
import 'providers/produtividade_provider.dart';
import 'providers/dispositivo_provider.dart';

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
import 'pages/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        ChangeNotifierProvider<LoginProvider>(
          create: (context) => LoginProvider(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<ProdutoProvider>(
          create: (_) => ProdutoProvider(),
        ),
        ChangeNotifierProvider<ColetaProvider>(
          create: (context) => ColetaProvider(),
        ),
        ChangeNotifierProvider<PerfilProvider>(
          create: (context) => PerfilProvider(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<ProdutividadeProvider>(
          create: (_) => ProdutividadeProvider(),
        ),
        ChangeNotifierProvider<DispositivoProvider>(
          create: (_) => DispositivoProvider(),
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
    initialLocation: '/', // Começa na Splash Screen
    routes: [
      GoRoute(
        name: 'splash',
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
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
        builder: (context, state) => LojaAddPage(loja: state.extra as LojaModel?),
      ),
      GoRoute(
        name: 'listaProdutos',
        path: '/listaProdutos',
        builder: (context, state) => ListaProdutosPage(loja: state.extra as LojaModel),
      ),
      GoRoute(
        name: 'scanner',
        path: '/scanner',
        builder: (context, state) => ScannerPage(loja: state.extra as LojaModel),
      ),
      GoRoute(
        name: 'coleta',
        path: '/coleta',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ColetaPage(
            loja: extra['loja'] as LojaModel,
            demanda: extra['demanda'] as DemandaModel,
            coleta: extra['coleta'] as ColetaModel?,
          );
        },
      ),
      GoRoute(
        name: 'produtos_coletados',
        path: '/produtos_coletados',
        builder: (context, state) => ProdutosColetadosPage(lojaId: state.extra as String?),
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
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
    );
  }
}