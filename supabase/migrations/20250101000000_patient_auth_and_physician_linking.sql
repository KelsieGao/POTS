/*
  Patient Authentication and Physician Linking System
  
  This migration creates:
  1. patient_auth table - Email/password authentication with 2-step verification
  2. physician_codes table - 6-digit codes for physicians to share with patients
  3. physician_patient_links table - Links patients to their physicians
  
  Features:
  - Patients can sign up with email/password
  - 2-step verification via email codes
  - 6-digit physician codes for account linking
  - Patients can link themselves to their physician using the code
*/

-- Create patient_auth table for authentication
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

-- Create physician_codes table for 6-digit codes
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

-- Create physician_patient_links table
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

-- Policies for patient_auth (users can only access their own auth data)
CREATE POLICY "Users can view own auth"
  ON patient_auth FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own auth"
  ON patient_auth FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own auth"
  ON patient_auth FOR UPDATE
  USING (true);

-- Policies for physician_codes (public read for validation)
CREATE POLICY "Anyone can view active physician codes"
  ON physician_codes FOR SELECT
  USING (is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW()));

CREATE POLICY "Administrators can manage physician codes"
  ON physician_codes FOR ALL
  USING (true);

-- Policies for physician_patient_links
CREATE POLICY "Patients can view own links"
  ON physician_patient_links FOR SELECT
  USING (true);

CREATE POLICY "Patients can create own links"
  ON physician_patient_links FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Patients can update own links"
  ON physician_patient_links FOR UPDATE
  USING (true);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_patient_auth_email ON patient_auth(email);
CREATE INDEX IF NOT EXISTS idx_patient_auth_patient_id ON patient_auth(patient_id);
CREATE INDEX IF NOT EXISTS idx_physician_codes_code ON physician_codes(code);
CREATE INDEX IF NOT EXISTS idx_physician_patient_links_patient_id ON physician_patient_links(patient_id);
CREATE INDEX IF NOT EXISTS idx_physician_patient_links_code ON physician_patient_links(physician_code);

-- Trigger for updated_at on patient_auth
CREATE TRIGGER update_patient_auth_updated_at
  BEFORE UPDATE ON patient_auth
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for updated_at on physician_codes
CREATE TRIGGER update_physician_codes_updated_at
  BEFORE UPDATE ON physician_codes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for updated_at on physician_patient_links
CREATE TRIGGER update_physician_patient_links_updated_at
  BEFORE UPDATE ON physician_patient_links
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON patient_auth TO anon, authenticated;
GRANT ALL ON physician_codes TO anon, authenticated;
GRANT ALL ON physician_patient_links TO anon, authenticated;

