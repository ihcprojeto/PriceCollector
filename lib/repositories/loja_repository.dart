import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loja_model.dart';

class LojaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addLoja(LojaModel loja) async {
    await _firestore.collection('lojas').add(loja.toMap());
  }

  Future<void> updateLoja(LojaModel loja) async {
    if (loja.id != null) {
      await _firestore.collection('lojas').doc(loja.id).update(loja.toMap());
    }
  }

  Future<void> deleteLoja(String id) async {
    await _firestore.collection('lojas').doc(id).delete();
  }

  Stream<List<LojaModel>> getLojas() {
    return _firestore
        .collection('lojas')
        .where('ativo', isEqualTo: true) // Filtrando apenas ativas conforme firestore.md
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LojaModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
