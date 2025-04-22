class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

List<OnboardingModel> onboardingPages = [
  OnboardingModel(
    title: "Voyagez en toute sécurité",
    description: "Profitez de trajets sûrs et fiables avec des chauffeurs vérifiés dans toute l'Afrique.",
    imagePath: "assets/images/onboarding1.png",
  ),
  OnboardingModel(
    title: "Réservez à l'avance",
    description: "Planifiez vos déplacements en réservant votre trajet à l'heure qui vous convient.",
      imagePath: "assets/images/onboarding2.png",
  ),
  OnboardingModel(
    title: "Voyages longue distance",
    description: "Explorez de nouvelles villes avec nos options de trajets longue distance abordables.",
    imagePath: "assets/images/onboarding3.png",
  ),
]; 