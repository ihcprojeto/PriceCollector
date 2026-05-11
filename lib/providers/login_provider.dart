import 'package:flutter/material.dart';
import '../models/dispositivo_model.dart';
import '../models/usuario_model.dart';
import '../repositories/auth_repository.dart';
import '../services/device_service.dart';

class LoginProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final DeviceService _deviceService = DeviceService();

  LoginProvider(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingDevices = false;
  bool get isLoadingDevices => _isLoadingDevices;

  List<DispositivoModel> _dispositivos = [];
  List<DispositivoModel> get dispositivos => _dispositivos;

  DispositivoModel? _dispositivoSelecionado;
  DispositivoModel? get dispositivoSelecionado => _dispositivoSelecionado;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UsuarioModel? _usuarioLogado;
  UsuarioModel? get usuarioLogado => _usuarioLogado;

  void setDispositivo(DispositivoModel? dispositivo) {
    _dispositivoSelecionado = dispositivo;
    notifyListeners();
  }

  Future<void> carregarDispositivos() async {
    _isLoadingDevices = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dispositivos = await _deviceService.getDispositivos();
    } catch (e) {
      _errorMessage = 'Erro ao carregar dispositivos.';
    } finally {
      _isLoadingDevices = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identificador, String senha) async {
    if (identificador.isEmpty || senha.isEmpty) {
      _errorMessage = 'Preencha todos os campos.';
      notifyListeners();
      return false;
    }

    if (_dispositivoSelecionado == null) {
      _errorMessage = 'Selecione um dispositivo.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authRepository.login(identificador, senha);
      if (userCredential.user != null) {
        _usuarioLogado = await _authRepository.getUsuarioData(userCredential.user!.uid);
        if (_usuarioLogado == null) {
          _errorMessage = 'Dados do usuário não encontrados no Firestore.';
          await _authRepository.signOut();
          return false;
        }
        // Aqui você pode salvar o dispositivo selecionado em um SharedPreferences ou no estado global
        // Para este exemplo, apenas retornamos sucesso
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
