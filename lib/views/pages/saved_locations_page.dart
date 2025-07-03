import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({Key? key}) : super(key: key);

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  // Liste des emplacements enregistrés
  final List<SavedLocation> _savedLocations = [
    SavedLocation(
      id: '1',
      name: 'Home',
      address: '123 Independence Ave, Accra',
      latitude: 5.6037,
      longitude: -0.1869,
      icon: Icons.home,
      iconColor: Colors.red,
      dateAjout: DateTime.now(),
    ),
    SavedLocation(
      id: '2',
      name: 'Work',
      address: 'Accra Tech Hub, Ring Road',
      latitude: 5.6037,
      longitude: -0.1869,
      icon: Icons.work,
      iconColor: Colors.black,
      dateAjout: DateTime.now(),
    ),
    SavedLocation(
      id: '3',
      name: 'Gym',
      address: 'Gold\'s Gym, Osu Oxford Street',
      latitude: 5.6037,
      longitude: -0.1869,
      icon: Icons.fitness_center,
      iconColor: Colors.blue,
      dateAjout: DateTime.now(),
    ),
    SavedLocation(
      id: '4',
      name: 'Mom\'s Place',
      address: '45 Cantonments Road, Accra',
      latitude: 5.6037,
      longitude: -0.1869,
      icon: Icons.favorite,
      iconColor: Colors.blue,
      dateAjout: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Locations',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search saved locations',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Liste des emplacements enregistrés
          Expanded(
            child: ListView.builder(
              itemCount: _savedLocations.length,
              itemBuilder: (context, index) {
                final location = _savedLocations[index];
                return _buildLocationCard(location);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddLocationDialog,
        backgroundColor: const Color(0xFFFF6B5B),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLocationCard(SavedLocation location) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: location.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(location.icon, color: location.iconColor, size: 24),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          location.address,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                // Action pour modifier l'emplacement
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () {
                // Action pour supprimer l'emplacement
                _showDeleteConfirmation(location);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(SavedLocation location) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Location'),
            content: Text(
              'Are you sure you want to delete "${location.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _savedLocations.remove(location);
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _openAddLocationDialog() async {
    final newLocation = await showDialog<SavedLocation>(
      context: context,
      builder: (context) => AddLocationDialog(),
    );
    if (newLocation != null) {
      setState(() {
        _savedLocations.add(newLocation);
      });
    }
  }
}

class SavedLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color iconColor;
  final DateTime dateAjout;
  final String? description;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.iconColor,
    required this.dateAjout,
    this.description,
  });
}

// Formulaire d'ajout de lieu
class AddLocationDialog extends StatefulWidget {
  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _description;
  String? _address;
  double? _latitude;
  double? _longitude;
  IconData _icon = Icons.place;
  Color _iconColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un lieu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom du lieu'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                onSaved: (v) => _name = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Icône :'),
                  IconButton(
                    icon: Icon(_icon, color: _iconColor),
                    onPressed: () {}, // TODO: Sélecteur d'icône
                  ),
                  // TODO: Sélecteur de couleur
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(
                  _address == null
                      ? 'Choisir sur la carte'
                      : 'Modifier sur la carte',
                ),
                onPressed: () async {
                  final result = await Navigator.push<MapPickerResult>(
                    context,
                    MaterialPageRoute(builder: (context) => MapPickerPage()),
                  );
                  if (result != null) {
                    setState(() {
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                      _address = result.address;
                    });
                  }
                },
              ),
              if (_address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Adresse : $_address'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _latitude != null &&
                _longitude != null &&
                _address != null) {
              _formKey.currentState!.save();
              Navigator.pop(
                context,
                SavedLocation(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _name!,
                  address: _address!,
                  latitude: _latitude!,
                  longitude: _longitude!,
                  icon: _icon,
                  iconColor: _iconColor,
                  dateAjout: DateTime.now(),
                  description: _description,
                ),
              );
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

// Résultat du picker sur carte
class MapPickerResult {
  final double latitude;
  final double longitude;
  final String address;
  MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

// Page de sélection sur la carte
class MapPickerPage extends StatefulWidget {
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _pickedLatLng;
  String? _pickedAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sélectionner sur la carte')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(5.6037, -0.1870), // Par défaut Accra
          zoom: 12,
        ),
        onTap: (latLng) async {
          setState(() {
            _pickedLatLng = latLng;
          });
          // Reverse geocoding ici (à compléter)
        },
        markers:
            _pickedLatLng != null
                ? {
                  Marker(
                    markerId: const MarkerId('picked'),
                    position: _pickedLatLng!,
                  ),
                }
                : {},
        onMapCreated: (controller) => _mapController = controller,
      ),
      floatingActionButton:
          _pickedLatLng != null
              ? FloatingActionButton.extended(
                onPressed: () async {
                  // TODO: Reverse geocoding pour obtenir l'adresse
                  String address = 'Adresse à compléter';
                  Navigator.pop(
                    context,
                    MapPickerResult(
                      latitude: _pickedLatLng!.latitude,
                      longitude: _pickedLatLng!.longitude,
                      address: address,
                    ),
                  );
                },
                label: const Text('Valider'),
                icon: const Icon(Icons.check),
              )
              : null,
    );
  }
}
