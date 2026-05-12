import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../repositories/auth_repository.dart';

class DashboardProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  DashboardProvider(this._authRepository);

  UsuarioModel? _usuario;
  UsuarioModel? get usuario => _usuario;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> carregarDadosUsuario() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      _isLoading = true;
      notifyListeners();
      
      _usuario = await _authRepository.getUsuarioData(currentUser.uid);
      
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
