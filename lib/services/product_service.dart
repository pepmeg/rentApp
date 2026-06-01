import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Product>> getAllProducts({String? ownerId, bool includeAll = false}) async {
    Query query = _firestore.collection('products');
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    } else if (!includeAll) {
      query = query.where('moderationStatus', isEqualTo: 'active');
    }
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final rawData = doc.data();
      final Map<String, dynamic> data = (rawData is Map<String, dynamic>)
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }

  static Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 30) {
      chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
    }
    final results = <Product>[];
    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results.add(Product.fromJson(data));
      }
    }
    return results;
  }

  static Future<List<Product>> searchProducts(String query, {String? ownerId}) async {
    if (query.isEmpty) return getAllProducts(ownerId: ownerId);

    final lowerQuery = query.toLowerCase();
    final endQuery = '$lowerQuery\uf8ff';

    Query firestoreQuery = _firestore.collection('products');
    if (ownerId != null) {
      firestoreQuery = firestoreQuery.where('ownerId', isEqualTo: ownerId);
    } else {
      firestoreQuery = firestoreQuery.where('moderationStatus', isEqualTo: 'active');
    }

    firestoreQuery = firestoreQuery
        .where('nameLowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('nameLowercase', isLessThanOrEqualTo: endQuery)
        .orderBy('nameLowercase')
        .orderBy('createdAt', descending: true);

    final snapshot = await firestoreQuery.get();
    return snapshot.docs.map((doc) {
      final rawData = doc.data();
      final Map<String, dynamic> data = (rawData is Map<String, dynamic>)
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }

  static Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    data['id'] = doc.id;
    return Product.fromJson(data);
  }

  static Future<String> addProduct(Product product) async {
    final data = product.toJson();
    if (data['id'] == null || (data['id'] as String).isEmpty) {
      data.remove('id');
    }
    final docRef = await _firestore.collection('products').add(data);
    return docRef.id;
  }

  static Future<void> updateProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toJson());
  }

  static Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  static Future<void> updateProductStatus(String id, String newStatus) async {
    await _firestore.collection('products').doc(id).update({'moderationStatus': newStatus});
  }

  static Future<void> deleteProductsByOwner(String ownerId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('products')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}