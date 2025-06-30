-- Politiques RLS correctes pour la table rides

-- 1. Permettre aux clients de créer leurs propres trajets
DROP POLICY IF EXISTS "Users can create their own rides" ON rides;
CREATE POLICY "Users can create their own rides" ON rides
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = customer_id);

-- 2. Permettre aux clients de voir leurs propres trajets
DROP POLICY IF EXISTS "Users can view their own rides" ON rides;
CREATE POLICY "Users can view their own rides" ON rides
    FOR SELECT
    TO authenticated
    USING (auth.uid() = customer_id);

-- 3. Permettre aux clients de mettre à jour leurs propres trajets
DROP POLICY IF EXISTS "Users can update their own rides" ON rides;
CREATE POLICY "Users can update their own rides" ON rides
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = customer_id)
    WITH CHECK (auth.uid() = customer_id);

-- 4. Permettre aux chauffeurs de voir les trajets disponibles
DROP POLICY IF EXISTS "Drivers can view available rides" ON rides;
CREATE POLICY "Drivers can view available rides" ON rides
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'driver'
        )
        AND status = 'searching'
    );

-- 5. Permettre aux chauffeurs de mettre à jour les trajets qu'ils acceptent
DROP POLICY IF EXISTS "Drivers can update accepted rides" ON rides;
CREATE POLICY "Drivers can update accepted rides" ON rides
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'driver'
        )
        AND driver_id = auth.uid()
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'driver'
        )
        AND driver_id = auth.uid()
    ); 