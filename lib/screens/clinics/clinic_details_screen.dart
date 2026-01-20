import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/clinic.dart';
import '../../services/database_service.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen>
    with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();
  late Clinic _clinic;
  int _selectedTab = 0;
  bool _isOwner = false;
  bool _isCallClicked = false;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    WidgetsBinding.instance.addObserver(this);
    _checkOwnership();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCallClicked) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isCallClicked = false;
          });
          _checkAndShowRatingDialog();
        }
      });
    }
  }

  void _checkOwnership() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.clinic.ownerId) {
      setState(() {
        _isOwner = true;
      });
    }
  }

  void _showReviewsModal() {
    final currentUser = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Reviews",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _checkAndShowRatingDialog();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Write a Review"),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getReviews(_clinic.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(child: Text("Something went wrong"));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_outlined,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No reviews yet. Be the first!",
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        );
                      }

                      return ListView.builder(
                        controller: controller,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final double rating =
                              (data['rating'] ?? 0.0).toDouble();
                          final String comment = data['comment'] ?? '';
                          final String reviewerId = data['reviewerId'] ?? '';
                          final Timestamp? createdAt = data['createdAt'];

                          // Check if it's my review
                          final bool isMyReview = currentUser != null &&
                              reviewerId == currentUser.uid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: isMyReview 
                                ? Border.all(color: AppColors.primary.withOpacity(0.3)) 
                                : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FutureBuilder<String>(
                                      future:
                                          _dbService.getUserName(reviewerId),
                                      builder: (context, nameSnapshot) {
                                        return Text(
                                          isMyReview ? "You" : (nameSnapshot.data ?? "Loading..."),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          createdAt != null
                                              ? DateFormat.yMMMd()
                                                  .format(createdAt.toDate())
                                              : '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500]),
                                        ),
                                        if (isMyReview)
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 16,
                                                color: AppColors.primary),
                                            constraints: const BoxConstraints(),
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showEditReviewDialog(
                                                  doc.id, rating, comment);
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                        color: AppColors.textDark, height: 1.4),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkAndShowRatingDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (currentUser.uid == _clinic.ownerId) return;

    DocumentSnapshot? existingReview = await _dbService.getUserReview(
      currentUser.uid,
      _clinic.ownerId,
      'clinic',
      petId: _clinic.id,
    );

    if (!mounted) return;

    if (existingReview != null) {
      final data = existingReview.data() as Map<String, dynamic>;
      _showEditReviewDialog(
        existingReview.id,
        (data['rating'] ?? 0.0).toDouble(),
        data['comment'] ?? '',
      );
    } else {
      _showRatingDialog(currentUser.uid);
    }
  }

  void _showEditReviewDialog(
      String reviewId, double currentRating, String currentComment) {
    double rating = currentRating;
    TextEditingController commentController =
        TextEditingController(text: currentComment);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Update your rating"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "Update comment (optional)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating > 0) {
                      await _dbService.updateReview(
                        reviewId: reviewId,
                        rating: rating,
                        comment: commentController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Review updated successfully!"),
                          backgroundColor: Colors.green,
                        ));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(String currentUserId) {
    double rating = 0;
    TextEditingController commentController = TextEditingController();
    bool isTransactionConfirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                      isTransactionConfirmed
                          ? Icons.star
                          : Icons.check_circle_outline,
                      color: isTransactionConfirmed
                          ? Colors.amber
                          : AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                      isTransactionConfirmed ? "Rate Clinic" : "Service Check"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTransactionConfirmed) ...[
                    const Text(
                      "Did you visit or contact this clinic successfully?",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("No",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setStateDialog(() {
                              isTransactionConfirmed = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text("How was your experience?"),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment (optional)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: isTransactionConfirmed
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Skip",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (rating > 0) {
                            await _dbService.addReview(
                              targetUserId: _clinic.ownerId,
                              reviewerId: currentUserId,
                              rating: rating,
                              comment: commentController.text,
                              reviewType: 'clinic',
                              petId: _clinic.id,
                            );

                            await _dbService.addBooking(
                              userId: currentUserId,
                              providerId: _clinic.ownerId,
                              serviceType: 'Vet Clinic',
                              itemName: _clinic.name,
                              details: {
                                'ratingGiven': rating,
                                'location': _clinic.address,
                              },
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Thanks for your feedback!"),
                                backgroundColor: Colors.green,
                              ));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Please select a star rating")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Submit"),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    );
  }

  bool _isClinicOpen(String workingHours) {
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
      final format = DateFormat('h:mm a');
      final now = DateTime.now();

      DateTime startTimeRef;
      DateTime endTimeRef;

      DateTime parseFlexible(String timeStr) {
        try {
          return format.parse(timeStr);
        } catch (_) {
          return DateFormat('h:mma').parse(timeStr.replaceAll(' ', ''));
        }
      }

      startTimeRef = parseFlexible(startStr);
      endTimeRef = parseFlexible(endStr);

      final openTime = DateTime(
          now.year, now.month, now.day, startTimeRef.hour, startTimeRef.minute);
      var closeTime = DateTime(
          now.year, now.month, now.day, endTimeRef.hour, endTimeRef.minute);

      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.hour < 12 && now.isBefore(closeTime)) {
          return true;
        }
        if (now.isAfter(openTime) ||
            now.isBefore(DateTime(now.year, now.month, now.day, endTimeRef.hour,
                endTimeRef.minute))) {
          return true;
        }
      }
      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    setState(() {
      _isCallClicked = true;
    });

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        setState(() => _isCallClicked = false);
      }
    } catch (e) {
      setState(() => _isCallClicked = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                "Delete Clinic?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to remove \"${_clinic.name}\"?\nThis action cannot be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _dbService.deleteClinic(_clinic.id);
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _clinic.name);
    final phoneController = TextEditingController(text: _clinic.phoneNumber);
    final addressController = TextEditingController(text: _clinic.address);
    final descController = TextEditingController(text: _clinic.description);

    final serviceInputController = TextEditingController();
    List<String> servicesList = List.from(_clinic.services);

    final openHourController = TextEditingController();
    final openMinuteController = TextEditingController();
    final closeHourController = TextEditingController();
    final closeMinuteController = TextEditingController();

    String openPeriod = "AM";
    String closePeriod = "PM";

    try {
      final parts = _clinic.workingHours.split(' - ');
      if (parts.length == 2) {
        final startParts = parts[0].trim().split(' ');
        final endParts = parts[1].trim().split(' ');

        if (startParts.length >= 2) {
          openPeriod = startParts[1];
          final timeParts = startParts[0].split(':');
          if (timeParts.length >= 1) openHourController.text = timeParts[0];
          if (timeParts.length >= 2) openMinuteController.text = timeParts[1];
        }

        if (endParts.length >= 2) {
          closePeriod = endParts[1];
          final timeParts = endParts[0].split(':');
          if (timeParts.length >= 1) closeHourController.text = timeParts[0];
          if (timeParts.length >= 2) closeMinuteController.text = timeParts[1];
        }
      }
    } catch (_) {
      openHourController.text = "9";
      openMinuteController.text = "00";
      closeHourController.text = "5";
      closeMinuteController.text = "00";
    }

    File? newImageFile;
    bool isOpen = _clinic.isOpen;
    bool isUpdating = false;
    bool showErrors = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;

              void addService() {
                final text = serviceInputController.text.trim();
                if (text.isNotEmpty) {
                  setSheetState(() {
                    servicesList.add(text);
                    serviceInputController.clear();
                  });
                }
              }

              void removeService(String item) {
                setSheetState(() {
                  servicesList.remove(item);
                });
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Edit Clinic",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding:
                            EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setSheetState(() {
                                      newImageFile = File(pickedFile.path);
                                    });
                                  }
                                },
                                child: Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    image: DecorationImage(
                                      image: newImageFile != null
                                          ? FileImage(newImageFile!)
                                          : NetworkImage(_clinic.imageUrl)
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      const Center(
                                          child: Icon(Icons.edit,
                                              color: Colors.white, size: 40)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildStyledInputField(
                                "Clinic Name",
                                nameController,
                                Icons.local_hospital,
                                showErrors,
                                true),
                            const SizedBox(height: 16),
                            _buildStyledInputField("Address", addressController,
                                Icons.location_on, showErrors, true),
                            const SizedBox(height: 16),
                            _buildStyledInputField("Phone Number",
                                phoneController, Icons.phone, showErrors, true,
                                inputType: TextInputType.phone),
                            const SizedBox(height: 24),
                            const Text("Working Hours",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSplitTimeInput(
                                    label: "Opens At",
                                    hourController: openHourController,
                                    minuteController: openMinuteController,
                                    period: openPeriod,
                                    onPeriodChanged: (val) =>
                                        setSheetState(() => openPeriod = val!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSplitTimeInput(
                                    label: "Closes At",
                                    hourController: closeHourController,
                                    minuteController: closeMinuteController,
                                    period: closePeriod,
                                    onPeriodChanged: (val) =>
                                        setSheetState(() => closePeriod = val!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text("Services",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: serviceInputController,
                                    decoration: InputDecoration(
                                      hintText: "e.g. Surgery, Vaccination",
                                      filled: true,
                                      fillColor: const Color(0xFFF9FAFB),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: addService,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: servicesList.map((service) {
                                return Chip(
                                  label: Text(service),
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => removeService(service),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            _buildStyledInputField(
                              "Description",
                              descController,
                              Icons.description,
                              false,
                              false,
                              maxLines: 3,
                              onTap: () {
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  if (scrollController.hasClients) {
                                    scrollController.animateTo(
                                      scrollController.position.maxScrollExtent,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isUpdating
                                    ? null
                                    : () async {
                                        setSheetState(() => showErrors = true);
                                        if (nameController.text.isEmpty ||
                                            phoneController.text.isEmpty ||
                                            addressController.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "Please fill in all required fields marked in red"),
                                            backgroundColor: Colors.red,
                                          ));
                                          return;
                                        }

                                        setSheetState(() => isUpdating = true);

                                        String finalImageUrl = _clinic.imageUrl;
                                        if (newImageFile != null) {
                                          try {
                                            finalImageUrl = await _dbService
                                                .uploadImage(newImageFile!);
                                          } catch (e) {
                                            print("Error updating image: $e");
                                          }
                                        }

                                        final String finalWorkingHours =
                                            "${openHourController.text}:${openMinuteController.text} $openPeriod - ${closeHourController.text}:${closeMinuteController.text} $closePeriod";

                                        final updatedClinic = Clinic(
                                          id: _clinic.id,
                                          ownerId: _clinic.ownerId,
                                          name: nameController.text,
                                          address: addressController.text,
                                          description: descController.text,
                                          imageUrl: finalImageUrl,
                                          rating: _clinic.rating,
                                          phoneNumber: phoneController.text,
                                          isOpen: isOpen,
                                          workingHours: finalWorkingHours,
                                          services: servicesList.isNotEmpty
                                              ? servicesList
                                              : ['General Checkup'],
                                        );

                                        await _dbService
                                            .updateClinic(updatedClinic);

                                        if (mounted) {
                                          setState(() {
                                            _clinic = updatedClinic;
                                          });
                                          Navigator.pop(context);
                                        }
                                      },
                                child: isUpdating
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        "Save Changes",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStyledInputField(String label, TextEditingController controller,
      IconData icon, bool showErrors, bool isRequired,
      {TextInputType inputType = TextInputType.text,
      int maxLines = 1,
      VoidCallback? onTap}) {
    bool isError = showErrors && isRequired && controller.text.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: isError
                  ? const BorderSide(color: Colors.red)
                  : BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text("Required",
                style: TextStyle(color: Colors.red[700], fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildSplitTimeInput({
    required String label,
    required TextEditingController hourController,
    required TextEditingController minuteController,
    required String period,
    required Function(String?) onPeriodChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: "HH",
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const Text(":",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey)),
              Expanded(
                child: TextField(
                  controller: minuteController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: "MM",
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: period,
                    items: ["AM", "PM"]
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: onPeriodChanged,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: _isOwner
            ? [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppColors.primary, size: 20),
                    onPressed: _showEditDialog,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12, left: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: _confirmDelete,
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 320,
              width: double.infinity,
              child: Image.network(
                _clinic.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _clinic.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showReviewsModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.serviceVetBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _dbService.getItemRatingStats(_clinic.id),
                            builder: (context, snapshot) {
                              String ratingText = "New";
                              String countText = "";
                              if (snapshot.hasData) {
                                double avg = snapshot.data!['average'] ?? 0.0;
                                int count = snapshot.data!['count'] ?? 0;
                                if (count > 0) {
                                  ratingText = avg.toStringAsFixed(1);
                                  countText = " ($count)";
                                }
                              }
                              return Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$ratingText$countText",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right,
                                      size: 16, color: Colors.grey),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton("Details", 0),
                        _buildTabButton("Hours", 1),
                        _buildTabButton("Services", 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentTabContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDetailsContent();
      case 1:
        return _buildHoursContent();
      case 2:
        return _buildServicesContent();
      default:
        return _buildDetailsContent();
    }
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("About Clinic",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          _clinic.description,
          style: const TextStyle(
              color: AppColors.textGrey, height: 1.6, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Text("Location",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                child: const Icon(Icons.location_on,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _clinic.address,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Contact Info",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.phone, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Phone Number",
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _clinic.phoneNumber,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _makePhoneCall(_clinic.phoneNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("Call",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoursContent() {
    final bool isOpenNow = _isClinicOpen(_clinic.workingHours);

    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isOpenNow ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isOpenNow ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isOpenNow ? Icons.check_circle : Icons.cancel,
                size: 50,
                color: isOpenNow ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isOpenNow ? "Open Now" : "Closed",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isOpenNow ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled, color: AppColors.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Working Hours",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(_clinic.workingHours,
                      style: const TextStyle(color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesContent() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Facilities & Services",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _clinic.services.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _clinic.services[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}