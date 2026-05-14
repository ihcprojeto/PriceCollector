import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';
import '../models/loja_model.dart';
import '../models/demanda_model.dart';
import '../models/coleta_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/login_provider.dart';
import '../providers/produto_provider.dart';

class ColetaPage extends StatefulWidget {
  final LojaModel loja;
  final DemandaModel demanda;
  final ColetaModel? coleta;

  const ColetaPage({
    super.key,
    required this.loja,
    required this.demanda,
    this.coleta,
  });

  static const String routeName = 'coleta';
  static const String routePath = '/coleta';

  @override
  State<ColetaPage> createState() => _ColetaPageState();
}

class _ColetaPageState extends State<ColetaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _precoController;
  final FocusNode _precoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _precoController = TextEditingController(
      text: widget.coleta != null ? widget.coleta!.preco.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _precoController.dispose();
    _precoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final double? preco = double.tryParse(_precoController.text.replaceAll(',', '.'));
    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um preço válido.')),
      );
      return;
    }

    final bool? confirmSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.coleta != null ? 'Deseja atualizar coleta?' : 'Deseja salvar coleta?'),
        content: Text('Confirmar preço: R\$ ${preco.toStringAsFixed(2)}'),
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
      
      final dashboardProvider = context.read<DashboardProvider>();
      final loginProvider = context.read<LoginProvider>();
      final produtoProvider = context.read<ProdutoProvider>();

      final usuario = dashboardProvider.usuario;
      final dispositivo = loginProvider.dispositivoSelecionado;

      if (usuario == null || dispositivo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário ou dispositivo não identificados.')),
        );
        return;
      }

      final novaColeta = ColetaModel(
        id: widget.coleta?.id,
        dataColeta: DateTime.now(),
        dispositivoId: dispositivo.id,
        dispositivoModelo: dispositivo.modelo,
        lojaId: widget.loja.id!,
        lojaNome: widget.loja.nome,
        preco: preco,
        produtoBarcode: widget.demanda.barcode,
        produtoNome: widget.demanda.produtoNome,
        produtoImagemUrl: widget.demanda.produtoImagemUrl,
        usuarioId: usuario.id!,
        usuarioMatricula: usuario.matricula,
        usuarioNome: usuario.nome,
      );

      final success = await produtoProvider.salvarColeta(
        coleta: novaColeta,
        demandaId: widget.demanda.id,
      );

      if (!mounted) return;

      if (success) {
        final String? nextStep = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Produto coletado com sucesso!'),
            content: const Text('O que deseja fazer agora?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'demanda'),
                child: const Text('Ver demanda'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'produtos'),
                child: const Text('Ver produtos coletados'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'nova'),
                child: const Text('Nova coleta'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (nextStep == 'nova') {
          context.pushNamed('scanner', extra: widget.loja);
        } else if (nextStep == 'demanda') {
          context.pushNamed('listaProdutos', extra: widget.loja);
        } else if (nextStep == 'produtos') {
          context.pushNamed('produtos_coletados', extra: widget.loja.id);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(produtoProvider.errorMessage ?? 'Erro ao salvar coleta.')),
        );
      }
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
            'Coleta',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.home_sharp, color: Colors.white),
                onPressed: () => context.pushNamed('dashboard'),
              ),
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
                    maxWidth: 900,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductCard(context),
          const SizedBox(height: 24),
          _buildPriceField(context),
          const SizedBox(height: 20),
          const Divider(height: 8, thickness: 1, color: AppTheme.border),
          const SizedBox(height: 20),
          _buildActionButtons(context),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildProductCard(context)),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceField(context),
                const SizedBox(height: 20),
                const Divider(height: 8, thickness: 1, color: AppTheme.border),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProductCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x0D000000),
            offset: Offset(0, 2),
          )
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFFF1F4F8),
                child: widget.demanda.produtoImagemUrl.startsWith('http')
                    ? Image.network(
                        widget.demanda.produtoImagemUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                      )
                    : Image.asset(
                        widget.demanda.produtoImagemUrl.isNotEmpty
                            ? widget.demanda.produtoImagemUrl
                            : 'assets/images/yopro.webp', // fallback
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.demanda.produtoNome,
                    maxLines: 2,
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_outlined, color: AppTheme.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          widget.demanda.produtoMarca,
                          style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.demanda.produtoDescricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.interTight(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => context.pushNamed('scanner', extra: widget.loja),
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREÇO',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _precoController,
          focusNode: _precoFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: '0.00',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "R\$",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o preço';
            }
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Valor inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLoading = context.watch<ProdutoProvider>().isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Salvar Coleta',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => setState(() => _precoController.clear()),
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
