-- Test du nouveau flux de création de trajet
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- 1. Vérifier l'utilisateur connecté
SELECT auth.uid() as current_user_id;

-- 2. Vérifier que l'utilisateur a un profil
SELECT id, email, full_name, role FROM profiles WHERE id = auth.uid();

-- 3. Vérifier les chauffeurs disponibles
SELECT 
  dl.driver_id,
  dl.location_lat,
  dl.location_lon,
  dl.heading,
  dl.speed,
  dl.last_updated,
  p.full_name,
  p.phone
FROM driver_locations dl
JOIN profiles p ON dl.driver_id = p.id
WHERE dl.is_available = true
AND dl.last_updated > (now() - interval '10 minutes')
ORDER BY dl.last_updated DESC;

-- 4. Test de création d'un trajet avec recherche de chauffeurs
-- (Simulation de ce qui se passe dans l'app)
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

-- 5. Vérifier que le trajet a été créé
SELECT 
  id,
  customer_id,
  pickup_address,
  destination_address,
  status,
  created_at
FROM rides 
WHERE customer_id = auth.uid()
ORDER BY created_at DESC
LIMIT 1;

-- 6. Vérifier que les demandes ont été envoyées aux chauffeurs
SELECT 
  rr.id,
  rr.ride_id,
  rr.driver_id,
  rr.status,
  rr.sent_at,
  p.full_name as driver_name
FROM ride_requests rr
JOIN profiles p ON rr.driver_id = p.id
WHERE rr.ride_id IN (
  SELECT id FROM rides 
  WHERE customer_id = auth.uid()
  ORDER BY created_at DESC
  LIMIT 1
);

-- 7. Nettoyer les données de test (optionnel)
-- DELETE FROM ride_requests WHERE ride_id IN (
--   SELECT id FROM rides 
--   WHERE customer_id = auth.uid()
--   AND created_at > (now() - interval '5 minutes')
-- );
-- DELETE FROM rides WHERE customer_id = auth.uid() 
-- AND created_at > (now() - interval '5 minutes'); 