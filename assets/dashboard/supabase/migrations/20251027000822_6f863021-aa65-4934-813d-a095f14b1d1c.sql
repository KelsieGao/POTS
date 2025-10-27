-- Update all existing join codes to 6-digit numeric format
DO $$
DECLARE
  clinician_record RECORD;
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  FOR clinician_record IN SELECT id FROM clinician_profiles
  LOOP
    LOOP
      -- Generate a random 6-digit number
      new_code := LPAD(floor(random() * 900000 + 100000)::text, 6, '0');
      
      -- Check if code already exists
      SELECT EXISTS(
        SELECT 1 FROM clinician_profiles WHERE join_code = new_code
      ) INTO code_exists;
      
      -- If code doesn't exist, use it
      IF NOT code_exists THEN
        UPDATE clinician_profiles 
        SET join_code = new_code 
        WHERE id = clinician_record.id;
        EXIT;
      END IF;
    END LOOP;
  END LOOP;
END $$;