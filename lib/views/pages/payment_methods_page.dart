import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  // État des interrupteurs pour chaque méthode de paiement
  Map<String, bool> paymentSwitches = {
    'Visa': true,
    'Orange Money': true,
    'Mastercard': true,
    'Cash': true,
    'MTN Mobile Money': false,
  };

  // Méthode de paiement principale
  String primaryMethod = 'Visa';

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
          'Payment Methods',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Action pour le bouton Edit
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFFFF6B5B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section des méthodes de paiement actives
              _buildSectionTitle('Active Payment Methods'),
              
              _buildPaymentCard(
                icon: Icons.credit_card,
                title: 'Visa',
                subtitle: '**** **** **** 4523',
                additionalInfo: 'Expires 09/26',
                isActive: true,
                isPrimary: primaryMethod == 'Visa',
              ),
              
              _buildPaymentCard(
                icon: Icons.phone_android,
                title: 'Orange Money',
                subtitle: '+224 621 234 567',
                isActive: true,
                isPrimary: primaryMethod == 'Orange Money',
              ),
              
              _buildPaymentCard(
                icon: Icons.credit_card,
                title: 'Mastercard',
                subtitle: '**** **** **** 8761',
                additionalInfo: 'Expires 03/25',
                isActive: true,
                isPrimary: primaryMethod == 'Mastercard',
              ),
              
              _buildPaymentCard(
                icon: Icons.money,
                title: 'Cash',
                subtitle: 'Pay with cash',
                isActive: true,
                isPrimary: primaryMethod == 'Cash',
              ),
              
              const SizedBox(height: 20),
              
              // Section des méthodes de paiement désactivées
              _buildSectionTitle('Disabled Payment Methods'),
              
              _buildPaymentCard(
                icon: Icons.phone_android,
                title: 'MTN Mobile Money',
                subtitle: '+224 661 987 654',
                isActive: false,
                isPrimary: false,
              ),
              
              const SizedBox(height: 30),
              
              // Bouton pour ajouter une méthode de paiement
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Action pour ajouter une méthode de paiement
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B5B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? additionalInfo,
    required bool isActive,
    required bool isPrimary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            // Icône
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF6B5B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF6B5B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (additionalInfo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      additionalInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Interrupteur ou bouton "Set as Primary"
            isActive
                ? Switch(
                    value: paymentSwitches[title] ?? false,
                    onChanged: (value) {
                      setState(() {
                        paymentSwitches[title] = value;
                      });
                    },
                    activeColor: const Color(0xFFFF6B5B),
                  )
                : Switch(
                    value: false,
                    onChanged: null,
                    activeColor: Colors.grey,
                  ),
            
            // Bouton "Set as Primary" (seulement pour les méthodes actives qui ne sont pas déjà primaires)
            if (isActive && !isPrimary)
              TextButton(
                onPressed: () {
                  setState(() {
                    primaryMethod = title;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFFF6B5B)),
                  ),
                ),
                child: const Text(
                  'Set as Primary',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6B5B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 