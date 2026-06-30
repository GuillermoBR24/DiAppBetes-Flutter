import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static const String _endpoint =
      'https://formsubmit.co/ajax/diappbetes0@gmail.com';

  static Future<bool> sendReport({
    required String type,
    required String title,
    required String description,
  }) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No identificado';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'N/A';

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          '_subject': '[$type] $title',
          'Tipo': type,
          'Título': title,
          'Descripción': description,
          'Usuario': userEmail,
          'UID': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}