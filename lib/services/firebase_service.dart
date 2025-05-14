// lib/services/firebase_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const uuid = Uuid();

  /// Uploads plant disease data to Firebase
  static Future<void> uploadPlantData({
    required File imageFile,
    required String plantName,
    required String diseaseName,
    String? additionalInfo,
    required String location,
    required double temperature,
    required double humidity,
    required DateTime time,
  }) async {
    final imageId = uuid.v4();
    final fileName = path.basename(imageFile.path);
    final firebasePath = 'plants/$plantName/$diseaseName/$imageId-$fileName';

    final ref = _storage.ref().child(firebasePath);
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestore.collection('plant_data').add({
      'plantName': plantName,
      'diseaseName': diseaseName,
      'otherInfo': additionalInfo ?? '',
      'imageUrl': downloadUrl,
      'imagePath': firebasePath,
      'timestamp': FieldValue.serverTimestamp(),
      'downloaded': false,
      'location': location,
      'temperature': temperature,
      'humidity': humidity,
      'recordedTime': time.toIso8601String(),
    });
  }

  /// Gets a list of all plant data entries
  static Future<List<Map<String, dynamic>>> getAllPlantData() async {
    final snapshot = await _firestore.collection('plant_data').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Gets plant data entries that haven't been downloaded yet
  static Future<List<Map<String, dynamic>>> getNewPlantData() async {
    final snapshot =
        await _firestore
            .collection('plant_data')
            .where('downloaded', isEqualTo: false)
            .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Marks a plant data entry as downloaded
  static Future<void> markAsDownloaded(String documentId) async {
    await _firestore.collection('plant_data').doc(documentId).update({
      'downloaded': true,
    });
  }

  /// Deletes a plant data entry and its associated file
  static Future<void> deletePlantData(
    String documentId,
    String imagePath,
  ) async {
    // Delete the file from Storage
    await _storage.ref().child(imagePath).delete();

    // Delete the document from Firestore
    await _firestore.collection('plant_data').doc(documentId).delete();
  }
}
