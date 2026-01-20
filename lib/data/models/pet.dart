import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String ownerId;
  final String postType; 
  final String name;
  final String type; 
  final String breed;
  final String gender;
  final String age;
  final String description;
  final String imageUrl;
  final String location;
  final String contactPhone;
  

  final String contactEmail; 
  final List<String> healthTags;

  final String? reward;      
  final String? price;     
  final String? capacity;   
  final String? amenities;   
  final DateTime? createdAt;

  Pet({
    this.id = '',
    required this.ownerId,
    required this.postType,
    required this.name,
    required this.type,
    required this.breed,
    required this.gender,
    required this.age,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.contactPhone,

    this.contactEmail = '', 
    this.healthTags = const [],
    
    this.reward,
    this.price,
    this.capacity,
    this.amenities,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'postType': postType,
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender,
      'age': age,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'healthTags': healthTags,
      'reward': reward,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map, String documentId) {
    return Pet(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      postType: map['postType'] ?? 'Adoption',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      breed: map['breed'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      

      contactEmail: map['contactEmail'] ?? '',
      healthTags: (map['healthTags'] is List) 
          ? List<String>.from(map['healthTags']) 
          : [],

      reward: map['reward'],
      price: map['price'],
      capacity: map['capacity'],
      amenities: map['amenities'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }
}