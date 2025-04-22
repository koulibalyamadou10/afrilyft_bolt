import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CarpoolPage extends StatelessWidget {
  const CarpoolPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text('Carpool', style: TextStyle(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre principal
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Text(
                'Carpool across Guinea at affordable prices',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Formulaire de recherche
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Champ de départ
                  _buildInputField(
                    icon: Icons.location_on_outlined,
                    hintText: 'Conakry',
                    isLocation: true,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Champ de destination
                  _buildInputField(
                    icon: Icons.location_on_outlined,
                    hintText: 'Kindia',
                    isLocation: true,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Champ de date
                  _buildInputField(
                    icon: Icons.calendar_today_outlined,
                    hintText: 'mm/dd/yyyy',
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Champ de passagers
                  _buildInputField(
                    icon: Icons.people_outline,
                    hintText: '1 passenger',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bouton de recherche
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Section des itinéraires populaires
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Text(
                'Popular routes in Guinea',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Liste des itinéraires populaires
            _buildRouteItem('Conakry', 'Kindia'),
            _buildRouteItem('Conakry', 'Mamou'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    bool isLocation = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: 22,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              hintText,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
          ),
          if (isLocation)
            Icon(
              Icons.my_location,
              color: Colors.grey.shade600,
              size: 20,
            ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }
  
  Widget _buildRouteItem(String from, String to) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Row(
          children: [
            Text(
              from,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              color: Colors.black54,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              to,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
        ),
        onTap: () {},
      ),
    );
  }
} 