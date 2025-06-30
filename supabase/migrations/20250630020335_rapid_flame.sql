/*
  # Correction du schéma d'authentification

  1. Corrections
    - Correction des colonnes de géolocalisation
    - Ajout de la fonction de création automatique de profil
    - Configuration RLS appropriée
    
  2. Sécurité
    - Politiques RLS pour tous les utilisateurs
    - Trigger pour création automatique de profil
*/

-- Supprimer les anciennes tables si elles existent avec des erreurs
DROP TABLE IF EXISTS ride_requests CASCADE;
DROP TABLE IF EXISTS rides CASCADE;
DROP TABLE IF EXISTS driver_locations CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Fonction pour créer automatiquement un profil après inscription
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Table des profils utilisateurs (corrigée)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  phone text UNIQUE NOT NULL,
  role text NOT NULL CHECK (role IN ('customer', 'driver')) DEFAULT 'customer',
  avatar_url text,
  is_active boolean DEFAULT true,
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table des positions des chauffeurs (corrigée avec latitude/longitude séparées)
CREATE TABLE IF NOT EXISTS driver_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  latitude numeric(10,8) NOT NULL,
  longitude numeric(11,8) NOT NULL,
  heading real,
  speed real,
  is_available boolean DEFAULT true,
  last_updated timestamptz DEFAULT now()
);

-- Table des trajets (corrigée)
CREATE TABLE IF NOT EXISTS rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  pickup_latitude numeric(10,8) NOT NULL,
  pickup_longitude numeric(11,8) NOT NULL,
  pickup_address text NOT NULL,
  destination_latitude numeric(10,8) NOT NULL,
  destination_longitude numeric(11,8) NOT NULL,
  destination_address text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'searching', 'accepted', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
  fare_amount numeric(10,2),
  distance_km real,
  estimated_duration_minutes integer,
  payment_method text DEFAULT 'cash',
  notes text,
  scheduled_for timestamptz,
  created_at timestamptz DEFAULT now(),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz
);

