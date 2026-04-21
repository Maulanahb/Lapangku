import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import file-file yang sudah kamu buat sebelumnya
import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/owner_repository.dart';
import '../../domain/repositories/owner_repository_impl.dart';
import '../../data/datasources/owner_remote_data_source.dart';

// 1. Provider untuk instance FirebaseFirestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// 2. Provider untuk DataSource
final ownerRemoteDataSourceProvider = Provider<OwnerRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OwnerRemoteDataSourceImpl(firestore: firestore);
});

// 3. Provider untuk Repository (Jembatan antara Data dan Domain)
final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  final dataSource = ref.watch(ownerRemoteDataSourceProvider);
  return OwnerRepositoryImpl(remoteDataSource: dataSource);
});

// 4. FutureProvider untuk mengambil data lapangan dari Firestore
// Kita pakai .family karena kita butuh passing ownerId (UID user yang login)
final ownerFieldsProvider = FutureProvider.family<List<FieldEntity>, String>((ref, ownerId) async {
  final repository = ref.watch(ownerRepositoryProvider);
  return repository.getOwnerFields(ownerId);
});