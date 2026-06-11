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
    // 1. Buscar todas as coletas vinculadas a esta loja para exclusão em massa
    final coletasQuery = await _firestore
        .collection('coletas')
        .where('lojaId', isEqualTo: id)
        .get();

    // 2. Buscar todas as demandas vinculadas a esta loja (subcoleção)
    final demandasQuery = await _firestore
        .collection('lojas')
        .doc(id)
        .collection('demandas')
        .get();

    // 3. Preparar lista de referências para exclusão (batch processing)
    final List<DocumentReference> refsToDelete = [];
    
    // Coletas
    for (var doc in coletasQuery.docs) {
      refsToDelete.add(doc.reference);
    }
    
    // Demandas
    for (var doc in demandasQuery.docs) {
      refsToDelete.add(doc.reference);
    }
    
    // A própria loja
    refsToDelete.add(_firestore.collection('lojas').doc(id));

    // 4. Executar exclusão em lotes de no máximo 500 (limite do Firestore)
    for (var i = 0; i < refsToDelete.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < refsToDelete.length) ? i + 500 : refsToDelete.length;
      final chunk = refsToDelete.sublist(i, end);
      
      for (var ref in chunk) {
        batch.delete(ref);
      }
      
      await batch.commit();
    }
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
