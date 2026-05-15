import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coleta_model.dart';

class ColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> salvarColeta(ColetaModel coleta, String demandaId) async {
    final batch = _firestore.batch();

    if (coleta.id == null || coleta.id!.isEmpty) {
      // 1. Criar nova coleta
      final coletaRef = _firestore.collection('coletas').doc();
      batch.set(coletaRef, coleta.toMap());
    } else {
      // 1. Atualizar coleta existente
      final coletaRef = _firestore.collection('coletas').doc(coleta.id);
      batch.update(coletaRef, coleta.toMap());
    }

    // 2. Atualizar o status da demanda na subcoleção da loja
    final demandaRef = _firestore
        .collection('lojas')
        .doc(coleta.lojaId)
        .collection('demandas')
        .doc(demandaId);
    
    batch.update(demandaRef, {'status': 'coletado'});

    await batch.commit();
  }

  Stream<List<ColetaModel>> getColetas({String? lojaId, String? usuarioId}) {
    Query query = _firestore.collection('coletas');
    
    if (lojaId != null && lojaId.isNotEmpty) {
      query = query.where('lojaId', isEqualTo: lojaId);
    }

    if (usuarioId != null && usuarioId.isNotEmpty) {
      query = query.where('usuarioId', isEqualTo: usuarioId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ColetaModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> excluirColeta(String coletaId, String lojaId, String barcode) async {
    final batch = _firestore.batch();

    // 1. Deletar documento da coleção coletas
    batch.delete(_firestore.collection('coletas').doc(coletaId));

    // 2. Buscar a demanda correspondente para voltar o status para pendente
    // Como o firestore.md não define o ID da demanda dentro da coleta, 
    // precisamos buscar pela loja e barcode.
    final demandaQuery = await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (demandaQuery.docs.isNotEmpty) {
      batch.update(demandaQuery.docs.first.reference, {'status': 'pendente'});
    }

    await batch.commit();
  }
}
