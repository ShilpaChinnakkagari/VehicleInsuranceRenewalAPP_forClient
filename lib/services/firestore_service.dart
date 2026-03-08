import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if user is admin
  Future<bool> isAdmin(String email) async {
    try {
      final query = await _db
          .collection('admin_users')
          .where('email', isEqualTo: email)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Add admin (use once)
  Future<void> addAdmin(String email) async {
    await _db.collection('admin_users').add({
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Add customer
  Future<void> addCustomer(Map<String, dynamic> data) async {
    await _db.collection('customers').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Get today's due customers
  Stream<QuerySnapshot> getTodayDueCustomers() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _db
        .collection('customers')
        .where('renewal_date', isEqualTo: today)
        .orderBy('name')
        .snapshots();
  }

  // Update status
  Future<void> updateStatus(String docId, String status) async {
    await _db.collection('customers').doc(docId).update({
      'status': status,
      'last_contacted_date': FieldValue.serverTimestamp(),
    });
  }
}