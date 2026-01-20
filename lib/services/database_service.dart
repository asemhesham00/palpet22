import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String username,
    required String location,
    File? imageFile,
  }) async {
    try {
      Map<String, dynamic> dataToUpdate = {
        'name': name,
        'username': username.toLowerCase(),
        'location': location,
      };

      if (imageFile != null) {
        String fileName = '${uid}_profile.jpg';
        Reference ref = _storage.ref().child('profile_images/$fileName');
        await ref.putFile(imageFile);
        String photoUrl = await ref.getDownloadURL();
        dataToUpdate['photoUrl'] = photoUrl;
      }

      await _db.collection('users').doc(uid).update(dataToUpdate);
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception("Failed to update profile information.");
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user data: $e");
    }
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Future<String> getUserName(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? 'Anonymous';
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return 'Anonymous';
  }

  Future<int> getUserPostCount(String uid) async {
    try {
      AggregateQuerySnapshot query = await _db
          .collection('pets')
          .where('ownerId', isEqualTo: uid)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      print("Error counting posts: $e");
      return 0;
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('pets_images/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Failed to upload image.");
    }
  }

  Stream<List<Pet>> getPets() {
    return _db
        .collection('pets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Pet.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Pet>> getUserPets(String uid) {
    return _db
        .collection('pets')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Pet.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String> addPet(Pet pet) async {
    try {
      DocumentReference docRef = await _db.collection('pets').add(pet.toMap());
      return docRef.id;
    } catch (e) {
      print("Error adding pet: $e");
      rethrow;
    }
  }

  Future<void> updatePet(Pet pet) async {
    try {
      await _db.collection('pets').doc(pet.id).update(pet.toMap());
    } catch (e) {
      print("Error updating pet: $e");
      throw Exception("Failed to update post.");
    }
  }

  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
  }

  Future<Pet?> getPetById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection('pets').doc(id).get();
      if (doc.exists) {
        return Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error getting pet: $e");
    }
    return null;
  }

  Future<void> addClinic(Clinic clinic) async {
    try {
      await _db.collection('clinics').add(clinic.toMap());
    } catch (e) {
      print("Error adding clinic: $e");
      throw Exception("Failed to add clinic.");
    }
  }

  Future<void> updateClinic(Clinic clinic) async {
    try {
      await _db.collection('clinics').doc(clinic.id).update(clinic.toMap());
    } catch (e) {
      print("Error updating clinic: $e");
      throw Exception("Failed to update clinic.");
    }
  }

  Future<void> deleteClinic(String id) async {
    try {
      await _db.collection('clinics').doc(id).delete();
    } catch (e) {
      print("Error deleting clinic: $e");
      throw Exception("Failed to delete clinic.");
    }
  }

  Stream<List<Clinic>> getClinics() {
    return _db
        .collection('clinics')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Clinic(
                id: doc.id,
                ownerId: data['ownerId'] ?? '',
                name: data['name'] ?? '',
                address: data['address'] ?? '',
                description: data['description'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                rating: (data['rating'] ?? 0.0).toDouble(),
                phoneNumber: data['phoneNumber'] ?? '',
                isOpen: data['isOpen'] ?? true,
                workingHours: data['workingHours'] ?? '09:00 AM - 10:00 PM',
                services: (data['services'] is List)
                    ? List<String>.from(data['services'])
                    : [],
              );
            }).toList());
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> checkAndSendNotifications(Pet newPet, String petId) async {
    try {
      if (newPet.postType == 'Found') {
        final matchesSnapshot = await _db
            .collection('pets')
            .where('postType', isEqualTo: 'Lost')
            .where('type', isEqualTo: newPet.type)
            .where('location', isEqualTo: newPet.location)
            .get();

        for (var doc in matchesSnapshot.docs) {
          final lostPetData = doc.data();
          final ownerId = lostPetData['ownerId'];
          if (ownerId != newPet.ownerId) {
            await _createNotification(
              userId: ownerId,
              title: "Possible Match! 🐾",
              body:
                  "A ${newPet.type} was found in ${newPet.location} matching your lost pet.",
              petId: petId,
              notificationType: 'found_match',
            );
          }
        }
      }

      if (newPet.postType == 'Lost') {
        final usersInAreaSnapshot = await _db
            .collection('users')
            .where('location', isEqualTo: newPet.location)
            .get();

        for (var doc in usersInAreaSnapshot.docs) {
          final targetUserId = doc.id;
          if (targetUserId != newPet.ownerId) {
            await _createNotification(
              userId: targetUserId,
              title: "Lost Pet Alert 🚨",
              body:
                  "A ${newPet.type} was lost in your area (${newPet.location}). Help find them!",
              petId: petId,
              notificationType: 'lost_alert',
            );
          }
        }
      }
    } catch (e) {
      print("Error sending notifications: $e");
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String petId,
    required String notificationType,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'petId': petId,
      'type': notificationType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getReviews(String itemId) {
    return _db
        .collection('reviews')
        .where('petId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserReviews(String userId) {
    return _db
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> getItemRatingStats(String itemId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('reviews')
          .where('petId', isEqualTo: itemId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double totalStars = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalStars += (data['rating'] ?? 0.0).toDouble();
      }

      double average = totalStars / snapshot.docs.length;
      return {'average': average, 'count': snapshot.docs.length};
    } catch (e) {
      print("Error calculating item rating: $e");
      return {'average': 0.0, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> getUserRatingStats(String userId,
      {String? reviewType}) async {
    try {
      Query query =
          _db.collection('reviews').where('targetUserId', isEqualTo: userId);
      if (reviewType != null) {
        query = query.where('reviewType', isEqualTo: reviewType);
      }
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double totalStars = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalStars += (data['rating'] ?? 0.0).toDouble();
      }

      double average = totalStars / snapshot.docs.length;
      return {'average': average, 'count': snapshot.docs.length};
    } catch (e) {
      print("Error calculating rating: $e");
      return {'average': 0.0, 'count': 0};
    }
  }

  Future<void> addReview({
    required String targetUserId,
    required String reviewerId,
    required double rating,
    required String comment,
    required String reviewType,
    String? petId,
  }) async {
    try {
      await _db.collection('reviews').add({
        'targetUserId': targetUserId,
        'reviewerId': reviewerId,
        'petId': petId,
        'rating': rating,
        'comment': comment,
        'reviewType': reviewType,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding review: $e");
      throw Exception("Failed to add review.");
    }
  }

  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _db.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating review: $e");
      throw Exception("Failed to update review.");
    }
  }

  Future<DocumentSnapshot?> getUserReview(
      String reviewerId, String targetUserId, String reviewType,
      {String? petId}) async {
    try {
      Query query = _db
          .collection('reviews')
          .where('reviewerId', isEqualTo: reviewerId)
          .where('reviewType', isEqualTo: reviewType);

      if (petId != null) {
        query = query.where('petId', isEqualTo: petId);
      } else {
        query = query.where('targetUserId', isEqualTo: targetUserId);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first;
      }
      return null;
    } catch (e) {
      print("Error checking review status: $e");
      return null;
    }
  }

  Future<bool> hasUserReviewed(
      String reviewerId, String targetUserId, String reviewType,
      {String? petId}) async {
    try {
      final doc = await getUserReview(reviewerId, targetUserId, reviewType,
          petId: petId);
      return doc != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleFavorite(String userId, String petId) async {
    final docRef =
        _db.collection('users').doc(userId).collection('favorites').doc(petId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isFavorite(String userId, String petId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(petId)
        .get();
    return doc.exists;
  }

  Stream<List<Pet>> getUserFavorites(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<String> petIds = snapshot.docs.map((doc) => doc.id).toList();
      if (petIds.isEmpty) return [];

      List<Pet> favoritePets = [];
      for (String id in petIds) {
        try {
          var petDoc = await _db.collection('pets').doc(id).get();
          if (petDoc.exists) {
            favoritePets.add(Pet.fromMap(petDoc.data()!, petDoc.id));
          }
        } catch (e) {
          print("Error fetching favorite pet $id: $e");
        }
      }
      return favoritePets;
    });
  }

  Future<void> addBooking({
    required String userId,
    required String providerId,
    required String serviceType,
    required String itemName,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _db.collection('bookings').add({
        'userId': userId,
        'providerId': providerId,
        'serviceType': serviceType,
        'itemName': itemName,
        'details': details,
        'status': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding booking: $e");
      throw Exception("Failed to add booking record.");
    }
  }

  Stream<List<Map<String, dynamic>>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<int> getUserBookingsCount(String userId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
