-- SOLUTION D'URGENCE : Désactiver complètement RLS sur toutes les tables
-- Exécutez ce code dans l'éditeur SQL de Supabase

-- 1. Désactiver RLS sur toutes les tables
ALTER TABLE rides DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques existantes sur rides
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON rides;
DROP POLICY IF EXISTS "Users can create their own rides" ON rides;
DROP POLICY IF EXISTS "Users can view their own rides" ON rides;
DROP POLICY IF EXISTS "Users can update their own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can view available rides" ON rides;
DROP POLICY IF EXISTS "Drivers can update accepted rides" ON rides;
DROP POLICY IF EXISTS "Enable read access for all users" ON rides;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON rides;
DROP POLICY IF EXISTS "Enable update for users based on email" ON rides;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON rides;

-- 3. Supprimer toutes les politiques sur profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON profiles;

-- 4. Supprimer toutes les politiques sur ride_requests
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON ride_requests;
DROP POLICY IF EXISTS "Enable read access for all users" ON ride_requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON ride_requests;
DROP POLICY IF EXISTS "Enable update for users based on email" ON ride_requests;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON ride_requests;

-- 5. Supprimer toutes les politiques sur driver_locations
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON driver_locations;
DROP POLICY IF EXISTS "Enable read access for all users" ON driver_locations;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON driver_locations;
DROP POLICY IF EXISTS "Enable update for users based on email" ON driver_locations;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON driver_locations;

-- 6. Supprimer toutes les politiques sur notifications
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON notifications;
DROP POLICY IF EXISTS "Enable read access for all users" ON notifications;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON notifications;
DROP POLICY IF EXISTS "Enable update for users based on email" ON notifications;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON notifications;

-- 7. Vérifier que RLS est bien désactivé
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('rides', 'profiles', 'ride_requests', 'driver_locations', 'notifications'); 