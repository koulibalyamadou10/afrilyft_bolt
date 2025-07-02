-- Test de la fonctionnalité de timeout des trajets
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- 1. Vérifier l'utilisateur connecté
SELECT auth.uid() as current_user_id;

-- 2. Créer un trajet de test
INSERT INTO rides (
  customer_id,
  pickup_latitude,
  pickup_longitude,
  pickup_address,
  destination_latitude,
  destination_longitude,
  destination_address,
  status,
  payment_method
) VALUES (
  auth.uid(),
  9.5370,
  -13.6785,
  'Conakry, Guinée - Point de départ',
  9.5370,
  -13.6785,
  'Conakry, Guinée - Destination',
  'searching',
  'cash'
) RETURNING id, customer_id, status, created_at;

-- 3. Vérifier que le trajet a été créé
SELECT 
  id,
  customer_id,
  status,
  created_at,
  now() - created_at as elapsed_time
FROM rides 
WHERE customer_id = auth.uid()
AND status = 'searching'
ORDER BY created_at DESC
LIMIT 1;

-- 4. Simuler un trajet expiré (en modifiant la date de création)
-- ATTENTION: Ceci est pour le test seulement
UPDATE rides 
SET created_at = now() - interval '3 minutes'
WHERE customer_id = auth.uid()
AND status = 'searching'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Vérifier les trajets expirés
SELECT 
  id,
  customer_id,
  status,
  created_at,
  now() - created_at as elapsed_time
FROM rides 
WHERE status = 'searching'
AND created_at < (now() - interval '2 minutes');

-- 6. Tester la fonction de nettoyage manuel
SELECT * FROM manual_cleanup_expired_rides();

-- 7. Vérifier que les trajets expirés ont été supprimés
SELECT 
  id,
  customer_id,
  status,
  created_at
FROM rides 
WHERE customer_id = auth.uid()
ORDER BY created_at DESC
LIMIT 5;

-- 8. Nettoyer les données de test (optionnel)
-- DELETE FROM rides WHERE customer_id = auth.uid() AND status = 'searching'; 