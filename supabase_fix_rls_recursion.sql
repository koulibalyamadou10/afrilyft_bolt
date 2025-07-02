-- SOLUTION COMPLÈTE : Corriger la récursion infinie dans les politiques RLS
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- 1. Désactiver temporairement RLS sur toutes les tables
ALTER TABLE rides DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques existantes qui causent des problèmes
-- Politiques sur rides
DROP POLICY IF EXISTS "Customers can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned or requested rides" ON rides;
DROP POLICY IF EXISTS "Drivers can update assigned rides" ON rides;
DROP POLICY IF EXISTS "Users can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned rides" ON rides;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON rides;

-- Politiques sur ride_requests
DROP POLICY IF EXISTS "Customers can read ride requests for their rides" ON ride_requests;
DROP POLICY IF EXISTS "Drivers can manage own ride requests" ON ride_requests;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON ride_requests;

-- Politiques sur profiles
DROP POLICY IF EXISTS "Users can read other profiles for rides" ON profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Politiques sur driver_locations
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read available driver locations" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read driver locations" ON driver_locations;

-- 3. Créer de nouvelles politiques NON récursives

-- POLITIQUES POUR PROFILES
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Permettre aux chauffeurs d'être visibles par tous les utilisateurs authentifiés
CREATE POLICY "Users can read driver profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (role = 'driver');

-- POLITIQUES POUR RIDES (NON RÉCURSIVES)
-- Clients peuvent gérer leurs propres trajets
CREATE POLICY "Customers can manage own rides"
  ON rides FOR ALL
  TO authenticated
  USING (customer_id = auth.uid());

-- Chauffeurs peuvent voir les trajets qui leur sont assignés
CREATE POLICY "Drivers can read assigned rides"
  ON rides FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid());

-- Chauffeurs peuvent mettre à jour les trajets qui leur sont assignés
CREATE POLICY "Drivers can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

-- Chauffeurs peuvent voir les trajets en recherche (pour accepter)
CREATE POLICY "Drivers can read searching rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    status = 'searching' 
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'driver'
    )
  );

-- POLITIQUES POUR RIDE_REQUESTS (NON RÉCURSIVES)
-- Chauffeurs peuvent gérer leurs propres demandes
CREATE POLICY "Drivers can manage own ride requests"
  ON ride_requests FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

-- Clients peuvent voir les demandes pour leurs trajets (sans récursion)
CREATE POLICY "Customers can read ride requests for their rides"
  ON ride_requests FOR SELECT
  TO authenticated
  USING (
    ride_id IN (
      SELECT id FROM rides WHERE customer_id = auth.uid()
    )
  );

-- POLITIQUES POUR DRIVER_LOCATIONS
-- Chauffeurs peuvent gérer leur propre position
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

-- Clients peuvent voir les positions des chauffeurs disponibles
CREATE POLICY "Customers can read available driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    is_available = true
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'customer'
    )
  );

-- POLITIQUES POUR NOTIFICATIONS
-- Utilisateurs peuvent gérer leurs propres notifications
CREATE POLICY "Users can manage own notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- 4. Réactiver RLS sur toutes les tables
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 5. Vérifier que les politiques sont bien créées
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('rides', 'profiles', 'ride_requests', 'driver_locations', 'notifications')
ORDER BY tablename, policyname;

-- 6. Test de création d'un trajet (optionnel - à exécuter manuellement)
-- INSERT INTO rides (customer_id, pickup_latitude, pickup_longitude, pickup_address, destination_latitude, destination_longitude, destination_address, status, payment_method) 
-- VALUES (auth.uid(), 9.5370, -13.6785, 'Conakry, Guinée', 9.5370, -13.6785, 'Conakry, Guinée', 'searching', 'cash'); 