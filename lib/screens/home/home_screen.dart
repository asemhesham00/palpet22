import 'package:flutter/material.dart';
import 'package:palpet/core/constants/app_colors.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/services/database_service.dart';
import 'package:palpet/screens/home/widgets/pet_card.dart'; 
import 'package:palpet/screens/home/widgets/home_banner.dart'; 
import 'package:palpet/screens/home/widgets/service_card.dart';  
import '../adoption/pet_details_screen.dart'; 

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        const HomeBanner(),
        const Center(
          child: Text(
            "Our Services",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Comprehensive pet care services designed to\nkeep your furry friends happy and healthy",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        GridView.count(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          crossAxisCount: 2, 
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, 
          children: [
            ServiceCard(
              title: "Adoption",
              subtitle: "Browse pets looking for a forever home",
              icon: Icons.pets,
              backgroundColor: AppColors.serviceAdoptionBg,
              onTap: () => onNavigate(3),
            ),
            ServiceCard(
              title: "Lost & Found",
              subtitle: "Report lost pets or help reunite found animals",
              icon: Icons.search,
              backgroundColor: AppColors.serviceLostBg,
              onTap: () => onNavigate(4),
            ),
            ServiceCard(
              title: "Vet Clinics",
              subtitle: "Find veterinary clinics near you",
              icon: Icons.local_hospital,
              backgroundColor: AppColors.serviceVetBg,
              onTap: () => onNavigate(6),
            ),
            ServiceCard(
              title: "Pet Hotels",
              subtitle: "Safe and comfortable accommodations",
              icon: Icons.house, 
              backgroundColor: AppColors.serviceHotelBg,
              onTap: () => onNavigate(5),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(color: Colors.black12, thickness: 1), 
        const SizedBox(height: 32),
        const Center(
          child: Text(
            "Meet Our Featured Pets",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "These adorable pets are looking for their\nforever homes",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),


        StreamBuilder<List<Pet>>(
          stream: DatabaseService().getPets(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No pets available yet."),
                ),
              );
            }

            final allPets = snapshot.data!;
            final adoptionPets = allPets.where((pet) {
              return pet.postType.toLowerCase() == 'adoption';
            }).toList();
            final featuredPets = adoptionPets.take(3).toList();

            if (featuredPets.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No featured pets at the moment."),
                ),
              );
            }

            return Column(
              children: featuredPets.map((pet) => PetCard(
                ownerId: pet.ownerId, 
                name: pet.name,
                breed: pet.breed,
                age: pet.age,
                gender: pet.gender, 
                description: pet.description, 
                imageUrl: pet.imageUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailsScreen(pet: pet),
                    ),
                  );
                },
              )).toList(),
            );
          },
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
}