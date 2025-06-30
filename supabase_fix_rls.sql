-- Solution temporaire : Désactiver RLS sur la table rides
ALTER TABLE rides DISABLE ROW LEVEL SECURITY;

-- Ou créer une politique simple qui permet tout
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON rides;
CREATE POLICY "Enable all access for authenticated users" ON rides
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Réactiver RLS
ALTER TABLE rides ENABLE ROW LEVEL SECURITY; 