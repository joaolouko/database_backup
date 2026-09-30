-- 03_mass_data.sql
DO $$ 
BEGIN 
    FOR i IN 1..1000 LOOP 
        INSERT INTO usuarios (nome, email) VALUES ('User ' || i, 'user' || i || '@example.com'); 
    END LOOP; 
END $$;
