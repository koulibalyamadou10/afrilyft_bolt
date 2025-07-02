-- Script de test pour vérifier que la création de trajets fonctionne
-- Exécutez ce script après avoir appliqué la correction RLS

-- 1. Vérifier que l'utilisateur est authentifié
SELECT auth.uid() as current_user_id;

-- 2. Vérifier que l'utilisateur a un profil
SELECT * FROM profiles WHERE id = auth.uid();

-- 3. Test de création d'un trajet simple
INSERT INTO rides (
  customer_id,
  pickup_latitude,
  pickup_longitude,
  pickup_address,
  destination_latitude,
  destination_longitude,
  destination_address,
  status,
  payment_method,
  distance_km,
  estimated_duration_minutes
) VALUES (
  auth.uid(),
  9.5370,
  -13.6785,
  'Conakry, Guinée - Point de départ',
  9.5370,
  -13.6785,
  'Conakry, Guinée - Destination',
  'searching',
  'cash',
  5.0,
  12
) RETURNING id, customer_id, status, created_at;

-- 4. Vérifier que le trajet a été créé
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
LIMIT 5;

-- 5. Test de récupération des trajets de l'utilisateur
SELECT 
  r.id,
  r.pickup_address,
  r.destination_address,
  r.status,
  r.created_at,
  p.full_name as customer_name
FROM rides r
JOIN profiles p ON p.id = r.customer_id
WHERE r.customer_id = auth.uid()
ORDER BY r.created_at DESC;

-- 6. Vérifier les politiques RLS actives
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'rides'
ORDER BY policyname;

-- 7. Nettoyer le test (optionnel)
-- DELETE FROM rides WHERE customer_id = auth.uid() AND status = 'searching'; 