/*
  # Fix ride_requests policies

  1. Changes
     - Fixes potential infinite recursion in ride_requests policies
     - Ensures proper access control without circular references
*/

-- First, drop the potentially problematic policies
DROP POLICY IF EXISTS "Customers can read ride requests for their rides" ON public.ride_requests;
DROP POLICY IF EXISTS "Drivers can manage own ride requests" ON public.ride_requests;

-- Create new non-recursive policies
-- Customers can read ride requests for their rides
CREATE POLICY "Customers can read ride requests for their rides" 
ON public.ride_requests
FOR SELECT 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM rides
    WHERE rides.id = ride_requests.ride_id 
    AND rides.customer_id = auth.uid()
  )
);

-- Drivers can manage own ride requests
CREATE POLICY "Drivers can manage own ride requests" 
ON public.ride_requests
FOR ALL
TO authenticated
USING (driver_id = auth.uid());