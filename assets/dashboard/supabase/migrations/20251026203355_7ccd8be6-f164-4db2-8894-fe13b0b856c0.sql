-- Create clinician_profiles table with join codes
CREATE TABLE public.clinician_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  join_code TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  specialty TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.clinician_profiles ENABLE ROW LEVEL SECURITY;

-- Clinicians can view and update their own profile
CREATE POLICY "Clinicians can view own profile"
  ON public.clinician_profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Clinicians can update own profile"
  ON public.clinician_profiles
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Clinicians can insert own profile"
  ON public.clinician_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Function to generate unique join code
CREATE OR REPLACE FUNCTION public.generate_join_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create clinician profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_clinician()
RETURNS TRIGGER AS $$
DECLARE
  new_join_code TEXT;
BEGIN
  -- Generate unique join code
  LOOP
    new_join_code := generate_join_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.clinician_profiles WHERE join_code = new_join_code);
  END LOOP;
  
  INSERT INTO public.clinician_profiles (id, join_code, first_name, last_name)
  VALUES (
    NEW.id, 
    new_join_code,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_clinician_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_clinician();

-- Add clinician_id to patients table
ALTER TABLE public.patients
ADD COLUMN clinician_id UUID REFERENCES public.clinician_profiles(id);

-- Update patients RLS to include clinician access
CREATE POLICY "Clinicians can view their patients"
  ON public.patients
  FOR SELECT
  USING (auth.uid() = clinician_id);

-- Create notifications table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinician_id UUID NOT NULL REFERENCES public.clinician_profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clinicians can view own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = clinician_id);

CREATE POLICY "Clinicians can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = clinician_id);

-- Create blood pressure continuous monitoring table
CREATE TABLE public.bp_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES public.patients(id),
  device_id TEXT NOT NULL,
  systolic INTEGER NOT NULL,
  diastolic INTEGER NOT NULL,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.bp_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for testing"
  ON public.bp_data
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Function to create notification when patient joins
CREATE OR REPLACE FUNCTION public.notify_patient_joined()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.clinician_id IS NOT NULL AND (OLD.clinician_id IS NULL OR OLD.clinician_id != NEW.clinician_id) THEN
    INSERT INTO public.notifications (clinician_id, type, title, message, patient_id)
    VALUES (
      NEW.clinician_id,
      'patient_joined',
      'New Patient Added',
      'Patient ' || NEW.first_name || ' ' || NEW.last_name || ' has joined your practice',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_patient_clinician_assigned
  AFTER UPDATE OF clinician_id ON public.patients
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_patient_joined();