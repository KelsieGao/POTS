-- Update the generate_join_code function to create 6-digit numeric codes
CREATE OR REPLACE FUNCTION generate_join_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  new_code text;
  code_exists boolean;
BEGIN
  LOOP
    -- Generate a random 6-digit number (100000 to 999999)
    new_code := LPAD(floor(random() * 900000 + 100000)::text, 6, '0');
    
    -- Check if code already exists
    SELECT EXISTS(
      SELECT 1 FROM clinician_profiles WHERE join_code = new_code
    ) INTO code_exists;
    
    -- If code doesn't exist, return it
    IF NOT code_exists THEN
      RETURN new_code;
    END IF;
  END LOOP;
END;
$$;