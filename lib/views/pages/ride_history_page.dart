import 'package:flutter/material.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({Key? key}) : super(key: key);

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  // Filtre de période sélectionné
  String _selectedPeriod = 'All Time';

  // Liste des filtres de période disponibles
  final List<String> _periodFilters = [
    'All Time',
    'This Week',
    'This Month',
    '3 Months',
  ];

  // Liste des trajets
  final List<RideHistory> _rides = [
    RideHistory(
      id: '1',
      date: '2023-11-25',
      time: '14:30',
      pickup: '123 Main St, Accra',
      destination: 'Accra Mall, Accra',
      distance: 3.2,
      duration: 15,
      paymentMethod: 'Cash',
      amount: 25.50,
      status: 'Completed',
      driverName: 'Kofi Mensah',
      driverRating: 4.8,
    ),
    RideHistory(
      id: '2',
      date: '2023-11-23',
      time: '09:15',
      pickup: 'Labadi Beach, Accra',
      destination: 'Kotoka International Airport, Accra',
      distance: 7.5,
      duration: 25,
      paymentMethod: 'Mobile Money',
      amount: 42.75,
      status: 'Completed',
      driverName: 'Ama Darko',
      driverRating: 4.9,
    ),
    RideHistory(
      id: '3',
      date: '2023-11-20',
      time: '18:45',
      pickup: 'University of Ghana, Legon',
      destination: 'Osu Oxford Street, Accra',
      distance: 8.3,
      duration: 30,
      paymentMethod: 'Visa',
      amount: 35.20,
      status: 'Completed',
      driverName: 'Kwame Asante',
      driverRating: 4.7,
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
          'Ride History',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filtres de période
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periodFilters.map((period) {
                  final isSelected = period == _selectedPeriod;
                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFFECEA),
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFFF6B5B) : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFFF6B5B) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Ligne de séparation
          Divider(color: Colors.grey[200], height: 1),
          
          // Liste des trajets
          Expanded(
            child: ListView.builder(
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final ride = _rides[index];
                return _buildRideCard(ride);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideHistory ride) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec date et prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.date,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${ride.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.status,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Itinéraire
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickup,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ride.destination,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Détails du trajet
            Row(
              children: [
                // Distance
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${ride.distance} km',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Durée
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${ride.duration} min',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Méthode de paiement
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      ride.paymentMethod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ligne de séparation
            Divider(color: Colors.grey[200]),
            
            // Informations sur le chauffeur et boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nom et note du chauffeur
                Row(
                  children: [
                    Text(
                      ride.driverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          ride.driverRating.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Boutons d'action
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Action pour voir le reçu
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B5B),
                        side: const BorderSide(color: Color(0xFFFF6B5B)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Action pour signaler un problème
                      },
                      icon: const Icon(Icons.flag, size: 16),
                      label: const Text('Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B5B),
                        side: const BorderSide(color: Color(0xFFFF6B5B)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RideHistory {
  final String id;
  final String date;
  final String time;
  final String pickup;
  final String destination;
  final double distance;
  final int duration;
  final String paymentMethod;
  final double amount;
  final String status;
  final String driverName;
  final double driverRating;

  RideHistory({
    required this.id,
    required this.date,
    required this.time,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.driverName,
    required this.driverRating,
  });
} 