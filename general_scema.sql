-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.driver_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL,
  document_type USER-DEFINED NOT NULL,
  document_url text NOT NULL,
  status USER-DEFINED DEFAULT 'pending'::document_status,
  verified_at timestamp with time zone,
  expires_at timestamp with time zone,
  rejection_reason text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT driver_documents_pkey PRIMARY KEY (id)
);
CREATE TABLE public.driver_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid UNIQUE,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  heading real,
  speed real,
  is_available boolean DEFAULT true,
  last_updated timestamp with time zone DEFAULT now(),
  CONSTRAINT driver_locations_pkey PRIMARY KEY (id),
  CONSTRAINT driver_locations_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['ride_request'::text, 'ride_update'::text, 'payment'::text, 'general'::text])),
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.payment_methods (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  type USER-DEFINED NOT NULL,
  provider text NOT NULL,
  last_four text,
  phone_number text,
  cardholder_name text,
  is_default boolean DEFAULT false,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payment_methods_pkey PRIMARY KEY (id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'customer'::text CHECK (role = ANY (ARRAY['customer'::text, 'driver'::text])),
  avatar_url text,
  is_active boolean DEFAULT true,
  is_verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.ride_ratings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL,
  rater_id uuid NOT NULL,
  rated_id uuid NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ride_ratings_pkey PRIMARY KEY (id)
);
CREATE TABLE public.ride_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ride_id uuid,
  driver_id uuid,
  status text NOT NULL DEFAULT 'sent'::text CHECK (status = ANY (ARRAY['sent'::text, 'seen'::text, 'accepted'::text, 'declined'::text, 'expired'::text])),
  sent_at timestamp with time zone DEFAULT now(),
  responded_at timestamp with time zone,
  expires_at timestamp with time zone DEFAULT (now() + '00:02:00'::interval),
  CONSTRAINT ride_requests_pkey PRIMARY KEY (id),
  CONSTRAINT ride_requests_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id),
  CONSTRAINT ride_requests_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.rides (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid,
  driver_id uuid,
  pickup_latitude numeric NOT NULL,
  pickup_longitude numeric NOT NULL,
  pickup_address text NOT NULL,
  destination_latitude numeric NOT NULL,
  destination_longitude numeric NOT NULL,
  destination_address text NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'searching'::text, 'accepted'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text])),
  fare_amount numeric,
  distance_km real,
  estimated_duration_minutes integer,
  payment_method text DEFAULT 'cash'::text,
  notes text,
  scheduled_for timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  accepted_at timestamp with time zone,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  cancelled_at timestamp with time zone,
  CONSTRAINT rides_pkey PRIMARY KEY (id),
  CONSTRAINT rides_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.profiles(id),
  CONSTRAINT rides_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.profiles(id)
);