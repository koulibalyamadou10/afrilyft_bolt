import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ReserveRidePage extends StatefulWidget {
  const ReserveRidePage({Key? key}) : super(key: key);

  @override
  State<ReserveRidePage> createState() => _ReserveRidePageState();
}

class _ReserveRidePageState extends State<ReserveRidePage> {
  String selectedVehicleType = 'Standard';
  String selectedPaymentMethod = 'Cash (GNF)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reserve a ride in Guinea',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Colors.grey),
                
                // Trip Details Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
                  child: Text(
                    'Trip Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Route visualization
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 60,
                            color: Colors.grey,
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: [
                            _buildLocationField('Pickup Location'),
                            const SizedBox(height: 10),
                            _buildLocationField('Destination'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Date and Time
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          icon: Icons.calendar_today,
                          text: '2025-04-21',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateTimeField(
                          icon: Icons.access_time,
                          text: '6:12 PM',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 40, color: Colors.grey),
                
                // Vehicle Type Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
                  child: Text(
                    'Vehicle Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Vehicle options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildVehicleOption(
                          type: 'Standard',
                          icon: Icons.directions_car,
                          price: 'F15,000',
                          capacity: '1-4',
                          time: '5 min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildVehicleOption(
                          type: 'Comfort',
                          icon: Icons.directions_car,
                          price: 'F25,000',
                          capacity: '1-4',
                          time: '7 min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildVehicleOption(
                          type: 'XL',
                          icon: Icons.airport_shuttle,
                          price: 'F35,000',
                          capacity: '1-6',
                          time: '10 min',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 40, color: Colors.grey),
                
                // Payment Method Section
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Payment options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentOption(
                              method: 'Cash (GNF)',
                              icon: Icons.money,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPaymentOption(
                              method: 'Orange Money',
                              icon: Icons.phone_android,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentOption(
                        method: 'MTN Mobile Money',
                        icon: Icons.phone_android,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 40, color: Colors.grey),
                
                // Popular locations section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Popular locations in Guinea',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Afficher une confirmation de réservation
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppColors.secondary,
                                title: const Text(
                                  'Réservation confirmée',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Votre trajet a été réservé avec succès. Vous recevrez une confirmation par SMS.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      // Retourner à la page d'accueil
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    },
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(color: Color(0xFFFF6B5B)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Reserve Ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                   
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationField(String hintText) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      margin: const EdgeInsets.only(right: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            hintText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateTimeField({required IconData icon, required String text}) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVehicleOption({
    required String type,
    required IconData icon,
    required String price,
    required String capacity,
    required String time,
  }) {
    final bool isSelected = selectedVehicleType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicleType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFFF6B5B), width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF6B5B),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFFF6B5B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, color: Colors.grey[400], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      capacity,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[400], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
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
  
  Widget _buildPaymentOption({
    required String method,
    required IconData icon,
    bool fullWidth = false,
  }) {
    final bool isSelected = selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
      },
      child: Container(
        height: 55,
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFFF6B5B), width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 