-- Table des demandes envoyées aux chauffeurs
CREATE TABLE IF NOT EXISTS ride_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid REFERENCES rides(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('sent', 'seen', 'accepted', 'declined', 'expired')) DEFAULT 'sent',
  sent_at timestamptz DEFAULT now(),
  responded_at timestamptz,
  expires_at timestamptz DEFAULT (now() + interval '2 minutes'),
  UNIQUE(ride_id, driver_id)
);

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type IN ('ride_request', 'ride_update', 'payment', 'general')),
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_driver_locations_lat_lon ON driver_locations (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_driver_locations_available ON driver_locations (is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_driver_locations_available_updated ON driver_locations (is_available, last_updated) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_driver_locations_updated ON driver_locations (last_updated);

CREATE INDEX IF NOT EXISTS idx_rides_customer ON rides (customer_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides (driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides (status);
CREATE INDEX IF NOT EXISTS idx_rides_created ON rides (created_at);
CREATE INDEX IF NOT EXISTS idx_rides_driver_status ON rides (driver_id, status) WHERE driver_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ride_requests_driver ON ride_requests (driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests (status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_expires ON ride_requests (expires_at);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver_status ON ride_requests (driver_id, status);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (user_id, is_read) WHERE is_read = false;

-- Fonction pour calculer la distance entre deux points
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) RETURNS double precision AS $$
BEGIN
  RETURN (
    6371 * acos(
      cos(radians(lat1)) * cos(radians(lat2)) * cos(radians(lon2) - radians(lon1)) +
      sin(radians(lat1)) * sin(radians(lat2))
    )
  );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour trouver les chauffeurs à proximité (corrigée)
CREATE OR REPLACE FUNCTION find_nearby_drivers(
  pickup_lat double precision,
  pickup_lon double precision,
  radius_km double precision DEFAULT 5.0,
  max_drivers integer DEFAULT 10
) RETURNS TABLE (
  driver_id uuid,
  driver_name text,
  driver_phone text,
  distance_km double precision,
  location_lat double precision,
  location_lon double precision,
  heading real,
  speed real,
  last_updated timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dl.driver_id,
    p.full_name,
    p.phone,
    calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) as distance_km,
    dl.latitude::double precision as location_lat,
    dl.longitude::double precision as location_lon,
    dl.heading,
    dl.speed,
    dl.last_updated
  FROM driver_locations dl
  JOIN profiles p ON p.id = dl.driver_id
  WHERE 
    dl.is_available = true
    AND p.is_active = true
    AND p.role = 'driver'
    AND calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) <= radius_km
    -- Exclure les chauffeurs qui ont déjà un trajet en cours
    AND NOT EXISTS (
      SELECT 1 FROM rides r 
      WHERE r.driver_id = dl.driver_id 
      AND r.status IN ('accepted', 'in_progress')
    )
  ORDER BY distance_km
  LIMIT max_drivers;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer une demande de trajet et notifier les chauffeurs (corrigée)
CREATE OR REPLACE FUNCTION create_ride_and_notify_drivers(
  p_customer_id uuid,
  p_pickup_lat double precision,
  p_pickup_lon double precision,
  p_pickup_address text,
  p_destination_lat double precision,
  p_destination_lon double precision,
  p_destination_address text,
  p_payment_method text DEFAULT 'cash',
  p_notes text DEFAULT NULL,
  p_scheduled_for timestamptz DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
  v_ride_id uuid;
  v_driver record;
  v_distance_km real;
BEGIN
  -- Calculer la distance estimée
  v_distance_km := calculate_distance(p_pickup_lat, p_pickup_lon, p_destination_lat, p_destination_lon);
  
  -- Créer le trajet
  INSERT INTO rides (
    customer_id,
    pickup_latitude,
    pickup_longitude,
    pickup_address,
    destination_latitude,
    destination_longitude,
    destination_address,
    distance_km,
    estimated_duration_minutes,
    payment_method,
    notes,
    scheduled_for,
    status
  ) VALUES (
    p_customer_id,
    p_pickup_lat,
    p_pickup_lon,
    p_pickup_address,
    p_destination_lat,
    p_destination_lon,
    p_destination_address,
    v_distance_km,
    ROUND(v_distance_km * 2.5)::integer,
    p_payment_method,
    p_notes,
    p_scheduled_for,
    CASE WHEN p_scheduled_for IS NULL THEN 'searching' ELSE 'pending' END
  ) RETURNING id INTO v_ride_id;
  
  -- Si c'est un trajet immédiat, chercher et notifier les chauffeurs
  IF p_scheduled_for IS NULL THEN
    FOR v_driver IN 
      SELECT driver_id FROM find_nearby_drivers(p_pickup_lat, p_pickup_lon, 5.0, 10)
    LOOP
      INSERT INTO ride_requests (ride_id, driver_id)
      VALUES (v_ride_id, v_driver.driver_id);
    END LOOP;
  END IF;
  
  RETURN v_ride_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour accepter un trajet
CREATE OR REPLACE FUNCTION accept_ride(
  p_ride_id uuid,
  p_driver_id uuid
) RETURNS boolean AS $$
DECLARE
  v_ride_status text;
BEGIN
  -- Vérifier que le trajet est toujours disponible
  SELECT status INTO v_ride_status FROM rides WHERE id = p_ride_id;
  
  IF v_ride_status != 'searching' THEN
    RETURN false;
  END IF;
  
  -- Mettre à jour le trajet
  UPDATE rides 
  SET 
    driver_id = p_driver_id,
    status = 'accepted',
    accepted_at = now()
  WHERE id = p_ride_id AND status = 'searching';
  
  -- Mettre à jour la demande
  UPDATE ride_requests 
  SET 
    status = 'accepted',
    responded_at = now()
  WHERE ride_id = p_ride_id AND driver_id = p_driver_id;
  
  -- Marquer les autres demandes comme expirées
  UPDATE ride_requests 
  SET 
    status = 'expired',
    responded_at = now()
  WHERE ride_id = p_ride_id AND driver_id != p_driver_id AND status = 'sent';
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour le statut d'un trajet
CREATE OR REPLACE FUNCTION update_ride_status(
  p_ride_id uuid,
  p_new_status text,
  p_user_id uuid
) RETURNS boolean AS $$
DECLARE
  v_ride record;
BEGIN
  -- Récupérer les informations du trajet
  SELECT * INTO v_ride FROM rides WHERE id = p_ride_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Vérifier les permissions
  IF v_ride.customer_id != p_user_id AND v_ride.driver_id != p_user_id THEN
    RETURN false;
  END IF;
  
  -- Mettre à jour selon le nouveau statut
  CASE p_new_status
    WHEN 'in_progress' THEN
      UPDATE rides SET status = 'in_progress', started_at = now() WHERE id = p_ride_id;
    WHEN 'completed' THEN
      UPDATE rides SET status = 'completed', completed_at = now() WHERE id = p_ride_id;
    WHEN 'cancelled' THEN
      UPDATE rides SET status = 'cancelled', cancelled_at = now() WHERE id = p_ride_id;
    ELSE
      RETURN false;
  END CASE;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour la disponibilité du chauffeur
CREATE OR REPLACE FUNCTION update_driver_availability()
RETURNS TRIGGER AS $$
BEGIN
  -- Si le trajet est accepté ou en cours, marquer le chauffeur comme non disponible
  IF NEW.status IN ('accepted', 'in_progress') AND NEW.driver_id IS NOT NULL THEN
    UPDATE driver_locations 
    SET is_available = false 
    WHERE driver_id = NEW.driver_id;
  -- Si le trajet est terminé ou annulé, marquer le chauffeur comme disponible
  ELSIF NEW.status IN ('completed', 'cancelled') AND NEW.driver_id IS NOT NULL THEN
    UPDATE driver_locations 
    SET is_available = true 
    WHERE driver_id = NEW.driver_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour nettoyer les demandes expirées
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_requests()
RETURNS TRIGGER AS $$
BEGIN
  -- Nettoyer les demandes expirées
  UPDATE ride_requests 
  SET status = 'expired' 
  WHERE expires_at < now() AND status = 'sent';
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_driver_availability
  AFTER UPDATE ON rides
  FOR EACH ROW
  EXECUTE FUNCTION update_driver_availability();

CREATE TRIGGER cleanup_expired_requests_trigger
  AFTER INSERT ON ride_requests
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_cleanup_expired_requests();

-- RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Politiques pour profiles
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

CREATE POLICY "Users can read other profiles for rides"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    role = 'driver' OR
    EXISTS (
      SELECT 1 FROM rides 
      WHERE (customer_id = auth.uid() AND driver_id = profiles.id) OR
            (driver_id = auth.uid() AND customer_id = profiles.id)
    )
  );

-- Politiques pour driver_locations
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Customers can read available driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    is_available = true AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'customer'
    )
  );

-- Politiques pour rides
CREATE POLICY "Customers can manage own rides"
  ON rides FOR ALL
  TO authenticated
  USING (customer_id = auth.uid());

CREATE POLICY "Drivers can read assigned or requested rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    driver_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM ride_requests 
      WHERE ride_id = rides.id AND driver_id = auth.uid()
    )
  );

CREATE POLICY "Drivers can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

-- Politiques pour ride_requests
CREATE POLICY "Drivers can manage own ride requests"
  ON ride_requests FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Customers can read ride requests for their rides"
  ON ride_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE id = ride_requests.ride_id AND customer_id = auth.uid()
    )
  );

-- Politiques pour notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());