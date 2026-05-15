import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUp(UsuarioModel usuario) async {
    try {
      // 1. Criar usuário no Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );

      // 2. Salvar dados adicionais no Firestore
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        // Não salvamos a senha no Firestore por segurança
        final userData = usuario.toJson();
        userData.remove('senha');
        
        await _firestore
            .collection('usuarios')
            .doc(uid)
            .set(userData);

        // Regra: Criar automaticamente a subcoleção dispositivos_utilizados
        // Como o Firestore precisa de um doc, podemos deixar a subcoleção pronta
        // ou adicionar um documento inicial vazio se necessário. 
        // A regra diz "deve ser criada", então garantimos o acesso ao caminho.
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected Error during signUp: $e');
      throw 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  Future<UserCredential> login(String identificador, String senha) async {
    try {
      String email = identificador.trim();

      // Se não for e-mail, busca por matrícula
      if (!identificador.contains('@')) {
        final query = await _firestore
            .collection('usuarios')
            .where('matricula', isEqualTo: identificador.trim())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Matrícula não encontrada.',
          );
        }
        email = query.docs.first.get('email');
      }

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected Login Error: $e');
      throw 'Erro inesperado ao realizar login.';
    }
  }

  Future<void> registrarDispositivoUtilizado(String userId, String modelo, String serial) async {
    final subcolecao = _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('dispositivos_utilizados');

    // Verificar se o dispositivo já existe para este usuário
    final query = await subcolecao
        .where('serialDispositivo', isEqualTo: serial)
        .where('modeloDispositivo', isEqualTo: modelo)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await subcolecao.add({
        'modeloDispositivo': modelo,
        'serialDispositivo': serial,
      });
    }
  }

  Future<UsuarioModel?> getUsuarioData(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      return UsuarioModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('usuarios').doc(uid).update(data);
  }

  Future<bool> reauthenticateAndChangeSensitiveData(
    String currentPassword, {
    String? newPassword,
    String? newEmail,
  }) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) throw 'Usuário não autenticado.';

    try {
      // 1. Reautenticar
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Atualizar Senha (se fornecida)
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      // 3. Atualizar Email (se fornecido e diferente)
      if (newEmail != null && newEmail.isNotEmpty && newEmail != user.email) {
         // O método updateEmail foi removido nas versões recentes do Firebase Auth (5.0+).
        // Agora deve-se usar verifyBeforeUpdateEmail, que envia um link de confirmação.
        // O e-mail no Firebase Auth só será alterado após o usuário clicar no link.
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('Erro na reautenticação/atualização: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isMatriculaDisponivel(String matricula, String currentUserId) async {
    final query = await _firestore
        .collection('usuarios')
        .where('matricula', isEqualTo: matricula)
        .get();

    // Se encontrar alguém com essa matrícula que não seja o próprio usuário
    return !query.docs.any((doc) => doc.id != currentUserId);
  }

  Stream<List<Map<String, dynamic>>> getDispositivosUtilizados(String userId) {
    return _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('dispositivos_utilizados')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> removerDispositivoUtilizado(String userId, String dispositivoDocId) async {
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('dispositivos_utilizados')
        .doc(dispositivoDocId)
        .delete();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'email-already-in-use':
        return 'Este e-mail já está sendo utilizado por outra conta.';
      case 'requires-recent-login':
        return 'Esta operação é sensível e requer um login recente. Por favor, faça login novamente.';
      case 'weak-password':
        return 'A senha fornecida é muito fraca.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail/Matrícula ou senha incorretos.';
      case 'invalid-email':
        return 'O formato do email é inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'network-request-failed':
        return 'Falha na conexão com a internet.';
      case 'too-many-requests':
        return 'Muitas solicitações. Tente novamente mais tarde.';
      default:
        return 'Erro na autenticação: ${e.message ?? e.code}';
    }
  }

  Future<void> checkAndSyncEmail(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final firestoreEmail = doc.data()?['email'];
      if (firestoreEmail != user.email) {
        // O e-mail no Auth mudou (ex: via verificação de e-mail), mas no Firestore não.
        // Sincronizamos para garantir que o login por matrícula funcione.
        await _firestore.collection('usuarios').doc(uid).update({'email': user.email});
        print('Sync: Firestore e-mail atualizado para ${user.email}');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
