/*
  # Migration complète pour le système de réservation AfriLyft

  1. Tables principales
    - `profiles` - Profils utilisateurs (clients et chauffeurs)
    - `driver_locations` - Positions des chauffeurs en temps réel
    - `rides` - Trajets avec toutes les informations
    - `ride_requests` - Demandes envoyées aux chauffeurs
    - `notifications` - Système de notifications

  2. Fonctions métier
    - `find_nearby_drivers` - Recherche chauffeurs disponibles (exclut ceux en course)
    - `create_ride_and_notify_drivers` - Création trajet + notification
    - `accept_ride` - Acceptation par chauffeur + annulation autres demandes
    - `update_ride_status` - Gestion des statuts de trajet

  3. Sécurité
    - RLS activé sur toutes les tables
    - Politiques pour clients et chauffeurs
    - Triggers pour mise à jour automatique
*/

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

-- Ajouter les colonnes manquantes à driver_locations si elles n'existent pas
DO $$
BEGIN
  -- Ajouter heading si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'driver_locations' AND column_name = 'heading'
  ) THEN
    ALTER TABLE driver_locations ADD COLUMN heading real;
  END IF;

  -- Ajouter speed si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'driver_locations' AND column_name = 'speed'
  ) THEN
    ALTER TABLE driver_locations ADD COLUMN speed real;
  END IF;

  -- Ajouter is_available si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'driver_locations' AND column_name = 'is_available'
  ) THEN
    ALTER TABLE driver_locations ADD COLUMN is_available boolean DEFAULT true;
  END IF;
END $$;

-- Ajouter les colonnes manquantes à rides si elles n'existent pas
DO $$
BEGIN
  -- Ajouter fare_amount si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'fare_amount'
  ) THEN
    ALTER TABLE rides ADD COLUMN fare_amount numeric(10,2);
  END IF;

  -- Ajouter distance_km si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'distance_km'
  ) THEN
    ALTER TABLE rides ADD COLUMN distance_km real;
  END IF;

  -- Ajouter estimated_duration_minutes si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'estimated_duration_minutes'
  ) THEN
    ALTER TABLE rides ADD COLUMN estimated_duration_minutes integer;
  END IF;

  -- Ajouter notes si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'notes'
  ) THEN
    ALTER TABLE rides ADD COLUMN notes text;
  END IF;

  -- Ajouter scheduled_for si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'scheduled_for'
  ) THEN
    ALTER TABLE rides ADD COLUMN scheduled_for timestamptz;
  END IF;

  -- Ajouter accepted_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'accepted_at'
  ) THEN
    ALTER TABLE rides ADD COLUMN accepted_at timestamptz;
  END IF;

  -- Ajouter started_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'started_at'
  ) THEN
    ALTER TABLE rides ADD COLUMN started_at timestamptz;
  END IF;

  -- Ajouter completed_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'completed_at'
  ) THEN
    ALTER TABLE rides ADD COLUMN completed_at timestamptz;
  END IF;

  -- Ajouter cancelled_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rides' AND column_name = 'cancelled_at'
  ) THEN
    ALTER TABLE rides ADD COLUMN cancelled_at timestamptz;
  END IF;
END $$;

