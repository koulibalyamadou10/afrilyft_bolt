-- SOLUTION D'URGENCE V2 : Corriger définitivement la récursion infinie
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- 1. Désactiver complètement RLS sur toutes les tables
ALTER TABLE rides DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_ratings DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer TOUTES les politiques existantes
-- Rides
DROP POLICY IF EXISTS "Customers can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned rides" ON rides;
DROP POLICY IF EXISTS "Drivers can update assigned rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read searching rides" ON rides;
DROP POLICY IF EXISTS "Users can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned or requested rides" ON rides;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON rides;

-- Ride requests
DROP POLICY IF EXISTS "Drivers can manage own ride requests" ON ride_requests;
DROP POLICY IF EXISTS "Customers can read ride requests for their rides" ON ride_requests;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON ride_requests;

-- Profiles
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read driver profiles" ON profiles;
DROP POLICY IF EXISTS "Users can read other profiles for rides" ON profiles;

-- Driver locations
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read available driver locations" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read driver locations" ON driver_locations;

-- Notifications
DROP POLICY IF EXISTS "Users can manage own notifications" ON notifications;

-- Ride ratings
DROP POLICY IF EXISTS "Users can read ratings for their rides" ON ride_ratings;
DROP POLICY IF EXISTS "Users can create ratings for completed rides" ON ride_ratings;
DROP POLICY IF EXISTS "Users can read their own ratings" ON ride_ratings;

-- 3. Créer des politiques SIMPLES et NON RÉCURSIVES

-- PROFILES - Politiques simples
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

-- RIDES - Politiques simples sans jointures
CREATE POLICY "Customers can manage own rides"
  ON rides FOR ALL
  TO authenticated
  USING (customer_id = auth.uid());

CREATE POLICY "Drivers can read assigned rides"
  ON rides FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Drivers can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

-- Chauffeurs peuvent voir les trajets en recherche (sans jointure)
CREATE POLICY "Drivers can read searching rides"
  ON rides FOR SELECT
  TO authenticated
  USING (status = 'searching');

-- RIDE_REQUESTS - Politiques simples
CREATE POLICY "Drivers can manage own ride requests"
  ON ride_requests FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

-- DRIVER_LOCATIONS - Politiques simples
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Anyone can read available driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (is_available = true);

-- NOTIFICATIONS - Politiques simples
CREATE POLICY "Users can manage own notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- RIDE_RATINGS - Politiques simples
CREATE POLICY "Users can read own ratings"
  ON ride_ratings FOR SELECT
  TO authenticated
  USING (rater_id = auth.uid() OR rated_id = auth.uid());

CREATE POLICY "Users can create own ratings"
  ON ride_ratings FOR INSERT
  TO authenticated
  WITH CHECK (rater_id = auth.uid());

-- 4. Réactiver RLS sur toutes les tables
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_ratings ENABLE ROW LEVEL SECURITY;

-- 5. Vérifier que les politiques sont bien créées
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('rides', 'profiles', 'ride_requests', 'driver_locations', 'notifications', 'ride_ratings')
ORDER BY tablename, policyname;

-- 6. Test de création d'un trajet simple
-- INSERT INTO rides (customer_id, pickup_latitude, pickup_longitude, pickup_address, destination_latitude, destination_longitude, destination_address, status, payment_method) 
-- VALUES (auth.uid(), 9.5370, -13.6785, 'Conakry, Guinée', 9.5370, -13.6785, 'Conakry, Guinée', 'searching', 'cash'); 