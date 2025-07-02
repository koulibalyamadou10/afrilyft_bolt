/*
  # Fix infinite recursion in RLS policies

  1. Problem
     - Infinite recursion detected in policy for relation "rides"
     - Caused by circular references between rides and ride_requests policies

  2. Solution
     - Remove all problematic policies
     - Create new non-recursive policies
     - Ensure proper access control without circular references
*/

-- 1. Temporarily disable RLS on all tables
ALTER TABLE rides DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 2. Drop all problematic policies
-- Rides policies
DROP POLICY IF EXISTS "Customers can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned or requested rides" ON rides;
DROP POLICY IF EXISTS "Drivers can update assigned rides" ON rides;
DROP POLICY IF EXISTS "Users can manage own rides" ON rides;
DROP POLICY IF EXISTS "Drivers can read assigned rides" ON rides;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON rides;

-- Ride requests policies
DROP POLICY IF EXISTS "Customers can read ride requests for their rides" ON ride_requests;
DROP POLICY IF EXISTS "Drivers can manage own ride requests" ON ride_requests;
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON ride_requests;

-- Profiles policies
DROP POLICY IF EXISTS "Users can read other profiles for rides" ON profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Driver locations policies
DROP POLICY IF EXISTS "Drivers can manage own location" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read available driver locations" ON driver_locations;
DROP POLICY IF EXISTS "Customers can read driver locations" ON driver_locations;

-- 3. Create new non-recursive policies

-- PROFILES POLICIES
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow drivers to be visible by all authenticated users
CREATE POLICY "Users can read driver profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (role = 'driver');

-- RIDES POLICIES (NON-RECURSIVE)
-- Customers can manage their own rides
CREATE POLICY "Customers can manage own rides"
  ON rides FOR ALL
  TO authenticated
  USING (customer_id = auth.uid());

-- Drivers can see rides assigned to them
CREATE POLICY "Drivers can read assigned rides"
  ON rides FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid());

-- Drivers can update rides assigned to them
CREATE POLICY "Drivers can update assigned rides"
  ON rides FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

-- Drivers can see searching rides (to accept)
CREATE POLICY "Drivers can read searching rides"
  ON rides FOR SELECT
  TO authenticated
  USING (
    status = 'searching' 
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'driver'
    )
  );

-- RIDE_REQUESTS POLICIES (NON-RECURSIVE)
-- Drivers can manage their own requests
CREATE POLICY "Drivers can manage own ride requests"
  ON ride_requests FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

-- Customers can see requests for their rides (without recursion)
CREATE POLICY "Customers can read ride requests for their rides"
  ON ride_requests FOR SELECT
  TO authenticated
  USING (
    ride_id IN (
      SELECT id FROM rides WHERE customer_id = auth.uid()
    )
  );

-- DRIVER_LOCATIONS POLICIES
-- Drivers can manage their own location
CREATE POLICY "Drivers can manage own location"
  ON driver_locations FOR ALL
  TO authenticated
  USING (driver_id = auth.uid());

-- Customers can see available driver locations
CREATE POLICY "Customers can read available driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    is_available = true
    AND EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'customer'
    )
  );

-- NOTIFICATIONS POLICIES
-- Users can manage their own notifications
CREATE POLICY "Users can manage own notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- 4. Re-enable RLS on all tables
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY; 