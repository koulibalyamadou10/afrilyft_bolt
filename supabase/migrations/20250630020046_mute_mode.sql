/*
  # Add driver document verification system

  1. New Tables
    - `driver_documents`
      - `id` (uuid, primary key)
      - `driver_id` (uuid, foreign key to profiles)
      - `document_type` (text, enum: license, insurance, vehicle_registration)
      - `document_url` (text, file storage URL)
      - `status` (text, enum: pending, approved, rejected)
      - `verified_at` (timestamp)
      - `expires_at` (timestamp)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `driver_documents` table
    - Add policies for document access

  3. Constraints
    - Add check constraints for document types and status
*/

-- Create document types enum
DO $$ BEGIN
  CREATE TYPE document_type AS ENUM ('license', 'insurance', 'vehicle_registration', 'vehicle_inspection');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE document_status AS ENUM ('pending', 'approved', 'rejected', 'expired');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create driver documents table
CREATE TABLE IF NOT EXISTS driver_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type document_type NOT NULL,
  document_url text NOT NULL,
  status document_status DEFAULT 'pending',
  verified_at timestamptz,
  expires_at timestamptz,
  rejection_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Ensure one active document per type per driver
  UNIQUE(driver_id, document_type)
);

-- Enable RLS
ALTER TABLE driver_documents ENABLE ROW LEVEL SECURITY;

-- Add indexes
CREATE INDEX idx_driver_documents_driver ON driver_documents(driver_id);
CREATE INDEX idx_driver_documents_status ON driver_documents(status);
CREATE INDEX idx_driver_documents_expires ON driver_documents(expires_at) WHERE expires_at IS NOT NULL;

-- Add trigger for updated_at
CREATE TRIGGER update_driver_documents_updated_at
  BEFORE UPDATE ON driver_documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
CREATE POLICY "Drivers can manage own documents"
  ON driver_documents
  FOR ALL
  TO authenticated
  USING (driver_id = auth.uid())
  WITH CHECK (driver_id = auth.uid());

-- Function to check if driver has all required documents approved
CREATE OR REPLACE FUNCTION check_driver_documents_complete(driver_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  required_docs text[] := ARRAY['license', 'insurance', 'vehicle_registration'];
  doc_type text;
  approved_count integer := 0;
BEGIN
  FOREACH doc_type IN ARRAY required_docs
  LOOP
    IF EXISTS (
      SELECT 1 FROM driver_documents 
      WHERE driver_id = driver_uuid 
      AND document_type = doc_type::document_type 
      AND status = 'approved'
      AND (expires_at IS NULL OR expires_at > now())
    ) THEN
      approved_count := approved_count + 1;
    END IF;
  END LOOP;
  
  RETURN approved_count = array_length(required_docs, 1);
END;
$$;