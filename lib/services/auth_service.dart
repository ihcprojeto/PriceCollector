import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Busca o email por matrícula caso o usuário tenha digitado a matrícula
  Future<String?> _getEmailByMatricula(String matricula) async {
    final query = await _firestore
        .collection('usuarios')
        .where('matricula', isEqualTo: matricula)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.get('email') as String;
    }
    return null;
  }

  Future<UserCredential> login(String identificador, String senha) async {
    String email = identificador;

    // Verifica se é email ou matrícula (simples regex ou presença de @)
    if (!identificador.contains('@')) {
      final emailEncontrado = await _getEmailByMatricula(identificador);
      if (emailEncontrado == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Matrícula não encontrada.',
        );
      }
      email = emailEncontrado;
    }

    return await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<UsuarioModel?> getUsuarioData(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      return UsuarioModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
