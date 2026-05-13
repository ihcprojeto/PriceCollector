import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coleta_model.dart';

class ColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> salvarColeta(ColetaModel coleta, String demandaId) async {
    final batch = _firestore.batch();

    // 1. Criar o documento na coleção 'coletas'
    final coletaRef = _firestore.collection('coletas').doc();
    batch.set(coletaRef, coleta.toMap());

    // 2. Atualizar o status da demanda na subcoleção da loja
    final demandaRef = _firestore
        .collection('lojas')
        .doc(coleta.lojaId)
        .collection('demandas')
        .doc(demandaId);
    
    batch.update(demandaRef, {'status': 'coletado'});

    await batch.commit();
  }
}
