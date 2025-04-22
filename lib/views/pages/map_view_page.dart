import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';

class MapViewPage extends StatefulWidget {
  final String? fromLocation;
  final String? toLocation;
  
  const MapViewPage({
    Key? key,
    this.fromLocation,
    this.toLocation,
  }) : super(key: key);

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  // État pour suivre si une route est sélectionnée
  bool _routeSelected = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs avec les valeurs passées
    if (widget.fromLocation != null) {
      _fromController.text = widget.fromLocation!;
    }
    
    if (widget.toLocation != null) {
      _toController.text = widget.toLocation!;
    }
    
    // Si les deux emplacements sont définis, considérer qu'une route est sélectionnée
    if (widget.fromLocation != null && widget.toLocation != null) {
      _routeSelected = true;
    }
  }
  
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte (simulée avec une image ou une couleur de fond)
          Container(
            color: Colors.grey[300], // Couleur de fond pour simuler la carte
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Text(
                'Map View',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Marqueurs des chauffeurs (simulés)
          Positioned(
            top: 200,
            left: 100,
            child: _buildDriverMarker(),
          ),
          Positioned(
            top: 300,
            left: 150,
            child: _buildDriverMarker(),
          ),
          Positioned(
            top: 250,
            right: 120,
            child: _buildDriverMarker(),
          ),
          
          // Marqueur de position actuelle (simulé)
          Positioned(
            bottom: 300,
            right: 180,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          
          // En-tête avec barre de recherche
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Barre de navigation
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                          widget.toLocation != null 
                              ? 'Conakry International Airport → Kaloum Center'
                              : 'Ride',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: Colors.white),
                        onPressed: () {
                          // Échanger les emplacements de départ et d'arrivée
                          final temp = _fromController.text;
                          _fromController.text = _toController.text;
                          _toController.text = temp;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Champ de recherche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        hintText: 'Search for a destination in Guinea...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Panneau d'informations sur le trajet (affiché lorsqu'une route est sélectionnée)
          if (_routeSelected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations sur le trajet
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Conakry to Kindia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '135 km • 2h 15min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Action pour sélectionner cet itinéraire
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B5B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text(
                            'Select this route',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFFFF6B5B)),
                            onPressed: () {
                              // Action pour centrer la carte sur la position actuelle
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Ligne de séparation
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Options de trajet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRideOption(
                          icon: Icons.directions_car,
                          label: 'Standard',
                          price: '€25.50',
                          isSelected: true,
                        ),
                        _buildRideOption(
                          icon: Icons.star,
                          label: 'Premium',
                          price: '€35.75',
                          isSelected: false,
                        ),
                        _buildRideOption(
                          icon: Icons.people,
                          label: 'Shared',
                          price: '€15.25',
                          isSelected: false,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton de confirmation
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Action pour confirmer le trajet
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm Ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Méthode pour construire un marqueur de chauffeur
  Widget _buildDriverMarker() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B5B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car,
        color: Colors.white,
        size: 20,
      ),
    );
  }
  
  // Méthode pour construire une option de trajet
  Widget _buildRideOption({
    required IconData icon,
    required String label,
    required String price,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFECEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6B5B) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF6B5B) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              color: isSelected ? const Color(0xFFFF6B5B) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFFFF6B5B) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
} 