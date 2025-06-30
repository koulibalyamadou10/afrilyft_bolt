/*
  # Fix handle_new_user trigger

  1. Changes
     - Fixes the handle_new_user trigger to properly create profiles
     - Ensures proper error handling in the trigger
     - Adds better logging for debugging
*/

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create the improved function
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the new user creation
  RAISE LOG 'Creating profile for new user: %', NEW.id;
  
  -- Insert the profile with proper error handling
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    phone,
    role,
    is_active,
    is_verified,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    true,
    false,
    now(),
    now()
  );
  
  RAISE LOG 'Profile created successfully for user: %', NEW.id;
  RETURN NEW;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error creating profile for user %: %', NEW.id, SQLERRM;
    -- Don't fail the user creation, just log the error
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user(); 