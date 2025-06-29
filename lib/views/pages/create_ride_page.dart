import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../controllers/ride_controller.dart';
import '../../theme/app_colors.dart';
import 'ride_tracking_page.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({Key? key}) : super(key: key);

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final RideController rideController = Get.put(RideController());
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'cash';
  DateTime? _scheduledFor;
  
  double? _pickupLat, _pickupLon;
  double? _destinationLat, _destinationLon;
  
  bool _isLoadingPickup = false;
  bool _isLoadingDestination = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAsPickup();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAsPickup() async {
    setState(() {
      _isLoadingPickup = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        
        setState(() {
          _pickupController.text = address;
          _pickupLat = position.latitude;
          _pickupLon = position.longitude;
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'obtenir votre position: $e');
    } finally {
      setState(() {
        _isLoadingPickup = false;
      });
    }
  }

  Future<void> _searchLocation(String query, bool isPickup) async {
    if (query.isEmpty) return;

    setState(() {
      if (isPickup) {
        _isLoadingPickup = true;
      } else {
        _isLoadingDestination = true;
      }
    });

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        setState(() {
          if (isPickup) {
            _pickupLat = location.latitude;
            _pickupLon = location.longitude;
          } else {
            _destinationLat = location.latitude;
            _destinationLon = location.longitude;
          }
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Adresse introuvable: $e');
    } finally {
      setState(() {
        if (isPickup) {
          _isLoadingPickup = false;
        } else {
          _isLoadingDestination = false;
        }
      });
    }
  }

  Future<void> _createRide() async {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir les adresses de départ et d\'arrivée');
      return;
    }

    if (_pickupLat == null || _pickupLon == null || 
        _destinationLat == null || _destinationLon == null) {
      Get.snackbar('Erreur', 'Veuillez valider les adresses en appuyant sur Entrée');
      return;
    }

    await rideController.createRide(
      pickupLat: _pickupLat!,
      pickupLon: _pickupLon!,
      pickupAddress: _pickupController.text,
      destinationLat: _destinationLat!,
      destinationLon: _destinationLon!,
      destinationAddress: _destinationController.text,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      scheduledFor: _scheduledFor,
    );

    if (rideController.currentRide.value != null) {
      Get.to(() => const RideTrackingPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Nouveau trajet', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adresses
            _buildLocationSection(),
            
            const SizedBox(height: 24),
            
            // Méthode de paiement
            _buildPaymentSection(),
            
            const SizedBox(height: 24),
            
            // Programmation
            _buildScheduleSection(),
            
            const SizedBox(height: 24),
            
            // Notes
            _buildNotesSection(),
            
            const SizedBox(height: 32),
            
            // Bouton de création
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: rideController.isLoading.value ? null : _createRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: rideController.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _scheduledFor != null ? 'Programmer le trajet' : 'Rechercher un chauffeur',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Où allez-vous ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Départ
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _pickupController,
                  decoration: InputDecoration(
                    hintText: 'Adresse de départ',
                    suffixIcon: _isLoadingPickup
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: _getCurrentLocationAsPickup,
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (value) => _searchLocation(value, true),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ligne de connexion
          Container(
            margin: const EdgeInsets.only(left: 6),
            width: 2,
            height: 20,
            color: Colors.grey[300],
          ),
          
          const SizedBox(height: 16),
          
          // Destination
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Où allez-vous ?',
                    suffixIcon: _isLoadingDestination
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (value) => _searchLocation(value, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Méthode de paiement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPaymentOption('cash', 'Espèces', Icons.money),
          _buildPaymentOption('card', 'Carte bancaire', Icons.credit_card),
          _buildPaymentOption('mobile', 'Mobile Money', Icons.phone_android),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (String? newValue) {
        setState(() {
          _selectedPaymentMethod = newValue!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Programmation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      
                      if (time != null) {
                        setState(() {
                          _scheduledFor = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(_scheduledFor != null 
                      ? 'Programmé pour ${_scheduledFor!.day}/${_scheduledFor!.month} à ${_scheduledFor!.hour}:${_scheduledFor!.minute.toString().padLeft(2, '0')}'
                      : 'Maintenant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              if (_scheduledFor != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _scheduledFor = null;
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes pour le chauffeur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Instructions spéciales, point de rendez-vous...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }
}