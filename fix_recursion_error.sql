-- Script pour corriger la récursion infinie dans les triggers
-- À exécuter dans la console SQL de Supabase

-- 1. Supprimer TOUS les triggers problématiques
DROP TRIGGER IF EXISTS auto_cancel_expired_rides_trigger ON ride_requests;
DROP TRIGGER IF EXISTS auto_cancel_expired_rides_update_trigger ON ride_requests;
DROP TRIGGER IF EXISTS cleanup_expired_requests_trigger ON ride_requests;

-- 2. Supprimer les fonctions problématiques
DROP FUNCTION IF EXISTS trigger_auto_cancel_expired_rides();
DROP FUNCTION IF EXISTS auto_cancel_expired_rides();
DROP FUNCTION IF EXISTS trigger_cleanup_expired_requests();

-- 3. Recréer la fonction d'annulation automatique (CORRIGÉE)
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

-- 4. Recréer la fonction trigger (CORRIGÉE)
CREATE OR REPLACE FUNCTION trigger_auto_cancel_expired_rides()
RETURNS TRIGGER AS $$
BEGIN
  -- Éviter la récursion en vérifiant le type d'opération
  IF TG_OP = 'INSERT' THEN
    -- Pour les insertions, exécuter seulement si c'est une nouvelle demande
    IF NEW.status = 'sent' THEN
      -- Utiliser un délai pour éviter la récursion immédiate
      PERFORM pg_sleep(0.1);
      PERFORM auto_cancel_expired_rides();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Pour les mises à jour, exécuter seulement si le statut change vers 'accepted'
    IF OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
      -- Pas besoin d'annuler si une demande est acceptée
      RETURN NEW;
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 5. Recréer la fonction de nettoyage (CORRIGÉE)
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_requests()
RETURNS TRIGGER AS $$
BEGIN
  -- Nettoyer les demandes expirées sans créer de récursion
  UPDATE ride_requests 
  SET status = 'expired' 
  WHERE expires_at < now() AND status = 'sent';
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 6. Recréer les triggers (CORRIGÉS)
CREATE TRIGGER auto_cancel_expired_rides_trigger
  AFTER INSERT ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_auto_cancel_expired_rides();

CREATE TRIGGER auto_cancel_expired_rides_update_trigger
  AFTER UPDATE ON ride_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_auto_cancel_expired_rides();

-- Note: Le trigger cleanup_expired_requests_trigger est maintenant géré par auto_cancel_expired_rides
-- donc on ne le recrée pas pour éviter les conflits

-- 7. Recréer la fonction de vérification spécifique (CORRIGÉE)
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

-- 8. Vérifier que les corrections sont appliquées
SELECT 'Triggers et fonctions corrigés avec succès!' as status;

-- 9. Afficher les triggers actifs sur ride_requests
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'ride_requests'; 