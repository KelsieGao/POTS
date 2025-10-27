/*
  Create Patient Authentication Tables
  
  This script creates all the required tables for patient authentication.
  Run this in your Supabase SQL Editor.
*/

-- 1. Create patient_auth table for authentication
CREATE TABLE IF NOT EXISTS patient_auth (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  verification_code TEXT,
  verification_code_expires_at TIMESTAMPTZ,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create physician_codes table for 6-digit codes
CREATE TABLE IF NOT EXISTS physician_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  physician_name TEXT NOT NULL,
  physician_institution TEXT,
  physician_email TEXT,
  created_by UUID,
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create physician_patient_links table
CREATE TABLE IF NOT EXISTS physician_patient_links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  physician_code TEXT NOT NULL REFERENCES physician_codes(code),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  linked_by UUID,
  linked_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'removed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(physician_code, patient_id)
);

-- Enable RLS
ALTER TABLE patient_auth ENABLE ROW LEVEL SECURITY;
ALTER TABLE physician_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE physician_patient_links ENABLE ROW LEVEL SECURITY;

-- Policies for patient_auth
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'patient_auth' AND policyname = 'Users can view own auth') THEN
    CREATE POLICY "Users can view own auth"
      ON patient_auth FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'patient_auth' AND policyname = 'Users can insert own auth') THEN
    CREATE POLICY "Users can insert own auth"
      ON patient_auth FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'patient_auth' AND policyname = 'Users can update own auth') THEN
    CREATE POLICY "Users can update own auth"
      ON patient_auth FOR UPDATE
      USING (true);
  END IF;
END $$;

-- Policies for physician_codes
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'physician_codes' AND policyname = 'Anyone can view active physician codes') THEN
    CREATE POLICY "Anyone can view active physician codes"
      ON physician_codes FOR SELECT
      USING (is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW()));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'physician_codes' AND policyname = 'Anyone can manage physician codes') THEN
    CREATE POLICY "Anyone can manage physician codes"
      ON physician_codes FOR ALL
      USING (true);
  END IF;
END $$;

-- Policies for physician_patient_links
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'physician_patient_links' AND policyname = 'Patients can view own links') THEN
    CREATE POLICY "Patients can view own links"
      ON physician_patient_links FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'physician_patient_links' AND policyname = 'Patients can create own links') THEN
    CREATE POLICY "Patients can create own links"
      ON physician_patient_links FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'physician_patient_links' AND policyname = 'Patients can update own links') THEN
    CREATE POLICY "Patients can update own links"
      ON physician_patient_links FOR UPDATE
      USING (true);
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_patient_auth_email ON patient_auth(email);
CREATE INDEX IF NOT EXISTS idx_patient_auth_patient_id ON patient_auth(patient_id);
CREATE INDEX IF NOT EXISTS idx_physician_codes_code ON physician_codes(code);
CREATE INDEX IF NOT EXISTS idx_physician_patient_links_patient_id ON physician_patient_links(patient_id);
CREATE INDEX IF NOT EXISTS idx_physician_patient_links_code ON physician_patient_links(physician_code);

-- Trigger for updated_at (if not already exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_patient_auth_updated_at') THEN
    CREATE TRIGGER update_patient_auth_updated_at
      BEFORE UPDATE ON patient_auth
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_physician_codes_updated_at') THEN
    CREATE TRIGGER update_physician_codes_updated_at
      BEFORE UPDATE ON physician_codes
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_physician_patient_links_updated_at') THEN
    CREATE TRIGGER update_physician_patient_links_updated_at
      BEFORE UPDATE ON physician_patient_links
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Grant permissions
GRANT ALL ON patient_auth TO anon, authenticated;
GRANT ALL ON physician_codes TO anon, authenticated;
GRANT ALL ON physician_patient_links TO anon, authenticated;

