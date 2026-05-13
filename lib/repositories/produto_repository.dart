import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/demanda_model.dart';

class ProdutoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DemandaModel>> getDemandas(String lojaId) {
    return _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DemandaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> atualizarStatusDemanda(String lojaId, String demandaId, String novoStatus) async {
    await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .doc(demandaId)
        .update({'status': novoStatus});
  }

  Future<void> importarDemandas(String lojaId, List<DemandaModel> novasDemandas) async {
    final batch = _firestore.batch();
    final demandasCollection = _firestore.collection('lojas').doc(lojaId).collection('demandas');
    final produtosCollection = _firestore.collection('produtos');

    for (var demanda in novasDemandas) {
      // Salva na subcoleção de demandas da loja
      final demandaDocRef = demandasCollection.doc();
      batch.set(demandaDocRef, demanda.toMap());

      // Salva na coleção global de produtos (usando barcode como ID para evitar duplicatas)
      final produtoDocRef = produtosCollection.doc(demanda.barcode);
      batch.set(produtoDocRef, {
        'barcode': demanda.barcode,
        'descricao': demanda.produtoDescricao,
        'imagemUrl': demanda.produtoImagemUrl,
        'marca': demanda.produtoMarca,
        'nome': demanda.produtoNome,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<DemandaModel?> getDemandaByBarcode(String lojaId, String barcode) async {
    final query = await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return DemandaModel.fromFirestore(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }
}
