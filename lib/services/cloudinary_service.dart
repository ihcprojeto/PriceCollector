import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = 'dgccbfglb';
  final String uploadPreset = 'ml_default';

  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    if (folder != null) {
      request.fields['folder'] = folder;
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        print('Erro no upload Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao fazer upload: $e');
      return null;
    }
  }
}
