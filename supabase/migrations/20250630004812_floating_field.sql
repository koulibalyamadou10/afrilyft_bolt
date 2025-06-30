/*
  # Amélioration de la recherche de chauffeurs disponibles

  1. Modifications
    - Mise à jour de la fonction `find_nearby_drivers` pour exclure les chauffeurs en course
    - Ajout de vérifications pour les statuts de trajets actifs
    - Optimisation des performances avec de nouveaux index

  2. Sécurité
    - Les chauffeurs avec des trajets actifs ne sont plus visibles
    - Seuls les chauffeurs vraiment disponibles sont retournés
*/

-- Fonction améliorée pour trouver les chauffeurs disponibles
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
    
    -- NOUVEAU: Exclure les chauffeurs qui ont déjà un trajet en cours
    AND NOT EXISTS (
      SELECT 1 FROM rides r 
      WHERE r.driver_id = dl.driver_id 
      AND r.status IN ('accepted', 'in_progress')
    )
    
    -- NOUVEAU: Exclure les chauffeurs qui ont des demandes acceptées non terminées
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

-- Créer le trigger pour la mise à jour automatique de disponibilité
DROP TRIGGER IF EXISTS trigger_update_driver_availability ON rides;
CREATE TRIGGER trigger_update_driver_availability
  AFTER UPDATE ON rides
  FOR EACH ROW
  EXECUTE FUNCTION update_driver_availability();

-- Fonction pour nettoyer les demandes expirées
CREATE OR REPLACE FUNCTION cleanup_expired_requests()
RETURNS void AS $$
BEGIN
  -- Marquer comme expirées les demandes non répondues
  UPDATE ride_requests 
  SET status = 'expired'
  WHERE status = 'sent' 
  AND expires_at < now();
  
  -- Remettre les trajets en recherche si toutes les demandes ont expiré
  UPDATE rides 
  SET status = 'searching'
  WHERE status = 'searching'
  AND NOT EXISTS (
    SELECT 1 FROM ride_requests 
    WHERE ride_id = rides.id 
    AND status IN ('sent', 'accepted')
  );
END;
$$ LANGUAGE plpgsql;

-- Trigger pour nettoyer automatiquement les demandes expirées
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_requests()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM cleanup_expired_requests();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS cleanup_expired_requests_trigger ON ride_requests;
CREATE TRIGGER cleanup_expired_requests_trigger
  AFTER INSERT ON ride_requests
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_cleanup_expired_requests();

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
  
  -- Décliner toutes les autres demandes pour ce trajet
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

-- Index supplémentaires pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_rides_driver_status ON rides (driver_id, status) WHERE driver_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver_status ON ride_requests (driver_id, status);
CREATE INDEX IF NOT EXISTS idx_driver_locations_available_updated ON driver_locations (is_available, last_updated) WHERE is_available = true;