-- Table des demandes envoyées aux chauffeurs
CREATE TABLE IF NOT EXISTS ride_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL,
  driver_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('sent', 'seen', 'accepted', 'declined', 'expired')) DEFAULT 'sent',
  sent_at timestamptz DEFAULT now(),
  responded_at timestamptz,
  expires_at timestamptz DEFAULT (now() + interval '2 minutes'),
  UNIQUE(ride_id, driver_id)
);

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type IN ('ride_request', 'ride_update', 'payment', 'general')),
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Ajouter les contraintes de clés étrangères après la création des tables
DO $$
BEGIN
  -- Contraintes pour ride_requests
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'ride_requests_ride_id_fkey'
  ) THEN
    ALTER TABLE ride_requests 
    ADD CONSTRAINT ride_requests_ride_id_fkey 
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'ride_requests_driver_id_fkey'
  ) THEN
    ALTER TABLE ride_requests 
    ADD CONSTRAINT ride_requests_driver_id_fkey 
    FOREIGN KEY (driver_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;

  -- Contraintes pour notifications
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'notifications_user_id_fkey'
  ) THEN
    ALTER TABLE notifications 
    ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_driver_locations_lat_lon ON driver_locations (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_driver_locations_available ON driver_locations (is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_driver_locations_updated ON driver_locations (last_updated);
CREATE INDEX IF NOT EXISTS idx_rides_customer ON rides (customer_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides (driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides (status);
CREATE INDEX IF NOT EXISTS idx_rides_created ON rides (created_at);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver ON ride_requests (driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests (status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_expires ON ride_requests (expires_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (user_id, is_read) WHERE is_read = false;

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

-- Fonction pour trouver les chauffeurs à proximité (EXCLUT ceux en course)
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
    COALESCE(p.full_name, '') as driver_name,
    COALESCE(p.phone, '') as driver_phone,
    calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) as distance_km,
    dl.latitude::double precision as location_lat,
    dl.longitude::double precision as location_lon,
    dl.heading,
    dl.speed,
    dl.last_updated
  FROM driver_locations dl
  LEFT JOIN profiles p ON p.id = dl.driver_id
  WHERE 
    -- Chauffeur disponible et actif
    COALESCE(dl.is_available, true) = true
    AND COALESCE(p.is_active, true) = true
    AND COALESCE(p.role, 'driver') = 'driver'
    
    -- IMPORTANT: Exclure les chauffeurs qui ont déjà un trajet en cours
    AND NOT EXISTS (
      SELECT 1 FROM rides r 
      WHERE r.driver_id = dl.driver_id 
      AND r.status IN ('accepted', 'in_progress')
    )
    
    -- Exclure les chauffeurs qui ont des demandes acceptées non terminées
    AND NOT EXISTS (
      SELECT 1 FROM ride_requests rr
      JOIN rides r ON r.id = rr.ride_id
      WHERE rr.driver_id = dl.driver_id 
      AND rr.status = 'accepted'
      AND r.status NOT IN ('completed', 'cancelled')
    )
    
    -- Dans le rayon de recherche
    AND calculate_distance(pickup_lat, pickup_lon, dl.latitude::double precision, dl.longitude::double precision) <= radius_km
    
    -- Position mise à jour récemment (moins de 5 minutes)
    AND dl.last_updated > (now() - interval '5 minutes')
    
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
    ROUND(COALESCE(v_distance_km, 0) * 2.5)::integer, -- Estimation: 2.5 min par km
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

-- Fonction pour accepter un trajet (utilisée par l'app chauffeur)
CREATE OR REPLACE FUNCTION accept_ride(
  p_ride_id uuid,
  p_driver_id uuid
) RETURNS boolean AS $$
DECLARE
  v_ride_status text;
  v_request_exists boolean;
BEGIN
  -- Vérifier que la demande existe et est valide
  SELECT EXISTS(
    SELECT 1 FROM ride_requests 
    WHERE ride_id = p_ride_id 
    AND driver_id = p_driver_id 
    AND status = 'sent'
    AND expires_at > now()
  ) INTO v_request_exists;
  
  IF NOT v_request_exists THEN
    RETURN false;
  END IF;
  
  -- Vérifier que le trajet est toujours en recherche
  SELECT status INTO v_ride_status 
  FROM rides 
  WHERE id = p_ride_id;
  
  IF v_ride_status != 'searching' THEN
    RETURN false;
  END IF;
  
  -- Accepter la demande
  UPDATE ride_requests 
  SET status = 'accepted', responded_at = now()
  WHERE ride_id = p_ride_id AND driver_id = p_driver_id;
  
  -- IMPORTANT: Décliner automatiquement toutes les autres demandes
  UPDATE ride_requests 
  SET status = 'declined', responded_at = now()
  WHERE ride_id = p_ride_id AND driver_id != p_driver_id AND status = 'sent';
  
  -- Assigner le chauffeur au trajet
  UPDATE rides 
  SET driver_id = p_driver_id, 
      status = 'accepted', 
      accepted_at = now()
  WHERE id = p_ride_id;
  
  -- Marquer le chauffeur comme non disponible
  UPDATE driver_locations 
  SET is_available = false 
  WHERE driver_id = p_driver_id;
  
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
  SELECT * INTO v_ride 
  FROM rides 
  WHERE id = p_ride_id;
  
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
      IF v_ride.status = 'accepted' AND v_ride.driver_id = p_user_id THEN
        UPDATE rides 
        SET status = 'in_progress', started_at = now()
        WHERE id = p_ride_id;
      ELSE
        RETURN false;
      END IF;
      
    WHEN 'completed' THEN
      IF v_ride.status = 'in_progress' AND v_ride.driver_id = p_user_id THEN
        UPDATE rides 
        SET status = 'completed', completed_at = now()
        WHERE id = p_ride_id;
        
        -- Remettre le chauffeur disponible
        UPDATE driver_locations 
        SET is_available = true 
        WHERE driver_id = v_ride.driver_id;
      ELSE
        RETURN false;
      END IF;
      
    WHEN 'cancelled' THEN
      IF v_ride.status IN ('searching', 'accepted', 'in_progress') THEN
        UPDATE rides 
        SET status = 'cancelled', cancelled_at = now()
        WHERE id = p_ride_id;
        
        -- Remettre le chauffeur disponible si assigné
        IF v_ride.driver_id IS NOT NULL THEN
          UPDATE driver_locations 
          SET is_available = true 
          WHERE driver_id = v_ride.driver_id;
        END IF;
      ELSE
        RETURN false;
      END IF;
      
    ELSE
      RETURN false;
  END CASE;
  
  RETURN true;
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

-- Fonction pour mettre à jour automatiquement la disponibilité du chauffeur
CREATE OR REPLACE FUNCTION update_driver_availability()
RETURNS TRIGGER AS $$
BEGIN
  -- Quand un trajet est accepté, marquer le chauffeur comme non disponible
  IF NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
    UPDATE driver_locations 
    SET is_available = false 
    WHERE driver_id = NEW.driver_id;
  END IF;
  
  -- Quand un trajet est terminé ou annulé, marquer le chauffeur comme disponible
  IF NEW.status IN ('completed', 'cancelled') AND OLD.status NOT IN ('completed', 'cancelled') THEN
    UPDATE driver_locations 
    SET is_available = true 
    WHERE driver_id = NEW.driver_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer les triggers
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
    CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Trigger pour la mise à jour automatique de disponibilité
  DROP TRIGGER IF EXISTS trigger_update_driver_availability ON rides;
  CREATE TRIGGER trigger_update_driver_availability
    AFTER UPDATE ON rides
    FOR EACH ROW
    EXECUTE FUNCTION update_driver_availability();
END $$;

-- RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Politiques pour profiles
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can read other profiles for rides" ON profiles;
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

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Politiques pour driver_locations
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

DROP POLICY IF EXISTS "Customers can read available driver locations" ON driver_locations;
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
DROP POLICY IF EXISTS "Customers can manage own rides" ON rides;
CREATE POLICY "Customers can manage own rides"
  ON rides FOR ALL
  TO authenticated
  USING (customer_id = auth.uid());

DROP POLICY IF EXISTS "Drivers can read assigned or requested rides" ON rides;
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

DROP POLICY IF EXISTS "Drivers can update assigned rides" ON rides;
CREATE POLICY "Drivers can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

-- Politiques pour ride_requests
DROP POLICY IF EXISTS "Drivers can manage own ride requests" ON ride_requests;
CREATE POLICY "Drivers can manage own ride requests"
  ON ride_requests FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

DROP POLICY IF EXISTS "Customers can read ride requests for their rides" ON ride_requests;
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
DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());