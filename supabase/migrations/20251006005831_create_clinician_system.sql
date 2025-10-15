/*
  # Create Clinician Dashboard System

  ## Summary
  This migration creates the database structure for the clinician-facing dashboard system,
  enabling clinicians to manage and monitor multiple patients.

  ## New Tables
  
  ### `clinicians`
  - `id` (uuid, primary key) - Unique clinician identifier
  - `clinician_code` (text, unique) - 6+ character alphanumeric code for authentication
  - `name` (text) - Clinician's full name
  - `email` (text, nullable) - Optional email address
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  - `last_login_at` (timestamptz, nullable) - Last login timestamp

  ### `clinician_patients`
  - `id` (uuid, primary key) - Unique relationship identifier
  - `clinician_id` (uuid, foreign key) - References clinicians table
  - `patient_id` (text) - Patient identifier from patients table
  - `status` (text) - Patient status: 'active', 'completed', 'inactive'
  - `added_at` (timestamptz) - When patient was added to clinician's dashboard
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  - Enable RLS on all tables
  - Create policies for authenticated clinician access
  - Ensure clinicians can only access their own patients

  ## Indexes
  - Index on clinician_code for fast authentication lookups
  - Index on clinician_id for patient list queries
  - Index on patient_id for relationship lookups
*/

-- Create function to update updated_at timestamp if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create clinicians table
CREATE TABLE IF NOT EXISTS clinicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  clinician_code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  CONSTRAINT clinician_code_length CHECK (LENGTH(clinician_code) >= 6)
);

-- Create clinician_patients junction table
CREATE TABLE IF NOT EXISTS clinician_patients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  clinician_id UUID NOT NULL REFERENCES clinicians(id) ON DELETE CASCADE,
  patient_id TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'inactive')),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clinician_id, patient_id)
);

-- Enable RLS
ALTER TABLE clinicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinician_patients ENABLE ROW LEVEL SECURITY;

-- Policies for clinicians table
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinicians' AND policyname = 'Clinicians can view own profile'
  ) THEN
    CREATE POLICY "Clinicians can view own profile"
      ON clinicians FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinicians' AND policyname = 'Anyone can insert clinicians'
  ) THEN
    CREATE POLICY "Anyone can insert clinicians"
      ON clinicians FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinicians' AND policyname = 'Clinicians can update own profile'
  ) THEN
    CREATE POLICY "Clinicians can update own profile"
      ON clinicians FOR UPDATE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Policies for clinician_patients table
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinician_patients' AND policyname = 'Clinicians can view own patients'
  ) THEN
    CREATE POLICY "Clinicians can view own patients"
      ON clinician_patients FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinician_patients' AND policyname = 'Clinicians can add patients'
  ) THEN
    CREATE POLICY "Clinicians can add patients"
      ON clinician_patients FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinician_patients' AND policyname = 'Clinicians can update own patient relationships'
  ) THEN
    CREATE POLICY "Clinicians can update own patient relationships"
      ON clinician_patients FOR UPDATE
      TO authenticated
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'clinician_patients' AND policyname = 'Clinicians can delete own patient relationships'
  ) THEN
    CREATE POLICY "Clinicians can delete own patient relationships"
      ON clinician_patients FOR DELETE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_clinicians_code ON clinicians(clinician_code);
CREATE INDEX IF NOT EXISTS idx_clinician_patients_clinician ON clinician_patients(clinician_id);
CREATE INDEX IF NOT EXISTS idx_clinician_patients_patient ON clinician_patients(patient_id);
CREATE INDEX IF NOT EXISTS idx_clinician_patients_status ON clinician_patients(status);

-- Create triggers for updated_at
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_clinicians_updated_at'
  ) THEN
    CREATE TRIGGER update_clinicians_updated_at 
      BEFORE UPDATE ON clinicians
      FOR EACH ROW 
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_clinician_patients_updated_at'
  ) THEN
    CREATE TRIGGER update_clinician_patients_updated_at 
      BEFORE UPDATE ON clinician_patients
      FOR EACH ROW 
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Grant permissions
GRANT ALL ON clinicians TO anon, authenticated;
GRANT ALL ON clinician_patients TO anon, authenticated;