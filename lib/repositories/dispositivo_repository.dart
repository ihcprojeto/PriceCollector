import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dispositivo_model.dart';
import '../models/coleta_model.dart';

class DispositivoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DispositivoModel>> getAllDispositivos() async {
    final query = await _firestore.collection('dispositivos').get();
    return query.docs
        .map((doc) => DispositivoModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> toggleStatus(String id, bool status) async {
    await _firestore.collection('dispositivos').doc(id).update({'ativo': status});
  }

  Future<List<ColetaModel>> getHistoricoDispositivo(String dispositivoId) async {
    final query = await _firestore
        .collection('coletas')
        .where('dispositivoId', isEqualTo: dispositivoId)
        .get();
    
    return query.docs.map((doc) => ColetaModel.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<List<ColetaModel>> getAllColetas() async {
    final query = await _firestore.collection('coletas').get();
    return query.docs.map((doc) => ColetaModel.fromFirestore(doc.data(), doc.id)).toList();
  }
}
