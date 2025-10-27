-- Add missing columns to symptom_logs table
-- This migration adds columns that are missing from the database but are used in the app

-- Add time_of_day column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'time_of_day'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN time_of_day TEXT;
    END IF;
END $$;

-- Add activity_type column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'activity_type'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN activity_type TEXT;
    END IF;
END $$;

-- Add other_details column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'other_details'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN other_details TEXT;
    END IF;
END $$;

-- Add is_pots_episode column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'is_pots_episode'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN is_pots_episode BOOLEAN;
    END IF;
END $$;

-- Add created_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'symptom_logs' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE symptom_logs 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add comments to document the columns
COMMENT ON COLUMN symptom_logs.time_of_day IS 'Time of day when symptoms occurred';
COMMENT ON COLUMN symptom_logs.activity_type IS 'Type of activity during symptoms (e.g., Standing, Walking)';
COMMENT ON COLUMN symptom_logs.other_details IS 'Additional details about the symptoms';
COMMENT ON COLUMN symptom_logs.is_pots_episode IS 'Indicates if the symptom log represents a POTS episode (symptoms due to postural changes)';

