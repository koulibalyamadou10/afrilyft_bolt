/*
  # Schéma complet AfriLyft avec événements temps réel

  1. Tables principales
    - `profiles` - Profils utilisateurs (customers et drivers)
    - `driver_locations` - Positions des chauffeurs en temps réel
    - `rides` - Trajets avec statuts
    - `ride_requests` - Demandes envoyées aux chauffeurs
    - `notifications` - Notifications push

  2. Fonctions
    - Calcul de distance (Haversine)
    - Recherche de chauffeurs à proximité
    - Création de trajet avec notification automatique
    - Gestion des statuts de trajet

  3. Événements temps réel
    - Écoute des changements de position des chauffeurs
    - Notifications de nouveaux trajets
    - Mises à jour de statut en temps réel
    - Synchronisation automatique

  4. Sécurité RLS
    - Politiques de sécurité pour chaque table
    - Accès contrôlé par rôle utilisateur
*/

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des profils utilisateurs
CREATE TABLE profiles (
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
CREATE TABLE driver_locations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  latitude numeric(10,8) NOT NULL,
  longitude numeric(11,8) NOT NULL,
  heading real, -- Direction en degrés (0-360)
  speed real, -- Vitesse en km/h
  is_available boolean DEFAULT true,
  last_updated timestamptz DEFAULT now(),
  UNIQUE(driver_id)
);

-- Table des trajets
CREATE TABLE rides (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  pickup_latitude numeric(10,8) NOT NULL,
  pickup_longitude numeric(11,8) NOT NULL,
  pickup_address text NOT NULL,
  destination_latitude numeric(10,8) NOT NULL,
  destination_longitude numeric(11,8) NOT NULL,
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
  completed_at timestamptz,
  cancelled_at timestamptz
);

-- Table des demandes envoyées aux chauffeurs
CREATE TABLE ride_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id uuid REFERENCES rides(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('sent', 'seen', 'accepted', 'declined', 'expired')) DEFAULT 'sent',
  sent_at timestamptz DEFAULT now(),
  responded_at timestamptz,
  expires_at timestamptz DEFAULT (now() + interval '2 minutes'),
  UNIQUE(ride_id, driver_id)
);

-- Table des notifications
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type IN ('ride_request', 'ride_update', 'payment', 'general')),
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Index pour les performances
CREATE INDEX idx_driver_locations_lat_lon ON driver_locations (latitude, longitude);
CREATE INDEX idx_driver_locations_available ON driver_locations (is_available) WHERE is_available = true;
CREATE INDEX idx_driver_locations_updated ON driver_locations (last_updated);
CREATE INDEX idx_rides_customer ON rides (customer_id);
CREATE INDEX idx_rides_driver ON rides (driver_id);
CREATE INDEX idx_rides_status ON rides (status);
CREATE INDEX idx_rides_created ON rides (created_at);
CREATE INDEX idx_ride_requests_driver ON ride_requests (driver_id);
CREATE INDEX idx_ride_requests_status ON ride_requests (status);
CREATE INDEX idx_ride_requests_expires ON ride_requests (expires_at);
CREATE INDEX idx_notifications_user ON notifications (user_id);
CREATE INDEX idx_notifications_unread ON notifications (user_id, is_read) WHERE is_read = false;

-- Fonction pour calculer la distance entre deux points (formule de Haversine)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) RETURNS double precision AS $$
DECLARE
  dlat double precision;
  dlon double precision;
  a double precision;
  c double precision;
  r double precision := 6371; -- Rayon de la Terre en km
BEGIN
  -- Vérifier les valeurs nulles
  IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
    RETURN NULL;
  END IF;
  
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  a := sin(dlat/2) * sin(dlat/2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2) * sin(dlon/2);
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  
  RETURN r * c;
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
  last_updated timestamptz,
  heading real,
  speed real
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dl.driver_id,
    p.full_name as driver_name,
    p.phone as driver_phone,
    calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) as distance_km,
    dl.latitude::double precision as location_lat,
    dl.longitude::double precision as location_lon,
    dl.last_updated,
    dl.heading,
    dl.speed
  FROM driver_locations dl
  JOIN profiles p ON p.id = dl.driver_id
  WHERE 
    dl.is_available = true
    AND p.is_active = true
    AND p.role = 'driver'
    AND calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) <= radius_km
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
  v_estimated_fare decimal(10,2);
