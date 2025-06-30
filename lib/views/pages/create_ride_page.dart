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
  
  List<String> _pickupSuggestions = [];
  List<String> _destinationSuggestions = [];
  
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

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
    if (_pickupController.text.length > 2) {
      _getAddressSuggestions(_pickupController.text, true);
    } else {
      setState(() {
        _pickupSuggestions = [];
      });
    }
  }

  void _onDestinationTextChanged() {
    if (_destinationController.text.length > 2) {
      _getAddressSuggestions(_destinationController.text, false);
    } else {
      setState(() {
        _destinationSuggestions = [];
      });
    }
  }

  Future<void> _getAddressSuggestions(String query, bool isPickup) async {
    if (query.isEmpty) return;
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock suggestions based on query
    List<String> suggestions = [];
    
    if (query.toLowerCase().contains('con')) {
      suggestions.add('Conakry, Guinea');
      suggestions.add('Conakry International Airport, Guinea');
      suggestions.add('Conakry Port, Guinea');
    }
    
    if (query.toLowerCase().contains('kin')) {
      suggestions.add('Kindia, Guinea');
      suggestions.add('Kindia Market, Guinea');
      suggestions.add('Kindia Central Station, Guinea');
    }
    
    if (query.toLowerCase().contains('mam')) {
      suggestions.add('Mamou, Guinea');
      suggestions.add('Mamou Central, Guinea');
    }
    
    if (query.toLowerCase().contains('lab')) {
      suggestions.add('Labé, Guinea');
      suggestions.add('Labé Market, Guinea');
    }
    
    if (query.toLowerCase().contains('kan')) {
      suggestions.add('Kankan, Guinea');
      suggestions.add('Kankan University, Guinea');
    }
    
    // Add generic suggestions if no specific matches
    if (suggestions.isEmpty && query.length > 2) {
      suggestions.add('$query Street, Guinea');
      suggestions.add('$query Market, Guinea');
      suggestions.add('$query District, Guinea');
    }
    
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
          _pickupSuggestions = [];
        } else {
          _isLoadingDestination = false;
          _destinationSuggestions = [];
        }
      });
    }
  }

  void _selectSuggestion(String suggestion, bool isPickup) {
    if (isPickup) {
      _pickupController.text = suggestion;
      _pickupSuggestions = [];
      _searchLocation(suggestion, true);
    } else {
      _destinationController.text = suggestion;
      _destinationSuggestions = [];
      _searchLocation(suggestion, false);
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
                            return ListTile(
                              dense: true,
                              title: Text(_pickupSuggestions[index]),
                              leading: const Icon(Icons.location_on, size: 18),
                              onTap: () => _selectSuggestion(_pickupSuggestions[index], true),
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
                            return ListTile(
                              dense: true,
                              title: Text(_destinationSuggestions[index]),
                              leading: const Icon(Icons.location_on, size: 18),
                              onTap: () => _selectSuggestion(_destinationSuggestions[index], false),
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