import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loja_model.dart';

class LojaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LojaModel>> getLojas() async {
    final query = await _firestore.collection('lojas').where('ativo', isEqualTo: true).get();
    return query.docs
        .map((doc) => LojaModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteLoja(String id) async {
    final coletas = await _firestore.collection('coletas').where('lojaId', isEqualTo: id).get();
    final demandas = await _firestore.collection('lojas').doc(id).collection('demandas').get();
    
    final batch = _firestore.batch();
    for (var doc in coletas.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in demandas.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('lojas').doc(id));
    
    await batch.commit();
  }
}
