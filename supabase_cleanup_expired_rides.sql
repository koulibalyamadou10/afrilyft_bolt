-- Script pour nettoyer automatiquement les trajets expirés
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- Fonction pour nettoyer les trajets expirés
CREATE OR REPLACE FUNCTION cleanup_expired_rides()
RETURNS void AS $$
BEGIN
  -- Supprimer les demandes de trajet pour les trajets expirés
  DELETE FROM ride_requests 
  WHERE ride_id IN (
    SELECT id FROM rides 
    WHERE status = 'searching' 
    AND created_at < (now() - interval '2 minutes')
  );
  
  -- Supprimer les trajets expirés
  DELETE FROM rides 
  WHERE status = 'searching' 
  AND created_at < (now() - interval '2 minutes');
  
  -- Log du nettoyage
  RAISE NOTICE 'Nettoyage des trajets expirés terminé';
END;
$$ LANGUAGE plpgsql;

-- Fonction trigger pour nettoyer automatiquement
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_rides()
RETURNS trigger AS $$
BEGIN
  -- Nettoyer les trajets expirés
  PERFORM cleanup_expired_rides();
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour nettoyer automatiquement après chaque insertion de trajet
DROP TRIGGER IF EXISTS cleanup_expired_rides_trigger ON rides;
CREATE TRIGGER cleanup_expired_rides_trigger
  AFTER INSERT ON rides
  FOR EACH STATEMENT
  EXECUTE FUNCTION trigger_cleanup_expired_rides();

-- Fonction pour nettoyer manuellement (à exécuter périodiquement)
CREATE OR REPLACE FUNCTION manual_cleanup_expired_rides()
RETURNS TABLE(
  deleted_rides integer,
  deleted_requests integer
) AS $$
DECLARE
  v_deleted_requests integer;
  v_deleted_rides integer;
BEGIN
  -- Compter et supprimer les demandes de trajet pour les trajets expirés
  SELECT COUNT(*) INTO v_deleted_requests
  FROM ride_requests 
  WHERE ride_id IN (
    SELECT id FROM rides 
    WHERE status = 'searching' 
    AND created_at < (now() - interval '2 minutes')
  );
  
  DELETE FROM ride_requests 
  WHERE ride_id IN (
    SELECT id FROM rides 
    WHERE status = 'searching' 
    AND created_at < (now() - interval '2 minutes')
  );
  
  -- Compter et supprimer les trajets expirés
  SELECT COUNT(*) INTO v_deleted_rides
  FROM rides 
  WHERE status = 'searching' 
  AND created_at < (now() - interval '2 minutes');
  
  DELETE FROM rides 
  WHERE status = 'searching' 
  AND created_at < (now() - interval '2 minutes');
  
  RETURN QUERY SELECT v_deleted_rides, v_deleted_requests;
END;
$$ LANGUAGE plpgsql;

-- Test de la fonction de nettoyage
-- SELECT * FROM manual_cleanup_expired_rides();

-- Vérifier les trajets qui vont expirer bientôt
-- SELECT 
--   id,
--   customer_id,
--   status,
--   created_at,
--   now() - created_at as elapsed_time
-- FROM rides 
-- WHERE status = 'searching'
-- ORDER BY created_at DESC; 