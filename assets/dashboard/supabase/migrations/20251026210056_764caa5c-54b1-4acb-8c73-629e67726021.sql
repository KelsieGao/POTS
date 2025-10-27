-- Insert fake patient Riley Pots
INSERT INTO public.patients (
  id,
  first_name,
  last_name,
  date_of_birth,
  sex_assigned_at_birth,
  height_cm,
  weight_kg,
  pots_diagnosis_date,
  reason_for_using_app,
  email,
  phone,
  clinician_id
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Riley',
  'Pots',
  '2004-06-15',
  'Female',
  165,
  58.5,
  NULL,
  'Doctor referral',
  'riley.pots@example.com',
  '+1-555-0123',
  NULL
);

-- Insert devices for Riley
INSERT INTO public.devices (
  device_id,
  device_name,
  device_type,
  firmware_version,
  patient_id,
  battery_level,
  is_active,
  last_sync
) VALUES 
(
  'WATCH_001',
  'Polar Ignite',
  'polar_ignite',
  '9.4',
  '00000000-0000-0000-0000-000000000001',
  85,
  true,
  NOW() - INTERVAL '1 hour'
),
(
  'BP_MONITOR_001',
  'BP Monitor',
  'other',
  '2.1',
  '00000000-0000-0000-0000-000000000001',
  92,
  true,
  NOW() - INTERVAL '1 hour'
);

-- Insert full day of heart rate data for Riley
-- Night/Early Morning (12 AM - 7 AM): Sleeping, low HR
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '1 hour' * h + INTERVAL '1 minute' * m,
  50 + (RANDOM() * 10)::INTEGER,
  95
FROM generate_series(0, 6) AS h, generate_series(0, 59, 5) AS m;

-- Morning wake up (7 AM - 8 AM): Gradual increase
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '7 hours' + INTERVAL '1 minute' * m,
  65 + (m / 2)::INTEGER + (RANDOM() * 5)::INTEGER,
  95
FROM generate_series(0, 59, 5) AS m;

-- Stand-up test (8:30 AM): CLEAR POTS PATTERN
-- Lying down baseline (8:30-8:35): ~70 bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '8 hours 30 minutes' + INTERVAL '10 seconds' * s,
  68 + (RANDOM() * 4)::INTEGER,
  95
FROM generate_series(0, 29) AS s;

-- Standing up transition (8:35-8:36): Rapid increase to 110+ bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '8 hours 35 minutes' + INTERVAL '10 seconds' * s,
  70 + (s * 7) + (RANDOM() * 5)::INTEGER,
  95
FROM generate_series(0, 5) AS s;

-- Standing sustained (8:36-8:46): Sustained elevation 105-120 bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '8 hours 36 minutes' + INTERVAL '10 seconds' * s,
  105 + (RANDOM() * 15)::INTEGER,
  95
FROM generate_series(0, 59) AS s;

-- Recovery after sitting back down (8:46-8:50): Gradual decrease
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '8 hours 46 minutes' + INTERVAL '10 seconds' * s,
  110 - (s * 1.5)::INTEGER + (RANDOM() * 5)::INTEGER,
  95
FROM generate_series(0, 23) AS s;

-- Morning activities (9 AM - 12 PM): Normal variation 70-90 bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '1 hour' * h + INTERVAL '1 minute' * m,
  75 + (RANDOM() * 15)::INTEGER,
  95
FROM generate_series(9, 11) AS h, generate_series(0, 59, 5) AS m;

-- EPISODE 1 WITH SYMPTOM LOG (2:15 PM): RED ALERT
-- Baseline before episode
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '14 hours' + INTERVAL '1 minute' * m,
  72 + (RANDOM() * 8)::INTEGER,
  95
FROM generate_series(0, 14, 2) AS m;

-- Episode spike (2:15-2:25 PM): HR jumps to 115+ bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '14 hours 15 minutes' + INTERVAL '10 seconds' * s,
  115 + (RANDOM() * 12)::INTEGER,
  95
FROM generate_series(0, 59) AS s;

-- Recovery from episode
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '14 hours 25 minutes' + INTERVAL '1 minute' * m,
  100 - (m * 2)::INTEGER + (RANDOM() * 5)::INTEGER,
  95
FROM generate_series(0, 14, 2) AS m;

-- Afternoon (3 PM - 5 PM): Normal variation
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '1 hour' * h + INTERVAL '1 minute' * m,
  70 + (RANDOM() * 15)::INTEGER,
  95
FROM generate_series(15, 16) AS h, generate_series(0, 59, 5) AS m;

-- EPISODE 2 WITHOUT SYMPTOM LOG (5:30 PM): ORANGE ALERT
-- Baseline before episode
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '17 hours' + INTERVAL '1 minute' * m,
  68 + (RANDOM() * 8)::INTEGER,
  95
