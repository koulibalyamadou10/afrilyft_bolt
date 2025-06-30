import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../controllers/ride_controller.dart';
import '../../theme/app_colors.dart';
import 'map_preview_page.dart';

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
  
  List<Map<String, String>> _pickupSuggestions = [];
  List<Map<String, String>> _destinationSuggestions = [];
  
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  // Liste des villes et lieux populaires en Guinée avec coordonnées
  final List<Map<String, dynamic>> _popularPlaces = [
    {
      'name': 'Conakry, Guinée',
      'address': 'Conakry, Guinée',
      'lat': 9.6412,
      'lon': -13.5784
    },
    {
      'name': 'Aéroport International de Conakry',
      'address': 'Aéroport International de Conakry, Guinée',
      'lat': 9.5764,
      'lon': -13.6121
    },
    {
      'name': 'Port de Conakry',
      'address': 'Port de Conakry, Guinée',
      'lat': 9.5142,
      'lon': -13.7128
    },
    {
      'name': 'Kindia, Guinée',
      'address': 'Kindia, Guinée',
      'lat': 10.0569,
      'lon': -12.8658
    },
    {
      'name': 'Marché de Kindia',
      'address': 'Marché de Kindia, Guinée',
      'lat': 10.0532,
      'lon': -12.8611
    },
    {
      'name': 'Mamou, Guinée',
      'address': 'Mamou, Guinée',
      'lat': 10.3755,
      'lon': -12.0915
    },
    {
      'name': 'Labé, Guinée',
      'address': 'Labé, Guinée',
      'lat': 11.3182,
      'lon': -12.2833
    },
    {
      'name': 'Kankan, Guinée',
      'address': 'Kankan, Guinée',
      'lat': 10.3854,
      'lon': -9.3057
    },
    {
      'name': 'Université de Conakry',
      'address': 'Université de Conakry, Guinée',
      'lat': 9.5359,
      'lon': -13.6801
    },
    {
      'name': 'Hôpital Donka',
      'address': 'Hôpital Donka, Conakry, Guinée',
      'lat': 9.5512,
      'lon': -13.6765
    },
    {
      'name': 'Stade du 28 Septembre',
      'address': 'Stade du 28 Septembre, Conakry, Guinée',
      'lat': 9.5387,
      'lon': -13.6765
    },
    {
      'name': 'Kaloum Centre',
      'address': 'Kaloum, Conakry, Guinée',
      'lat': 9.5092,
      'lon': -13.7122
    },
    {
      'name': 'Marché Madina',
      'address': 'Marché Madina, Conakry, Guinée',
      'lat': 9.5452,
      'lon': -13.6765
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAsPickup();
    
    // Add listeners to text controllers for suggestions
    _pickupController.addListener(_onPickupTextChanged);
    _destinationController.addListener(_onDestinationTextChanged);
    
    // Add listeners to focus nodes
    _pickupFocusNode.addListener(() {
      if (!_pickupFocusNode.hasFocus) {
        setState(() {
          _pickupSuggestions = [];
        });
      }
    });
    
    _destinationFocusNode.addListener(() {
      if (!_destinationFocusNode.hasFocus) {
        setState(() {
          _destinationSuggestions = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _pickupController.removeListener(_onPickupTextChanged);
    _destinationController.removeListener(_onDestinationTextChanged);
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  void _onPickupTextChanged() {
    if (_pickupController.text.length > 1) {
      _getAddressSuggestions(_pickupController.text, true);
    } else {
      setState(() {
        _pickupSuggestions = [];
      });
    }
  }

  void _onDestinationTextChanged() {
    if (_destinationController.text.length > 1) {
      _getAddressSuggestions(_destinationController.text, false);
    } else {
      setState(() {
        _destinationSuggestions = [];
      });
    }
  }

  void _getAddressSuggestions(String query, bool isPickup) {
    if (query.isEmpty) return;
    
    // Filtrer les lieux populaires en fonction de la requête
    final List<Map<String, dynamic>> filteredPlaces = _popularPlaces
        .where((place) => 
            place['name'].toLowerCase().contains(query.toLowerCase()) ||
            place['address'].toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    // Convertir en format de suggestion
    final suggestions = filteredPlaces.map((place) => {
      'name': place['name'],
      'address': place['address'],
      'lat': place['lat'].toString(),
      'lon': place['lon'].toString(),
    }).toList();
    
    setState(() {
      if (isPickup) {
        _pickupSuggestions = suggestions;
      } else {
        _destinationSuggestions = suggestions;
      }
    });
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

  void _selectSuggestion(Map<String, String> suggestion, bool isPickup) {
    if (isPickup) {
      _pickupController.text = suggestion['address'] ?? suggestion['name'] ?? '';
      _pickupLat = double.tryParse(suggestion['lat'] ?? '');
      _pickupLon = double.tryParse(suggestion['lon'] ?? '');
      _pickupSuggestions = [];
    } else {
      _destinationController.text = suggestion['address'] ?? suggestion['name'] ?? '';
      _destinationLat = double.tryParse(suggestion['lat'] ?? '');
      _destinationLon = double.tryParse(suggestion['lon'] ?? '');
      _destinationSuggestions = [];
    }
    setState(() {});
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
      // D'abord, chercher dans nos lieux populaires
      final matchingPlace = _popularPlaces.firstWhereOrNull(
        (place) => place['name'].toLowerCase() == query.toLowerCase() || 
                  place['address'].toLowerCase() == query.toLowerCase()
      );
      
      if (matchingPlace != null) {
        setState(() {
          if (isPickup) {
            _pickupLat = matchingPlace['lat'];
            _pickupLon = matchingPlace['lon'];
          } else {
            _destinationLat = matchingPlace['lat'];
            _destinationLon = matchingPlace['lon'];
          }
        });
        return;
      }
      
      // Si pas trouvé dans nos lieux populaires, utiliser geocoding
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
      // Si geocoding échoue, utiliser des coordonnées par défaut pour Conakry
      if (query.toLowerCase().contains('conakry')) {
        setState(() {
          if (isPickup) {
            _pickupLat = 9.6412;
            _pickupLon = -13.5784;
          } else {
            _destinationLat = 9.6412;
            _destinationLon = -13.5784;
          }
        });
      } else {
        Get.snackbar('Adresse approximative', 'Coordonnées exactes non trouvées, veuillez préciser');
      }
    } finally {
      setState(() {
        if (isPickup) {
          _isLoadingPickup = false;
          _pickupSuggestions = [];
        } else {
          _isLoadingDestination = false;
          _destinationSuggestions = [];
        }
      });
    }
  }

  void _proceedToMapPreview() {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir les adresses de départ et d\'arrivée');
      return;
    }

    if (_pickupLat == null || _pickupLon == null || 
        _destinationLat == null || _destinationLon == null) {
      // Try to search for locations if coordinates are not set
      _searchLocation(_pickupController.text, true).then((_) {
        _searchLocation(_destinationController.text, false).then((_) {
          if (_pickupLat != null && _pickupLon != null && 
              _destinationLat != null && _destinationLon != null) {
            _navigateToMapPreview();
          } else {
            Get.snackbar('Erreur', 'Impossible de trouver les coordonnées des adresses');
          }
        });
      });
    } else {
      _navigateToMapPreview();
    }
  }

  void _navigateToMapPreview() {
    Get.to(() => MapPreviewPage(
      pickupLat: _pickupLat!,
      pickupLon: _pickupLon!,
      pickupAddress: _pickupController.text,
      destinationLat: _destinationLat!,
      destinationLon: _destinationLon!,
      destinationAddress: _destinationController.text,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      scheduledFor: _scheduledFor,
    ));
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
            
            // Bouton pour voir la carte
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _proceedToMapPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir sur la carte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _pickupController,
                      focusNode: _pickupFocusNode,
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
                    if (_pickupSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pickupSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _pickupSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(suggestion['name'] ?? ''),
                              subtitle: Text(suggestion['address'] ?? '', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              leading: const Icon(Icons.location_on, size: 18),
                              onTap: () => _selectSuggestion(suggestion, true),
                            );
                          },
                        ),
                      ),
                  ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _destinationController,
                      focusNode: _destinationFocusNode,
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
                    if (_destinationSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _destinationSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _destinationSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(suggestion['name'] ?? ''),
                              subtitle: Text(suggestion['address'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              leading: const Icon(Icons.location_on, size: 18),
                              onTap: () => _selectSuggestion(suggestion, false),
                            );
                          },
                        ),
                      ),
                  ],
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