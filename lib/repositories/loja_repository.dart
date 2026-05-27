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

      final coletasQuery = await _firestore
          .collection('coletas')
          .where('lojaId', isEqualTo: loja.id)
          .get();

      if (coletasQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in coletasQuery.docs) {
          batch.update(doc.reference, {'lojaNome': loja.nome});
        }
        await batch.commit();
      }
    }
  }

  Future<void> deleteLoja(String id) async {
    await _firestore.collection('lojas').doc(id).delete();
  }

  Stream<List<LojaModel>> getLojas() {
    return _firestore
        .collection('lojas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LojaModel.fromMap(doc.data(), doc.id))
          .where((loja) => loja.ativo)
          .toList();
    });
  }

  Future<List<LojaModel>> getLojasList() async {
    final snapshot = await _firestore
        .collection('lojas')
        .get();
    return snapshot.docs
        .map((doc) => LojaModel.fromMap(doc.data(), doc.id))
        .where((loja) => loja.ativo)
        .toList();
  }
}
