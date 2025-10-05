-- POTS App Database Schema (SAFE VERSION)
-- Run this in your Supabase SQL editor to set up the required tables

-- Drop existing tables if they exist (to start fresh)
DROP TABLE IF EXISTS symptom_logs CASCADE;
DROP TABLE IF EXISTS symptoms CASCADE;

-- Enable Row Level Security
ALTER TABLE IF EXISTS patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS heart_rate_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS standup_tests ENABLE ROW LEVEL SECURITY;

-- Create symptoms table
CREATE TABLE symptoms (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    emoji TEXT NOT NULL,
    is_custom BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptom_logs table
CREATE TABLE symptom_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    symptoms TEXT[] NOT NULL,
    severity INTEGER NOT NULL CHECK (severity >= 1 AND severity <= 10),
    time_of_day TEXT,
    activity_type TEXT,
    other_details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptom_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for symptoms table (public read access)
CREATE POLICY "Symptoms are viewable by everyone" ON symptoms
    FOR SELECT USING (true);

CREATE POLICY "Symptoms are insertable by everyone" ON symptoms
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Symptoms are updatable by everyone" ON symptoms
    FOR UPDATE USING (true);

-- Create policies for symptom_logs table (public access for now)
CREATE POLICY "Anyone can view symptom logs" ON symptom_logs
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert symptom logs" ON symptom_logs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update symptom logs" ON symptom_logs
    FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete symptom logs" ON symptom_logs
    FOR DELETE USING (true);

-- Insert predefined symptoms
INSERT INTO symptoms (id, name, emoji, is_custom) VALUES
    ('dizziness', 'Dizziness', '😵‍💫', false),
    ('lightheaded', 'Lightheaded', '🤯', false),
    ('fatigue', 'Fatigue', '😴', false),
    ('palpitations', 'Palpitations', '💗', false),
    ('chest_pain', 'Chest Pain', '❤️', false),
    ('shortness_breath', 'Shortness of Breath', '🫁', false),
    ('nausea', 'Nausea', '🤢', false),
    ('headache', 'Headache', '🤕', false),
    ('brain_fog', 'Brain Fog', '☁️', false),
    ('tremor', 'Tremor/Shaking', '🤲', false),
    ('heat_intolerance', 'Heat Intolerance', '🌡️', false),
    ('exercise_intolerance', 'Exercise Intolerance', '🏃‍♀️', false),
    ('sleep_issues', 'Sleep Issues', '😵', false),
    ('digestive_issues', 'Digestive Issues', '🤮', false),
    ('anxiety', 'Anxiety', '😰', false)
ON CONFLICT (id) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_symptom_logs_patient_id ON symptom_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_symptom_logs_timestamp ON symptom_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_symptom_logs_created_at ON symptom_logs(created_at);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_symptoms_updated_at BEFORE UPDATE ON symptoms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_symptom_logs_updated_at BEFORE UPDATE ON symptom_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
