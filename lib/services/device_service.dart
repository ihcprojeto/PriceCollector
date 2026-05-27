import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dispositivo_model.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DispositivoModel>> getDispositivos() async {
    final query = await _firestore.collection('dispositivos').get();
    return query.docs
        .map((doc) => DispositivoModel.fromFirestore(doc.data(), doc.id))
        .where((d) => d.ativo)
        .toList();
  }
}
