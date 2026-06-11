import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/demanda_model.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProdutoModel>> getTodosProdutos() async {
    final snapshot = await _firestore.collection('produtos').get();
    return snapshot.docs.map((doc) => ProdutoModel.fromFirestore(doc.data())).toList();
  }

  Future<void> excluirProdutoPermanente(String barcode) async {
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('produtos').doc(barcode));

    final lojasSnapshot = await _firestore.collection('lojas').get();
    for (var lojaDoc in lojasSnapshot.docs) {
      batch.delete(lojaDoc.reference.collection('demandas').doc(barcode));
    }

    await batch.commit();
  }

  Future<int> getContagemLojasDoProduto(String barcode) async {
    final lojasSnapshot = await _firestore.collection('lojas').get();
    int count = 0;
    
    for (var lojaDoc in lojasSnapshot.docs) {
      final doc = await lojaDoc.reference.collection('demandas').doc(barcode).get();
      if (doc.exists) count++;
    }
    
    return count;
  }

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

  Future<void> deletarDemanda(String lojaId, String demandaId) async {
    await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .doc(demandaId)
        .delete();
  }

  Future<int> importarDemandas(String lojaId, List<DemandaModel> novasDemandas) async {
    final snapshot = await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .get();
    
    final existingBarcodes = snapshot.docs.map((doc) => doc.data()['barcode'] as String).toSet();
    
    final demandasCollection = _firestore.collection('lojas').doc(lojaId).collection('demandas');
    final produtosCollection = _firestore.collection('produtos');

    int ignoredCount = 0;
    List<DemandaModel> aImportar = [];

    for (var demanda in novasDemandas) {
      if (existingBarcodes.contains(demanda.barcode)) {
        ignoredCount++;
        continue;
      }
      aImportar.add(demanda);
      existingBarcodes.add(demanda.barcode);
    }

    if (aImportar.isEmpty) return ignoredCount;

    for (var i = 0; i < aImportar.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < aImportar.length) ? i + 500 : aImportar.length;
      final chunk = aImportar.sublist(i, end);

      for (var demanda in chunk) {
        final demandaDocRef = demandasCollection.doc(demanda.barcode);
        batch.set(demandaDocRef, demanda.toMap());

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
    
    return ignoredCount;
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

  Future<Set<String>> _getActiveLojaIds() async {
    final snapshot = await _firestore.collection('lojas').where('ativo', isEqualTo: true).get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  Future<int> getColetadosDemandas({String? lojaId}) async {
    if (lojaId != null && lojaId.isNotEmpty) {
      final snapshot = await _firestore
          .collection('lojas')
          .doc(lojaId)
          .collection('demandas')
          .where('status', isEqualTo: 'coletado')
          .get();
      return snapshot.size;
    } else {
      final activeIds = await _getActiveLojaIds();
      try {
        final snapshot = await _firestore
            .collectionGroup('demandas')
            .where('status', isEqualTo: 'coletado')
            .get();
        return snapshot.docs.where((doc) => activeIds.contains(doc.reference.parent.parent?.id)).length;
      } catch (e) {
        final snapshot = await _firestore.collectionGroup('demandas').get();
        return snapshot.docs.where((doc) {
          final storeId = doc.reference.parent.parent?.id;
          final status = doc.data()['status'];
          return activeIds.contains(storeId) && status == 'coletado';
        }).length;
      }
    }
  }

  Future<int> getTotalDemandas({String? lojaId}) async {
    if (lojaId != null && lojaId.isNotEmpty) {
      final snapshot = await _firestore
          .collection('lojas')
          .doc(lojaId)
          .collection('demandas')
          .where('status', isNotEqualTo: 'cancelado')
          .get();
      return snapshot.size;
    } else {
      final activeIds = await _getActiveLojaIds();
      try {
        final snapshot = await _firestore
            .collectionGroup('demandas')
            .where('status', isNotEqualTo: 'cancelado')
            .get();
        return snapshot.docs.where((doc) => activeIds.contains(doc.reference.parent.parent?.id)).length;
      } catch (e) {
        final snapshot = await _firestore.collectionGroup('demandas').get();
        return snapshot.docs.where((doc) {
          final storeId = doc.reference.parent.parent?.id;
          final status = doc.data()['status'];
          return activeIds.contains(storeId) && status != 'cancelado';
        }).length;
      }
    }
  }
}
