-- Test simple de création de trajet après correction RLS
-- Exécutez ce script dans l'éditeur SQL de Supabase

-- 1. Vérifier l'utilisateur connecté
SELECT auth.uid() as current_user_id;

-- 2. Vérifier que l'utilisateur a un profil
SELECT id, email, full_name, role FROM profiles WHERE id = auth.uid();

-- 3. Test de création d'un trajet simple (sans jointures)
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
LIMIT 3;

-- 5. Vérifier les politiques RLS actives sur rides
SELECT 
  policyname,
  permissive,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'rides'
ORDER BY policyname;

-- 6. Nettoyer le test (optionnel)
-- DELETE FROM rides WHERE customer_id = auth.uid() AND status = 'searching'; 