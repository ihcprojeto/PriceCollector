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
    await _firestore.collection('lojas').doc(id).delete();
  }
}
