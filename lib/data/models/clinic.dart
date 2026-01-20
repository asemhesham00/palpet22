import 'package:intl/intl.dart';

class Clinic {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String description;
  final String imageUrl;
  final double rating;
  final String phoneNumber;
  final bool isOpen;
  final String workingHours;
  final List<String> services;

  Clinic({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.phoneNumber,
    this.isOpen = true,
    this.workingHours = '09:00 AM - 10:00 PM',
    this.services = const [
      'Vaccination',
      'Surgery',
      'Dental Care',
      'Grooming',
      'Emergency'
    ],
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'phoneNumber': phoneNumber,
      'isOpen': isOpen,
      'workingHours': workingHours,
      'services': services,
    };
  }

  factory Clinic.fromMap(Map<String, dynamic> data, String id) {
    return Clinic(
      id: id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      phoneNumber: data['phoneNumber'] ?? '',
      isOpen: data['isOpen'] ?? true,
      workingHours: data['workingHours'] ?? '09:00 AM - 10:00 PM',
      services:
          (data['services'] is List) ? List<String>.from(data['services']) : [],
    );
  }

  bool get isWorkingNow {
    if (!isOpen) return false;

    if (workingHours.toLowerCase().contains("24")) return true;

    try {
      if (workingHours.isEmpty) return false;

      final parts = workingHours.contains(' - ')
          ? workingHours.split(' - ')
          : workingHours.split('-');

      if (parts.length != 2) return false;

      String normalizeTime(String rawTime) {
        String clean = rawTime.trim().toUpperCase();
        String period = "";
        if (clean.contains("AM")) {
          period = "AM";
          clean = clean.replaceAll("AM", "").trim();
        } else if (clean.contains("PM")) {
          period = "PM";
          clean = clean.replaceAll("PM", "").trim();
        }

        if (!clean.contains(":")) {
          clean = "$clean:00";
        }
        return "$clean $period".trim();
      }

      final startStr = normalizeTime(parts[0]);
      final endStr = normalizeTime(parts[1]);

      DateTime parseFlexible(String timeStr) {
        try {
          return DateFormat('h:mm a').parse(timeStr);
        } catch (_) {
          return DateFormat('h:mma').parse(timeStr.replaceAll(' ', ''));
        }
      }

      final now = DateTime.now();
      final startTimeRef = parseFlexible(startStr);
      final endTimeRef = parseFlexible(endStr);

      final openTime = DateTime(
          now.year, now.month, now.day, startTimeRef.hour, startTimeRef.minute);
      var closeTime = DateTime(
          now.year, now.month, now.day, endTimeRef.hour, endTimeRef.minute);

      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.hour < 12 && now.isBefore(closeTime)) return true;
        if (now.isAfter(openTime)) return true;
        return false;
      }

      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      return false;
    }
  }
}
