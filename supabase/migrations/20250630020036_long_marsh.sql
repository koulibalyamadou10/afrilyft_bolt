/*
  # Add ride ratings and reviews system

  1. New Tables
    - `ride_ratings`
      - `id` (uuid, primary key)
      - `ride_id` (uuid, foreign key to rides)
      - `rater_id` (uuid, foreign key to profiles - who gave the rating)
      - `rated_id` (uuid, foreign key to profiles - who received the rating)
      - `rating` (integer, 1-5 scale)
      - `review` (text, optional comment)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `ride_ratings` table
    - Add policies for rating access and creation

  3. Indexes
    - Add indexes for efficient rating queries
*/

-- Create ride ratings table
CREATE TABLE IF NOT EXISTS ride_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  rater_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rated_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review text,
  created_at timestamptz DEFAULT now(),
  
  -- Ensure one rating per ride per rater
  UNIQUE(ride_id, rater_id)
);

-- Enable RLS
ALTER TABLE ride_ratings ENABLE ROW LEVEL SECURITY;

-- Add indexes
CREATE INDEX idx_ride_ratings_ride ON ride_ratings(ride_id);
CREATE INDEX idx_ride_ratings_rated ON ride_ratings(rated_id);
CREATE INDEX idx_ride_ratings_rater ON ride_ratings(rater_id);

-- RLS Policies
CREATE POLICY "Users can read ratings for their rides"
  ON ride_ratings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = ride_ratings.ride_id 
      AND (rides.customer_id = auth.uid() OR rides.driver_id = auth.uid())
    )
  );

CREATE POLICY "Users can create ratings for completed rides"
  ON ride_ratings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = rater_id
    AND EXISTS (
      SELECT 1 FROM rides 
      WHERE rides.id = ride_ratings.ride_id 
      AND rides.status = 'completed'
      AND (
        (rides.customer_id = auth.uid() AND rides.driver_id = rated_id) OR
        (rides.driver_id = auth.uid() AND rides.customer_id = rated_id)
      )
    )
  );

CREATE POLICY "Users can read their own ratings"
  ON ride_ratings
  FOR SELECT
  TO authenticated
  USING (rated_id = auth.uid());