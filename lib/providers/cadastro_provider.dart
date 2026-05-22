import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../repositories/auth_repository.dart';

class CadastroProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  CadastroProvider(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> registrarUsuario({
    required String matricula,
    required String nome,
    required String email,
    required String senha,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final String matriculaTrim = matricula.trim();
      final String funcao = (matriculaTrim.toLowerCase().contains('adm')) ? 'administrador' : 'coletador';

      final usuario = UsuarioModel(
        email: email.trim(),
        funcao: funcao,
        matricula: matriculaTrim,
        nome: nome.trim(),
        senha: senha,
      );

      await _authRepository.signUp(usuario);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
