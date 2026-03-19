// lib/data/datasources/remote/auth_remote_datasource.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  );
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> updateUser(UserModel user);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl(this.firebaseAuth, this.firestore);

  @override
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      // Prevención de escalada de privilegios
      final safeRole = (role.toLowerCase() == 'admin') ? 'maestro' : role;

      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // Crea un documento de usuario en Firestore para almacenar el rol y otros datos
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: safeRole,
      );

      await firestore.collection('users').doc(uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      // Mapeo de códigos de Firebase a mensajes amigables
      switch (e.code) {
        case 'weak-password':
          throw Exception('La contraseña es demasiado débil');
        case 'email-already-in-use':
          throw Exception('El correo electrónico ya está en uso');
        case 'invalid-email':
          throw Exception('Correo electrónico inválido');
        case 'operation-not-allowed':
          throw Exception('La operación no está permitida');
        default:
          throw Exception('Error de autenticación: ${e.message ?? e.code}');
      }
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo obtener la información del usuario.');
      }
      final uid = user.uid;

      final userRef = firestore.collection('users').doc(uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        // Si no existe el doc de Firestore, lo creamos con datos mínimos
        final userModel = UserModel(
          uid: uid, 
          email: user.email ?? email, 
          name: user.displayName ?? 'Usuario',
          role: 'user'
        );
        await userRef.set(userModel.toMap());
        return userModel;
      }
      return UserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      // Mapeo de códigos de Firebase a mensajes amigables
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Usuario no encontrado');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'invalid-email':
          throw Exception('Correo electrónico inválido');
        case 'user-disabled':
          throw Exception('La cuenta de usuario está deshabilitada');
        case 'too-many-requests':
          throw Exception('Demasiados intentos, inténtalo más tarde');
        default:
          throw Exception('Error de autenticación: ${e.message ?? e.code}');
      }
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    }
    return null;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.uid).update(user.toMap());
      
      // También podríamos actualizar el perfil de FirebaseAuth si es necesario (nombre, foto)
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null && currentUser.uid == user.uid) {
         await currentUser.updateDisplayName(user.name);
      }

    } on FirebaseException catch (e) {
      throw Exception('Error al actualizar usuario: ${e.message ?? e.code}');
    }
  }
}