BEGIN
  -- Calculer la distance estimée
  v_distance_km := calculate_distance(p_pickup_lat, p_pickup_lon, p_destination_lat, p_destination_lon);
  
  -- Calculer le tarif estimé (exemple: 1000 GNF par km + 2000 GNF de base)
  v_estimated_fare := COALESCE(v_distance_km, 0) * 1000 + 2000;
  
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
    fare_amount,
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
    ROUND(COALESCE(v_distance_km, 0) * 2.5)::integer, -- Estimation: 2.5 min par km
    v_estimated_fare,
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
      -- Créer la demande pour le chauffeur
      INSERT INTO ride_requests (ride_id, driver_id)
      VALUES (v_ride_id, v_driver.driver_id);
      
      -- Créer une notification pour le chauffeur
      INSERT INTO notifications (user_id, title, message, type, data)
      VALUES (
        v_driver.driver_id,
        'Nouvelle demande de trajet',
        'Un client souhaite effectuer un trajet près de votre position',
        'ride_request',
        jsonb_build_object(
          'ride_id', v_ride_id,
          'pickup_address', p_pickup_address,
          'destination_address', p_destination_address,
          'distance_km', v_distance_km,
          'estimated_fare', v_estimated_fare
        )
      );
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
  v_customer_id uuid;
BEGIN
  -- Vérifier que le trajet existe et est en recherche
  SELECT status, customer_id INTO v_ride_status, v_customer_id
  FROM rides 
  WHERE id = p_ride_id;
  
  IF v_ride_status != 'searching' THEN
    RETURN false;
  END IF;
  
  -- Mettre à jour le trajet
  UPDATE rides 
  SET 
    driver_id = p_driver_id,
    status = 'accepted',
    accepted_at = now()
  WHERE id = p_ride_id;
  
  -- Marquer la demande comme acceptée
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
  
  -- Notifier le client
  INSERT INTO notifications (user_id, title, message, type, data)
  VALUES (
    v_customer_id,
    'Chauffeur trouvé !',
    'Un chauffeur a accepté votre demande et arrive vers vous',
    'ride_update',
    jsonb_build_object('ride_id', p_ride_id, 'status', 'accepted')
  );
  
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
  v_notification_title text;
  v_notification_message text;
  v_target_user_id uuid;
BEGIN
  -- Récupérer les informations du trajet
  SELECT * INTO v_ride FROM rides WHERE id = p_ride_id;
  
  IF v_ride IS NULL THEN
    RETURN false;
  END IF;
  
  -- Vérifier les permissions
  IF p_user_id != v_ride.customer_id AND p_user_id != v_ride.driver_id THEN
    RETURN false;
  END IF;
  
  -- Mettre à jour le statut
  CASE p_new_status
    WHEN 'in_progress' THEN
      UPDATE rides SET status = p_new_status, started_at = now() WHERE id = p_ride_id;
      v_notification_title := 'Trajet commencé';
      v_notification_message := 'Votre trajet a commencé, bon voyage !';
      v_target_user_id := v_ride.customer_id;
      
    WHEN 'completed' THEN
      UPDATE rides SET status = p_new_status, completed_at = now() WHERE id = p_ride_id;
      v_notification_title := 'Trajet terminé';
      v_notification_message := 'Votre trajet est terminé. Merci d''avoir utilisé AfriLyft !';
      v_target_user_id := v_ride.customer_id;
      
    WHEN 'cancelled' THEN
      UPDATE rides SET status = p_new_status, cancelled_at = now() WHERE id = p_ride_id;
      v_notification_title := 'Trajet annulé';
      v_notification_message := 'Le trajet a été annulé';
      v_target_user_id := CASE WHEN p_user_id = v_ride.customer_id THEN v_ride.driver_id ELSE v_ride.customer_id END;
      
    ELSE
      UPDATE rides SET status = p_new_status WHERE id = p_ride_id;
  END CASE;
  
  -- Envoyer une notification si nécessaire
  IF v_target_user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, title, message, type, data)
    VALUES (
      v_target_user_id,
      v_notification_title,
      v_notification_message,
      'ride_update',
      jsonb_build_object('ride_id', p_ride_id, 'status', p_new_status)
    );
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour la position d'un chauffeur
CREATE OR REPLACE FUNCTION update_driver_location(
  p_driver_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_heading real DEFAULT NULL,
  p_speed real DEFAULT NULL,
  p_is_available boolean DEFAULT true
) RETURNS void AS $$
BEGIN
  INSERT INTO driver_locations (driver_id, latitude, longitude, heading, speed, is_available, last_updated)
  VALUES (p_driver_id, p_latitude, p_longitude, p_heading, p_speed, p_is_available, now())
  ON CONFLICT (driver_id) 
  DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    heading = EXCLUDED.heading,
    speed = EXCLUDED.speed,
    is_available = EXCLUDED.is_available,
    last_updated = EXCLUDED.last_updated;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour nettoyer les demandes expirées
CREATE OR REPLACE FUNCTION cleanup_expired_requests() RETURNS void AS $$
BEGIN
  UPDATE ride_requests 
  SET status = 'expired'
  WHERE status = 'sent' AND expires_at < now();
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

-- Trigger pour nettoyer automatiquement les demandes expirées
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_requests()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM cleanup_expired_requests();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

-- Fonction pour créer un profil automatiquement après inscription
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, phone, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer automatiquement un profil
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();