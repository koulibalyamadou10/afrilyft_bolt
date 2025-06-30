import 'package:supabase_flutter/supabase_flutter.dart';

// Script de test pour vérifier l'inscription
void main() async {
  // Initialiser Supabase
  await Supabase.initialize(
    url: 'https://fkqfebadrrgomfymziwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrcWZlYmFkcnJnb21meW16aXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMzY5MTgsImV4cCI6MjA2NjgxMjkxOH0.BuZCFCM0O3Y2OAQaaDEwwIenV03wBAlOAusn6qbTJsA',
  );

  final client = Supabase.instance.client;

  try {
    print('🧪 Test d\'inscription...');

    // Test d'inscription
    final response = await client.auth.signUp(
      email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'test123456',
      data: {
        'full_name': 'Test User',
        'phone': '+1234567890',
        'role': 'customer',
      },
    );

    print('✅ Réponse d\'inscription:');
    print('👤 Utilisateur: ${response.user?.id}');
    print('📧 Email: ${response.user?.email}');
    print('🔑 Session: ${response.session != null}');

    if (response.user != null) {
      // Attendre un peu
      await Future.delayed(const Duration(seconds: 2));

      // Vérifier le profil
      final profile =
          await client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single();

      print('✅ Profil trouvé:');
      print('👤 Nom: ${profile['full_name']}');
      print('📱 Téléphone: ${profile['phone']}');
      print('🎭 Rôle: ${profile['role']}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
