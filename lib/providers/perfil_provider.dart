import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class PerfilProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  PerfilProvider(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _dispositivos = [];
  List<Map<String, dynamic>> get dispositivos => _dispositivos;

  StreamSubscription? _dispositivosSub;

  void fetchDispositivos(String userId) {
    _dispositivosSub?.cancel();
    _dispositivosSub = _authRepository.getDispositivosUtilizados(userId).listen((data) {
      _dispositivos = data;
      notifyListeners();
    });
  }

  Future<bool> removerDispositivo(String userId, String docId) async {
    try {
      await _authRepository.removerDispositivoUtilizado(userId, docId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao remover dispositivo: $e';
      notifyListeners();
      return false;
    }
  }

  String? _successMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> atualizarPerfil({
    required String uid,
    required String nome,
    required String email,
    required String matricula,
    required String senhaAtual,
    String? novaSenha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Validar matrícula duplicada antes de qualquer ação sensível
      final disponivel = await _authRepository.isMatriculaDisponivel(matricula, uid);
      if (!disponivel) {
        throw 'Esta matrícula já está sendo utilizada por outro usuário.';
      }

      final currentEmail = _authRepository.currentUser?.email;
      bool emailChangeInitiated = email != currentEmail;

      // 2. Reautenticar e atualizar dados sensíveis no Firebase Auth (Senha e/ou Email)
      await _authRepository.reauthenticateAndChangeSensitiveData(
        senhaAtual,
        newPassword: novaSenha,
        newEmail: email,
      );
      debugPrint('PerfilProvider: Dados sensíveis (Auth) processados.');

      // 3. Atualizar dados no Firestore
      // Se verifyBeforeUpdateEmail foi usado, o currentUser?.email ainda é o antigo.
      // Sincronizamos o Firestore apenas com o que o Auth aceita no momento.
      final String finalEmail = _authRepository.currentUser?.email ?? email;

      await _authRepository.updateUserProfile(uid, {
        'nome': nome,
        'matricula': matricula,
        'email': finalEmail,
      });
      debugPrint('PerfilProvider: Firestore atualizado.');

      if (emailChangeInitiated) {
        _successMessage = 'Dados salvos. Verifique seu novo e-mail para confirmar a alteração.';
      } else {
        _successMessage = 'Perfil atualizado com sucesso!';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _dispositivosSub?.cancel();
    super.dispose();
  }
}
