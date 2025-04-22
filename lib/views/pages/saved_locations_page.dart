import 'package:flutter/material.dart';

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
      icon: Icons.home,
      iconColor: Colors.red,
    ),
    SavedLocation(
      id: '2',
      name: 'Work',
      address: 'Accra Tech Hub, Ring Road',
      icon: Icons.work,
      iconColor: Colors.black,
    ),
    SavedLocation(
      id: '3',
      name: 'Gym',
      address: 'Gold\'s Gym, Osu Oxford Street',
      icon: Icons.fitness_center,
      iconColor: Colors.blue,
    ),
    SavedLocation(
      id: '4',
      name: 'Mom\'s Place',
      address: '45 Cantonments Road, Accra',
      icon: Icons.favorite,
      iconColor: Colors.blue,
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
        onPressed: () {
          // Action pour ajouter un nouvel emplacement
        },
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: location.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            location.icon,
            color: location.iconColor,
            size: 24,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          location.address,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
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
}

class SavedLocation {
  final String id;
  final String name;
  final String address;
  final IconData icon;
  final Color iconColor;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.icon,
    required this.iconColor,
  });
} 