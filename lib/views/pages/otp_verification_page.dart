import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../home_view.dart';
import 'reset_password_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final bool isRegistration;
  final bool isPasswordReset;
  
  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.isRegistration,
    this.isPasswordReset = false,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  // Contrôleurs pour les champs OTP
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  
  // Liste des focus nodes pour les champs OTP
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  // Minuteur pour le compte à rebours
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  @override
  void dispose() {
    // Libérer les ressources
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }
  
  // Démarrer le minuteur pour le compte à rebours
  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }
  
  // Formater le temps restant
  String get _timeRemaining {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Vérifier le code OTP
  void _verifyOtp() {
    // Récupérer le code OTP complet
    final otp = _otpControllers.map((controller) => controller.text).join();
    
    // Vérifier que le code est complet
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Rediriger en fonction du contexte
    if (widget.isPasswordReset) {
      // Naviguer vers la page de réinitialisation de mot de passe
      Get.to(() => ResetPasswordPage(phoneNumber: widget.phoneNumber));
    } else {
      // Naviguer vers la page d'accueil
      Get.offAll(() => const HomeView());
    }
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
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'OTP Verification',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Icône et titre
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEA),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.sms,
                size: 40,
                color: Color(0xFFFF6B5B),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'We have sent the verification code to\n${widget.phoneNumber}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Champs de saisie OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => SizedBox(
                  width: 60,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        // Passer au champ suivant
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Bouton de vérification
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B5B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Compte à rebours et option de renvoi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Didn\'t receive the code? ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                _canResend
                    ? TextButton(
                        onPressed: () {
                          // Simuler l'envoi d'un nouveau code
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New verification code sent'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _startTimer();
                        },
                        child: const Text(
                          'Resend',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFF6B5B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Text(
                        _timeRemaining,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF6B5B),
                          fontWeight: FontWeight.w500,
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