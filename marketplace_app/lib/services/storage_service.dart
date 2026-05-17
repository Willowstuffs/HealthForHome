import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static const int _maxBytes = 5 * 1024 * 1024;

  Future<File?> pickAvatarFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final ext = _extensionForPath(file.path);
    if (!_allowedExtensions.contains(ext)) {
      throw Exception('Nieprawidłowe rozszerzenie pliku. Dozwolone: jpg, jpeg, png, webp');
    }

    if (file.lengthSync() > _maxBytes) {
      throw Exception('Plik jest za duży. Maksymalny rozmiar to 5 MB.');
    }

    return file;
  }

  String _extensionForPath(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }
}
