import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loja_model.dart';

class LojaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addLoja(LojaModel loja) async {
    await _firestore.collection('lojas').add(loja.toMap());
  }

  Stream<List<LojaModel>> getLojas() {
    return _firestore.collection('lojas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LojaModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
