import 'package:flutter/material.dart';

class PromoCodesPage extends StatefulWidget {
  const PromoCodesPage({Key? key}) : super(key: key);

  @override
  State<PromoCodesPage> createState() => _PromoCodesPageState();
}

class _PromoCodesPageState extends State<PromoCodesPage> {
  // Contrôleur pour le champ de saisie du code promo
  final TextEditingController _promoCodeController = TextEditingController();

  // Liste des codes promo disponibles
  final List<PromoCode> _availablePromoCodes = [
    PromoCode(
      code: 'WELCOME25',
      description: '25% off your first ride',
      discount: '25%',
      expires: 'Sep 30, 2023',
      isExpired: false,
      maxAmount: null,
      minFare: null,
      usesLeft: null,
    ),
    PromoCode(
      code: 'WEEKEND50',
      description: '50% off weekend rides (up to 25k GNF)',
      discount: '50%',
      expires: 'Aug 15, 2023',
      isExpired: false,
      maxAmount: '25k GNF',
      minFare: null,
      usesLeft: null,
    ),
    PromoCode(
      code: 'FRIEND20',
      description: '20% off your next 3 rides',
      discount: '20%',
      expires: 'Dec 31, 2023',
      isExpired: false,
      maxAmount: null,
      minFare: null,
      usesLeft: '3',
    ),
  ];

  // Liste des codes promo utilisés ou expirés
  final List<PromoCode> _usedExpiredPromoCodes = [
    PromoCode(
      code: 'SUMMER15',
      description: '15k GNF off rides over 50k GNF',
      discount: '15k GNF',
      expires: 'Jul 10, 2023',
      isExpired: true,
      maxAmount: null,
      minFare: '50k GNF',
      usesLeft: null,
    ),
    PromoCode(
      code: 'APRILYFFT10',
      description: '10% off your next ride',
      discount: '10%',
      expires: 'Apr 30, 2023',
      isExpired: true,
      maxAmount: null,
      minFare: null,
      usesLeft: null,
    ),
  ];

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

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
          'Promo Codes',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ de saisie du code promo
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action pour ajouter un code promo
                        if (_promoCodeController.text.isNotEmpty) {
                          // Logique pour vérifier et ajouter le code promo
                          _promoCodeController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24.0),
              
              // Section des codes promo disponibles
              const Text(
                'Available Promo Codes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12.0),
              
              // Liste des codes promo disponibles
              ..._availablePromoCodes.map((promo) => _buildPromoCard(promo, isAvailable: true)),
              
              const SizedBox(height: 24.0),
              
              // Section des codes promo utilisés ou expirés
              const Text(
                'Used & Expired Codes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12.0),
              
              // Liste des codes promo utilisés ou expirés
              ..._usedExpiredPromoCodes.map((promo) => _buildPromoCard(promo, isAvailable: false)),
              
              const SizedBox(height: 16.0),
              
              // Note sur les restrictions
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Promo codes are applied at checkout. Restrictions may apply.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(PromoCode promo, {required bool isAvailable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code promo et badge "Expired"
            Row(
              children: [
                Text(
                  promo.code,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isAvailable ? const Color(0xFFFF6B5B) : Colors.grey[400],
                  ),
                ),
                if (promo.isExpired) ...[
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 4.0),
            
            // Description du code promo
            Text(
              promo.description,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isAvailable ? Colors.black87 : Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12.0),
            
            // Détails du code promo
            Row(
              children: [
                // Remise
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        promo.discount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAvailable ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Montant maximum ou utilisations restantes
                if (promo.maxAmount != null || promo.usesLeft != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.maxAmount != null ? 'Max' : 'Uses Left',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          promo.maxAmount ?? promo.usesLeft ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAvailable ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Montant minimum ou date d'expiration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.minFare != null ? 'Min Fare' : 'Expires',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        promo.minFare ?? promo.expires,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAvailable ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton "Apply" (seulement pour les codes disponibles)
                if (isAvailable)
                  TextButton(
                    onPressed: () {
                      // Action pour appliquer le code promo
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFECEA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Color(0xFFFF6B5B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PromoCode {
  final String code;
  final String description;
  final String discount;
  final String expires;
  final bool isExpired;
  final String? maxAmount;
  final String? minFare;
  final String? usesLeft;

  PromoCode({
    required this.code,
    required this.description,
    required this.discount,
    required this.expires,
    required this.isExpired,
    this.maxAmount,
    this.minFare,
    this.usesLeft,
  });
} 