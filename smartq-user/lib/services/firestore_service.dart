import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get hospitals =>
      _firestore.collection('hospitals');

  CollectionReference<Map<String, dynamic>> get departments =>
      _firestore.collection('departments');

  CollectionReference<Map<String, dynamic>> get tokens =>
      _firestore.collection('tokens');

  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await users.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': '',
      'role': 'patient',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(String uid) async {
    return await users.doc(uid).get();
  }

  Future<void> saveToken({
    required String userId,
    required String hospitalId,
    required String hospitalName,
    required String departmentId,
    required String departmentName,
    required String tokenNumber,
    required int currentQueue,
    required String estimatedTime,
    required String issuedTime,
    required String status,
  }) async {
    await tokens.add({
      'userId': userId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'tokenNumber': tokenNumber,
      'currentQueue': currentQueue,
      'estimatedTime': estimatedTime,
      'issuedTime': issuedTime,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHospitals() async {
    return await hospitals
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDepartmentsByHospital(
      String hospitalId,
      ) async {
    return await departments
        .where('hospitalId', isEqualTo: hospitalId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getActiveTokensByUser(
      String userId,
      ) async {
    return await tokens
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Active')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getTokenHistoryByUser(
      String userId,
      ) async {
    return await tokens
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> updateTokenStatus({
    required String tokenId,
    required String status,
  }) async {
    await tokens.doc(tokenId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHospitals() {
    return hospitals
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDepartmentsByHospital(
      String hospitalId,
      ) {
    return departments
        .where('hospitalId', isEqualTo: hospitalId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamActiveTokensByUser(
      String userId,
      ) {
    return tokens
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Active')
        .orderBy('createdAt', descending: true)
        .snapshots();




















  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTokenHistoryByUser(
      String userId,
      ) {
    return tokens
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}