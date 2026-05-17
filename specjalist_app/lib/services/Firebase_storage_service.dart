import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  // Dodajemy parametr userId, przekazywany z profilu/sesji Twojego API
  static Future<String> uploadAvatar(File file, String userId) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('$userId.jpg'); // Zdjęcie zapisze się jako np. avatars/123.jpg

    // Wysyłanie pliku do Firebase
    await ref.putFile(file);

    // Pobranie publicznego linku URL do zdjęcia
    return await ref.getDownloadURL();
  }
}