import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploader {
  static const cloudName = 'zwbdjibj';
  static const preset = 'immobilier_unsigned';

  static Future<String> upload(XFile file) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Envoi de la photo échoué (${response.statusCode})');
    }
    return jsonDecode(response.body)['secure_url'] as String;
  }
}