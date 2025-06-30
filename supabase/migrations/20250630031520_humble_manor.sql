/*
  # Fix infinite recursion in rides policy

  1. Changes
     - Fixes the infinite recursion detected in policy for relation 'rides'
     - Replaces recursive policy with direct conditions
     - Ensures proper access control without circular references
*/

-- First, drop the problematic policies
DROP POLICY IF EXISTS "Customers can manage own rides" ON public.rides;
DROP POLICY IF EXISTS "Drivers can read assigned or requested rides" ON public.rides;
DROP POLICY IF EXISTS "Drivers can update assigned rides" ON public.rides;

-- Create new non-recursive policies
CREATE POLICY "Customers can manage own rides" 
ON public.rides
FOR ALL 
TO authenticated
USING (customer_id = auth.uid());

-- Drivers can read rides assigned to them
CREATE POLICY "Drivers can read assigned rides" 
ON public.rides
FOR SELECT 
TO authenticated
USING (driver_id = auth.uid());

-- Drivers can read rides requested to them (via ride_requests)
CREATE POLICY "Drivers can read requested rides" 
ON public.rides
FOR SELECT 
TO authenticated
USING (
  id IN (
    SELECT ride_id FROM ride_requests 
    WHERE driver_id = auth.uid()
  )
);

-- Drivers can update only rides assigned to them
CREATE POLICY "Drivers can update assigned rides" 
ON public.rides
FOR UPDATE 
TO authenticated
USING (driver_id = auth.uid());