FROM generate_series(0, 29, 2) AS m;

-- Episode spike (5:30-5:40 PM): HR jumps to 110+ bpm
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '17 hours 30 minutes' + INTERVAL '10 seconds' * s,
  110 + (RANDOM() * 15)::INTEGER,
  95
FROM generate_series(0, 59) AS s;

-- Recovery from episode
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '17 hours 40 minutes' + INTERVAL '1 minute' * m,
  95 - (m * 1.5)::INTEGER + (RANDOM() * 5)::INTEGER,
  95
FROM generate_series(0, 19, 2) AS m;

-- Evening (6 PM - 11 PM): Winding down
INSERT INTO public.heartrate_data (device_id, patient_id, recorded_at, heart_rate, signal_quality)
SELECT 
  'WATCH_001',
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '1 hour' * h + INTERVAL '1 minute' * m,
  65 - ((h - 18) * 2) + (RANDOM() * 10)::INTEGER,
  95
FROM generate_series(18, 22) AS h, generate_series(0, 59, 5) AS m;

-- Blood Pressure Data
-- Stand-up test BP measurements
INSERT INTO public.bp_data (device_id, patient_id, recorded_at, systolic, diastolic)
VALUES
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '8 hours 34 minutes', 115, 72),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '8 hours 36 minutes', 105, 78),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '8 hours 38 minutes', 108, 80),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '8 hours 40 minutes', 110, 79),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '8 hours 45 minutes', 112, 77);

-- Episode 1 BP (2:15 PM) - WITH symptom log
INSERT INTO public.bp_data (device_id, patient_id, recorded_at, systolic, diastolic)
VALUES
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '14 hours 14 minutes', 118, 74),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '14 hours 16 minutes', 108, 80),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '14 hours 20 minutes', 112, 78);

-- Episode 2 BP (5:30 PM) - WITHOUT symptom log (orange alert)
INSERT INTO public.bp_data (device_id, patient_id, recorded_at, systolic, diastolic)
VALUES
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '17 hours 29 minutes', 120, 73),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '17 hours 31 minutes', 106, 79),
  ('BP_MONITOR_001', '00000000-0000-0000-0000-000000000001', CURRENT_DATE + INTERVAL '17 hours 35 minutes', 110, 77);

-- Symptom log for Episode 1 at 2:15 PM (RED ALERT)
INSERT INTO public.symptom_logs (
  patient_id,
  timestamp,
  symptoms,
  severity,
  activity_type,
  time_of_day,
  other_details
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE + INTERVAL '14 hours 18 minutes',
  ARRAY['Dizziness', 'Lightheadedness', 'Heart Racing', 'Fatigue', 'Brain Fog'],
  8,
  'standing',
  'afternoon',
  'Was standing in kitchen preparing snack when suddenly felt very dizzy and heart started racing. Had to sit down immediately. Felt foggy and lightheaded for several minutes.'
);

-- Stand-up test record
INSERT INTO public.standup_tests (
  patient_id,
  test_date,
  test_time,
  supine_hr,
  supine_systolic,
  supine_diastolic,
  supine_duration_minutes,
  standing_1min_hr,
  standing_1min_systolic,
  standing_1min_diastolic,
  standing_3min_hr,
  standing_3min_systolic,
  standing_3min_diastolic,
  standing_5min_hr,
  standing_10min_hr,
  test_result,
  pots_severity,
  notes
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE,
  '08:30:00',
  70,
  115,
  72,
  5,
  112,
  105,
  78,
  116,
  108,
  80,
  118,
  115,
  'pots',
  'moderate',
  'Clear POTS pattern observed. HR increased by 42 bpm from supine to 1 min standing (>30 bpm threshold). Sustained tachycardia throughout 10-minute standing period. Patient reported dizziness and lightheadedness during test.'
);

-- VOSS Questionnaire showing POTS symptoms
INSERT INTO public.voss_questionnaires (
  patient_id,
  completed_at,
  dizziness_frequency,
  orthostatic_intolerance,
  fatigue_level,
  cognitive_symptoms,
  sleep_quality,
  symptom_frequency,
  symptom_severity,
  total_score,
  interpretation,
  notes
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  CURRENT_DATE - INTERVAL '2 days',
  4,
  4,
  8,
  3,
  4,
  4,
  4,
  51,
  'Severe orthostatic symptoms consistent with POTS. Patient reports frequent episodes of dizziness, lightheadedness, and heart racing when standing. Significant impact on daily activities.',
  'Patient describes feeling "dizzy and like heart is going to jump out of chest" when standing up, especially in morning and after meals. Has to limit activities due to symptoms. Sleep disrupted by symptoms.'
);