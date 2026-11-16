import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/admin_nav_helper.dart';

class MaintenanceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String?> checkMaintenanceMode() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      
      final maintenanceMode = data['maintenance_mode'] ?? false;
      final maintenanceMessage = data['maintenance_message']?.toString() ?? '';
      
      if (!maintenanceMode) {
        return null;
      }
      
      final user = _auth.currentUser;
      
      if (user == null) {
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        return msg;
      }
      
      final profileDoc = await _db.collection('profiles').doc(user.uid).get();
      
      if (!profileDoc.exists) {
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        return msg;
      }
      
      final profileData = profileDoc.data()!;
      
      final role = profileData['role']?.toString().toLowerCase() ?? '';
      
      final isAdmin = AdminNavHelper.isAdminRole(role);
      
      if (isAdmin) {
        return null;
      }
      
      final msg = maintenanceMessage.isNotEmpty 
          ? maintenanceMessage 
          : 'La aplicación está en mantenimiento. Intente más tarde.';
      return msg;
          
    } catch (e) {
      return null;
    }
  }

  Future<bool> isMaintenanceActive() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      if (!doc.exists) return false;
      return doc.data()?['maintenance_mode'] ?? false;
    } catch (e) {
      return false;
    }
  }
}