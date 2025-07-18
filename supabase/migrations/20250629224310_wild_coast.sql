/*
  # Configuration initiale pour Afrilyft

  1. Tables principales
    - `profiles` - Profils utilisateurs avec rôles (customer/driver)
    - `rides` - Demandes de trajets
    - `ride_requests` - Demandes envoyées aux chauffeurs
    - `driver_locations` - Positions en temps réel des chauffeurs

  2. Sécurité
    - RLS activé sur toutes les tables
    - Politiques pour customers et drivers
    - Triggers pour les notifications

  3. Fonctions
    - Recherche de chauffeurs à proximité
    - Notifications push automatiques
*/

-- Extension pour la géolocalisation
CREATE EXTENSION IF NOT EXISTS postgis;

-- Table des profils utilisateurs
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

-- Table des positions des chauffeurs
CREATE TABLE IF NOT EXISTS driver_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  location geography(POINT, 4326) NOT NULL,
  heading real, -- Direction en degrés
  speed real, -- Vitesse en km/h
  is_available boolean DEFAULT true,
  last_updated timestamptz DEFAULT now(),
  UNIQUE(driver_id)
);

-- Table des trajets
CREATE TABLE IF NOT EXISTS rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  pickup_location geography(POINT, 4326) NOT NULL,
  pickup_address text NOT NULL,
  destination_location geography(POINT, 4326) NOT NULL,
  destination_address text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'searching', 'accepted', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
  fare_amount decimal(10,2),
  distance_km real,
  estimated_duration_minutes integer,
  payment_method text DEFAULT 'cash',
  notes text,
  scheduled_for timestamptz,
  created_at timestamptz DEFAULT now(),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz
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

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_driver_locations_geography ON driver_locations USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_rides_pickup_location ON rides USING GIST (pickup_location);
CREATE INDEX IF NOT EXISTS idx_rides_destination_location ON rides USING GIST (destination_location);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides (status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests (status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_expires_at ON ride_requests (expires_at);

-- Fonction pour calculer la distance entre deux points
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) RETURNS double precision AS $$
BEGIN
  RETURN ST_Distance(
    ST_GeogFromText('POINT(' || lon1 || ' ' || lat1 || ')'),
    ST_GeogFromText('POINT(' || lon2 || ' ' || lat2 || ')')
  ) / 1000; -- Retourne la distance en kilomètres
END;
$$ LANGUAGE plpgsql;

-- Fonction pour trouver les chauffeurs à proximité
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
  last_updated timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dl.driver_id,
    p.full_name,
    p.phone,
    ST_Distance(
      dl.location,
      ST_GeogFromText('POINT(' || pickup_lon || ' ' || pickup_lat || ')')
    ) / 1000 as distance_km,
    ST_Y(dl.location::geometry) as location_lat,
    ST_X(dl.location::geometry) as location_lon,
    dl.last_updated
  FROM driver_locations dl
  JOIN profiles p ON p.id = dl.driver_id
  WHERE 
    dl.is_available = true
    AND p.is_active = true
    AND p.role = 'driver'
    AND ST_DWithin(
      dl.location,
      ST_GeogFromText('POINT(' || pickup_lon || ' ' || pickup_lat || ')'),
      radius_km * 1000
    )
  ORDER BY distance_km
  LIMIT max_drivers;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour créer une demande de trajet et notifier les chauffeurs
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
    pickup_location,
    pickup_address,
    destination_location,
    destination_address,
    distance_km,
    estimated_duration_minutes,
    payment_method,
    notes,
    scheduled_for,
    status
  ) VALUES (
    p_customer_id,
    ST_GeogFromText('POINT(' || p_pickup_lon || ' ' || p_pickup_lat || ')'),
    p_pickup_address,
    ST_GeogFromText('POINT(' || p_destination_lon || ' ' || p_destination_lat || ')'),
    p_destination_address,
    v_distance_km,
    ROUND(v_distance_km * 2.5)::integer, -- Estimation: 2.5 min par km
    p_payment_method,
    p_notes,
    p_scheduled_for,
    CASE WHEN p_scheduled_for IS NULL THEN 'searching' ELSE 'pending' END
  ) RETURNING id INTO v_ride_id;
  
  -- Si c'est un trajet immédiat, chercher et notifier les chauffeurs
  IF p_scheduled_for IS NULL THEN
    -- Trouver les chauffeurs à proximité et créer les demandes
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

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;

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

-- Politiques pour driver_locations
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Customers can read driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
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

CREATE POLICY "Drivers can read assigned rides"
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