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
        // Não salvamos a senha no Firestore por segurança
        final userData = usuario.toJson();
        userData.remove('senha');
        
        await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set(userData);
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
      String email = identificador;

      // Identifica se é matrícula (não contém @)
      if (!identificador.contains('@')) {
        final query = await _firestore
            .collection('usuarios')
            .where('matricula', isEqualTo: identificador)
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
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro inesperado ao realizar login.';
    }
  }

  Future<UsuarioModel?> getUsuarioData(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      return UsuarioModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
