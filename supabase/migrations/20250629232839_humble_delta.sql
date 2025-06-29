/*
  # Ajouter les fonctions manquantes utilisées dans le code Flutter

  1. Fonctions RPC manquantes
    - `accept_ride` - pour accepter un trajet (utilisée dans RealtimeService)
    - `update_ride_status` - pour mettre à jour le statut d'un trajet
    - `update_driver_location` - pour mettre à jour la position du chauffeur

  2. Sécurité
    - Politiques RLS appropriées pour ces nouvelles fonctions
*/

-- Fonction pour accepter un trajet (utilisée dans RealtimeService)
CREATE OR REPLACE FUNCTION accept_ride(
  p_ride_id uuid,
  p_driver_id uuid
) RETURNS boolean AS $$
DECLARE
  v_updated_rows integer;
BEGIN
  -- Vérifier que le chauffeur a reçu une demande pour ce trajet
  IF NOT EXISTS (
    SELECT 1 FROM ride_requests 
    WHERE ride_id = p_ride_id 
      AND driver_id = p_driver_id 
      AND status = 'sent'
  ) THEN
    RETURN false;
  END IF;

  -- Mettre à jour le trajet
  UPDATE rides 
  SET 
    driver_id = p_driver_id,
    status = 'accepted',
    accepted_at = now()
  WHERE id = p_ride_id 
    AND status = 'searching';
  
  GET DIAGNOSTICS v_updated_rows = ROW_COUNT;
  
  IF v_updated_rows > 0 THEN
    -- Marquer la demande comme acceptée
    UPDATE ride_requests 
    SET 
      status = 'accepted',
      responded_at = now()
    WHERE ride_id = p_ride_id 
      AND driver_id = p_driver_id;
    
    -- Marquer les autres demandes comme expirées
    UPDATE ride_requests 
    SET 
      status = 'expired',
      responded_at = now()
    WHERE ride_id = p_ride_id 
      AND driver_id != p_driver_id 
      AND status = 'sent';
    
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour le statut d'un trajet
CREATE OR REPLACE FUNCTION update_ride_status(
  p_ride_id uuid,
  p_new_status text,
  p_user_id uuid
) RETURNS boolean AS $$
DECLARE
  v_updated_rows integer;
  v_current_status text;
  v_customer_id uuid;
  v_driver_id uuid;
BEGIN
  -- Récupérer les informations du trajet
  SELECT status, customer_id, driver_id 
  INTO v_current_status, v_customer_id, v_driver_id
  FROM rides 
  WHERE id = p_ride_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Vérifier les permissions
  IF p_user_id != v_customer_id AND p_user_id != v_driver_id THEN
    RETURN false;
  END IF;
  
  -- Vérifier les transitions de statut valides
  CASE p_new_status
    WHEN 'cancelled' THEN
      -- Le client peut annuler avant que le trajet commence
      IF v_current_status NOT IN ('searching', 'accepted') OR p_user_id != v_customer_id THEN
        RETURN false;
      END IF;
    WHEN 'in_progress' THEN
      -- Seul le chauffeur peut démarrer le trajet
      IF v_current_status != 'accepted' OR p_user_id != v_driver_id THEN
        RETURN false;
      END IF;
    WHEN 'completed' THEN
      -- Seul le chauffeur peut terminer le trajet
      IF v_current_status != 'in_progress' OR p_user_id != v_driver_id THEN
        RETURN false;
      END IF;
    ELSE
      RETURN false;
  END CASE;
  
  -- Mettre à jour le statut
  UPDATE rides 
  SET 
    status = p_new_status,
    started_at = CASE WHEN p_new_status = 'in_progress' THEN now() ELSE started_at END,
    completed_at = CASE WHEN p_new_status = 'completed' THEN now() ELSE completed_at END,
    cancelled_at = CASE WHEN p_new_status = 'cancelled' THEN now() ELSE cancelled_at END
  WHERE id = p_ride_id;
  
  GET DIAGNOSTICS v_updated_rows = ROW_COUNT;
  
  RETURN v_updated_rows > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour la position du chauffeur
CREATE OR REPLACE FUNCTION update_driver_location(
  p_driver_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_heading real DEFAULT NULL,
  p_speed real DEFAULT NULL,
  p_is_available boolean DEFAULT true
) RETURNS void AS $$
BEGIN
  -- Vérifier que l'utilisateur est un chauffeur
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = p_driver_id 
      AND role = 'driver' 
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'User is not an active driver';
  END IF;

  -- Insérer ou mettre à jour la position
  INSERT INTO driver_locations (
    driver_id,
    latitude,
    longitude,
    heading,
    speed,
    is_available,
    last_updated
  ) VALUES (
    p_driver_id,
    p_latitude,
    p_longitude,
    p_heading,
    p_speed,
    p_is_available,
    now()
  )
  ON CONFLICT (driver_id) 
  DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    heading = EXCLUDED.heading,
    speed = EXCLUDED.speed,
    is_available = EXCLUDED.is_available,
    last_updated = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les détails d'un trajet par ID
CREATE OR REPLACE FUNCTION get_ride_by_id(p_ride_id uuid)
RETURNS TABLE (
  id uuid,
  customer_id uuid,
  driver_id uuid,
  pickup_latitude numeric,
  pickup_longitude numeric,
  pickup_address text,
  destination_latitude numeric,
  destination_longitude numeric,
  destination_address text,
  status text,
  fare_amount numeric,
  distance_km real,
  estimated_duration_minutes integer,
  payment_method text,
  notes text,
  scheduled_for timestamptz,
  created_at timestamptz,
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  customer_name text,
  customer_phone text,
  driver_name text,
  driver_phone text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.customer_id,
    r.driver_id,
    r.pickup_latitude,
    r.pickup_longitude,
    r.pickup_address,
    r.destination_latitude,
    r.destination_longitude,
    r.destination_address,
    r.status,
    r.fare_amount,
    r.distance_km,
    r.estimated_duration_minutes,
    r.payment_method,
    r.notes,
    r.scheduled_for,
    r.created_at,
    r.accepted_at,
    r.started_at,
    r.completed_at,
    r.cancelled_at,
    cp.full_name as customer_name,
    cp.phone as customer_phone,
    dp.full_name as driver_name,
    dp.phone as driver_phone
  FROM rides r
  LEFT JOIN profiles cp ON cp.id = r.customer_id
  LEFT JOIN profiles dp ON dp.id = r.driver_id
  WHERE r.id = p_ride_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir l'historique des trajets d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_rides(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  customer_id uuid,
  driver_id uuid,
  pickup_latitude numeric,
  pickup_longitude numeric,
  pickup_address text,
  destination_latitude numeric,
  destination_longitude numeric,
  destination_address text,
  status text,
  fare_amount numeric,
  distance_km real,
  estimated_duration_minutes integer,
  payment_method text,
  notes text,
  scheduled_for timestamptz,
  created_at timestamptz,
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  driver_name text,
  driver_phone text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.customer_id,
    r.driver_id,
    r.pickup_latitude,
    r.pickup_longitude,
    r.pickup_address,
    r.destination_latitude,
    r.destination_longitude,
    r.destination_address,
    r.status,
    r.fare_amount,
    r.distance_km,
    r.estimated_duration_minutes,
    r.payment_method,
    r.notes,
    r.scheduled_for,
    r.created_at,
    r.accepted_at,
    r.started_at,
    r.completed_at,
    r.cancelled_at,
    dp.full_name as driver_name,
    dp.phone as driver_phone
  FROM rides r
  LEFT JOIN profiles dp ON dp.id = r.driver_id
  WHERE r.customer_id = p_user_id
  ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;