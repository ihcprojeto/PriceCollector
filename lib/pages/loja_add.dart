import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/loja_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_body.dart';
import '../providers/loja_provider.dart';

class LojaAddPage extends StatefulWidget {
  final LojaModel? loja;
  const LojaAddPage({super.key, this.loja});

  static const String routeName = 'lojaAdd';
  static const String routePath = '/lojaAdd';

  @override
  State<LojaAddPage> createState() => _LojaAddPageState();
}

class _LojaAddPageState extends State<LojaAddPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cnpjController;
  late TextEditingController _nomeController;
  late TextEditingController _enderecoController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool get isEditing => widget.loja != null;

  @override
  void initState() {
    super.initState();
    _cnpjController = TextEditingController(text: widget.loja?.cnpj);
    _nomeController = TextEditingController(text: widget.loja?.nome);
    _enderecoController = TextEditingController(text: widget.loja?.endereco);
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _nomeController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null && widget.loja?.imagemUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma imagem para a loja.')),
      );
      return;
    }

    final bool? confirmSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Deseja atualizar loja?' : 'Deseja salvar loja?'),
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
      final lojaProvider = context.read<LojaProvider>();
      
      try {
        await lojaProvider.saveLoja(
          id: widget.loja?.id,
          nome: _nomeController.text,
          cnpj: _cnpjController.text,
          endereco: _enderecoController.text,
          imageFile: _imageFile,
          existingImageUrl: widget.loja?.imagemUrl,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Loja atualizada com sucesso!' : 'Loja salva com sucesso!')),
        );
        context.pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar loja: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LojaProvider>().isLoading;

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
            isEditing ? 'Editar Loja' : 'Nova Loja',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: Responsive.isDesktop(context) ? 30 : 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_sharp, color: Colors.white),
              onPressed: () => context.goNamed('dashboard'),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (isLoading) const LinearProgressIndicator(),
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
              Expanded(
                child: SingleChildScrollView(
                  child: AbsorbPointer(
                    absorbing: isLoading,
                    child: ResponsiveBody(
                      maxWidth: 800,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildImagePicker(),
                            const SizedBox(height: 20),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : (isEditing && widget.loja?.imagemUrl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.loja!.imagemUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: AppTheme.primary),
                          SizedBox(height: 8),
                          Text('Toque para selecionar imagem da loja',
                              style: TextStyle(color: AppTheme.primary)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      children: [
        if (Responsive.isDesktop(context))
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'CNPJ',
                  hint: 'Digite o CNPJ',
                  icon: Icons.payment_outlined,
                  controller: _cnpjController,
                  validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'NOME',
                  hint: 'Entre com o nome da loja',
                  icon: Icons.store_outlined,
                  controller: _nomeController,
                  validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
                ),
              ),
            ],
          )
        else ...[
          CustomTextField(
            label: 'CNPJ',
            hint: 'Digite o CNPJ',
            icon: Icons.payment_outlined,
            controller: _cnpjController,
            validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'NOME',
            hint: 'Entre com o nome da loja',
            icon: Icons.store_outlined,
            controller: _nomeController,
            validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
          ),
        ],
        const SizedBox(height: 20),
        CustomTextField(
          label: 'ENDEREÇO',
          hint: 'Digite o endereço da loja',
          icon: Icons.location_pin,
          controller: _enderecoController,
          validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLoading = context.watch<LojaProvider>().isLoading;
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
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isEditing ? 'Atualizar Loja' : 'Salvar Loja',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (!isEditing)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        _cnpjController.clear();
                        _nomeController.clear();
                        _enderecoController.clear();
                        _imageFile = null;
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
