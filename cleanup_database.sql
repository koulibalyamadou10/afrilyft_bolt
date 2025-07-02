-- Script pour nettoyer les données problématiques
-- À exécuter dans la console SQL de Supabase APRÈS avoir exécuté fix_recursion_error.sql

-- 1. Nettoyer les trajets en statut 'searching' depuis plus de 2 minutes
UPDATE rides 
SET 
  status = 'cancelled',
  cancelled_at = now()
WHERE 
  status = 'searching'
  AND created_at < (now() - interval '2 minutes');

-- 2. Nettoyer les demandes expirées
UPDATE ride_requests 
SET status = 'expired'
WHERE status = 'sent' AND expires_at < now();

-- 3. Nettoyer les demandes pour les trajets annulés
UPDATE ride_requests 
SET status = 'expired'
WHERE status = 'sent' 
AND ride_id IN (
  SELECT id FROM rides WHERE status = 'cancelled'
);

-- 4. Vérifier l'état de la base de données
SELECT 
  'Rides status count:' as info,
  status,
  count(*) as count
FROM rides 
GROUP BY status
ORDER BY status;

SELECT 
  'Ride requests status count:' as info,
  status,
  count(*) as count
FROM ride_requests 
GROUP BY status
ORDER BY status;

-- 5. Afficher les trajets récents pour vérification
SELECT 
  id,
  status,
  created_at,
  cancelled_at
FROM rides 
WHERE created_at > (now() - interval '1 hour')
ORDER BY created_at DESC
LIMIT 10; 