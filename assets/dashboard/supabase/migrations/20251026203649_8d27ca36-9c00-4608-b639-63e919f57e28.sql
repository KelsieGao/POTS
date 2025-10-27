-- Fix search_path for generate_join_code function
CREATE OR REPLACE FUNCTION public.generate_join_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- Fix search_path for existing functions
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.aggregate_hourly_heartrate()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO heartrate_hourly_summary (patient_id, hour_timestamp, avg_hr, min_hr, max_hr, sample_count, hr_variability)
    SELECT 
        patient_id,
        date_trunc('hour', recorded_at) as hour_timestamp,
        AVG(heart_rate) as avg_hr,
        MIN(heart_rate) as min_hr,
        MAX(heart_rate) as max_hr,
        COUNT(*) as sample_count,
        STDDEV(heart_rate) as hr_variability
    FROM heartrate_data
    WHERE recorded_at >= NOW() - INTERVAL '2 hours'
    GROUP BY patient_id, date_trunc('hour', recorded_at)
    ON CONFLICT (patient_id, hour_timestamp) 
    DO UPDATE SET
        avg_hr = EXCLUDED.avg_hr,
        min_hr = EXCLUDED.min_hr,
        max_hr = EXCLUDED.max_hr,
        sample_count = EXCLUDED.sample_count,
        hr_variability = EXCLUDED.hr_variability;
END;
$$;

CREATE OR REPLACE FUNCTION public.analyze_pots_indicators(patient_uuid uuid, days_back integer DEFAULT 7)
RETURNS TABLE(avg_hr_lying double precision, avg_hr_standing double precision, hr_increase_standing double precision, hr_variability double precision, pots_risk_score double precision)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(AVG(CASE WHEN acc.activity_type = 'lying' THEN hr.heart_rate END), 0) as avg_hr_lying,
        COALESCE(AVG(CASE WHEN acc.activity_type = 'standing' THEN hr.heart_rate END), 0) as avg_hr_standing,
        COALESCE(AVG(CASE WHEN acc.activity_type = 'standing' THEN hr.heart_rate END), 0) - 
        COALESCE(AVG(CASE WHEN acc.activity_type = 'lying' THEN hr.heart_rate END), 0) as hr_increase_standing,
        STDDEV(hr.heart_rate) as hr_variability,
        LEAST(100, GREATEST(0, 
            (COALESCE(AVG(CASE WHEN acc.activity_type = 'standing' THEN hr.heart_rate END), 0) - 
             COALESCE(AVG(CASE WHEN acc.activity_type = 'lying' THEN hr.heart_rate END), 0)) * 0.5 +
            STDDEV(hr.heart_rate) * 0.3
        )) as pots_risk_score
    FROM heartrate_data hr
    LEFT JOIN accelerometer_data acc ON hr.patient_id = acc.patient_id 
        AND ABS(EXTRACT(EPOCH FROM (hr.recorded_at - acc.recorded_at))) < 5
    WHERE hr.patient_id = patient_uuid
        AND hr.recorded_at >= NOW() - INTERVAL '1 day' * days_back;
END;
$$;

CREATE OR REPLACE FUNCTION public.run_scheduled_tasks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM cleanup_old_heartrate();
    PERFORM aggregate_hourly_heartrate();
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_old_heartrate()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM heartrate_data 
    WHERE recorded_at < NOW() - INTERVAL '7 days';
END;
$$;