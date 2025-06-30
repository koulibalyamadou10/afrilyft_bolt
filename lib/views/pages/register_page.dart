import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      Get.snackbar(
        'Erreur',
        'Veuillez accepter les conditions d\'utilisation',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      print('📝 Début de l\'inscription depuis la page');

      final success = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success) {
        print('✅ Inscription réussie, navigation vers la page d\'accueil');
        // Ne pas naviguer vers LoginPage, laisser AuthController gérer la navigation
        // Get.offAll(() => const LoginPage());
      } else {
        print('❌ Échec de l\'inscription');
        // Rester sur la page d'inscription pour permettre à l'utilisateur de corriger
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bouton de retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    onPressed: () => Get.back(),
                  ),

                  const SizedBox(height: 20),

                  // Titre et sous-titre
                  const Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remplissez le formulaire pour continuer',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 32),

                  // Nom complet
                  const Text(
                    'Nom complet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom complet';
                      }
                      if (value.length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Entrez votre nom complet',
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Numéro de téléphone
                  const Text(
                    'Numéro de téléphone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      // Validation plus stricte pour le numéro de téléphone
                      final phoneRegex = RegExp(
                        r'^(\+?[0-9]{1,4}[\s-]?)?[0-9]{8,15}$',
                      );
                      if (!phoneRegex.hasMatch(value.trim())) {
                        return 'Format de numéro de téléphone invalide';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Entrez votre numéro de téléphone',
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Entrez votre adresse email',
                      prefixIcon: const Icon(Icons.email, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mot de passe
                  const Text(
                    'Mot de passe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      // Validation plus stricte pour le mot de passe
                      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                        return 'Le mot de passe doit contenir au moins une lettre et un chiffre';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Créez un mot de passe',
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Conditions d'utilisation
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFFF6B5B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'J\'accepte les ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: 'Conditions d\'utilisation',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B5B),
                                  fontWeight: FontWeight.w500,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        // Navigation vers les conditions d'utilisation
                                      },
                              ),
                              const TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'Politique de confidentialité',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B5B),
                                  fontWeight: FontWeight.w500,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        // Navigation vers la politique de confidentialité
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bouton d'inscription
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            authController.isLoading.value
                                ? null
                                : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child:
                            authController.isLoading.value
                                ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : const Text(
                                  'S\'inscrire',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lien vers la page de connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte ?',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() => const LoginPage());
                        },
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 14,
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
          ),
        ),
      ),
    );
  }
}
