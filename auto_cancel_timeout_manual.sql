-- Script pour ajouter l'annulation automatique après 2 minutes
-- À exécuter dans la console SQL de Supabase

-- Fonction pour annuler automatiquement les trajets expirés
CREATE OR REPLACE FUNCTION auto_cancel_expired_rides()
RETURNS void AS $$
BEGIN
  -- Marquer comme annulés les trajets en recherche depuis plus de 2 minutes
  -- et qui n'ont aucune demande acceptée
  UPDATE rides 
  SET 
    status = 'cancelled',
    cancelled_at = now()
  WHERE 
    status = 'searching'
    AND created_at < (now() - interval '2 minutes')
    AND NOT EXISTS (
      SELECT 1 FROM ride_requests 
      WHERE ride_id = rides.id 
      AND status = 'accepted'
    );
  
  -- Marquer comme expirées toutes les demandes non répondues pour les trajets annulés
  UPDATE ride_requests 
  SET status = 'expired'
  WHERE status = 'sent'
  AND ride_id IN (
    SELECT id FROM rides 
    WHERE status = 'cancelled' 
    AND cancelled_at > (now() - interval '1 minute')
  );
  
  RAISE LOG 'Auto-cancelled expired rides: %', (SELECT count(*) FROM rides WHERE status = 'cancelled' AND cancelled_at > (now() - interval '1 minute'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction trigger pour exécuter l'annulation automatique
CREATE OR REPLACE FUNCTION trigger_auto_cancel_expired_rides()
RETURNS TRIGGER AS $$
BEGIN
  -- Exécuter la fonction d'annulation automatique
  PERFORM auto_cancel_expired_rides();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour exécuter l'annulation automatique après chaque insertion de demande
DROP TRIGGER IF EXISTS auto_cancel_expired_rides_trigger ON ride_requests;
CREATE TRIGGER auto_cancel_expired_rides_trigger
  AFTER INSERT ON ride_requests
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_auto_cancel_expired_rides();

-- Trigger pour exécuter l'annulation automatique après chaque mise à jour de demande
DROP TRIGGER IF EXISTS auto_cancel_expired_rides_update_trigger ON ride_requests;
CREATE TRIGGER auto_cancel_expired_rides_update_trigger
  AFTER UPDATE ON ride_requests
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_auto_cancel_expired_rides();

-- Fonction pour vérifier et annuler un trajet spécifique
CREATE OR REPLACE FUNCTION check_and_cancel_ride_if_expired(p_ride_id uuid)
RETURNS boolean AS $$
DECLARE
  v_ride_status text;
  v_has_accepted_request boolean;
BEGIN
  -- Vérifier le statut du trajet
  SELECT status INTO v_ride_status 
  FROM rides 
  WHERE id = p_ride_id;
  
  IF v_ride_status != 'searching' THEN
    RETURN false; -- Trajet déjà traité
  END IF;
  
  -- Vérifier s'il y a une demande acceptée
  SELECT EXISTS(
    SELECT 1 FROM ride_requests 
    WHERE ride_id = p_ride_id 
    AND status = 'accepted'
  ) INTO v_has_accepted_request;
  
  -- Si pas de demande acceptée et le trajet a plus de 2 minutes
  IF NOT v_has_accepted_request AND 
     EXISTS(SELECT 1 FROM rides WHERE id = p_ride_id AND created_at < (now() - interval '2 minutes')) THEN
    
    -- Annuler le trajet
    UPDATE rides 
    SET 
      status = 'cancelled',
      cancelled_at = now()
    WHERE id = p_ride_id;
    
    -- Marquer toutes les demandes comme expirées
    UPDATE ride_requests 
    SET status = 'expired'
    WHERE ride_id = p_ride_id AND status = 'sent';
    
    RAISE LOG 'Auto-cancelled ride: %', p_ride_id;
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Message de confirmation
SELECT 'Fonctionnalité d''annulation automatique après 2 minutes installée avec succès!' as message; 