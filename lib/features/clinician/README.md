# Clinician Dashboard System

This directory contains the complete clinician-facing dashboard system for the POTS Monitor app.

## Features

### Authentication
- **Clinician Code Entry**: Secure 6+ character alphanumeric code authentication
- **Auto-uppercase conversion**: Codes are case-insensitive
- **Session management**: Last login tracking

### Patient Management
- **Add Patient**: Link patients via their unique patient codes
- **Patient List**: View all patients with search and filter capabilities
- **Dashboard Stats**: Quick overview of active, completed, and total patients
- **Status Badges**: Visual indicators for patient status (Active, Completed, Inactive)
- **Progress Tracking**: See patient progress through monitoring period

### Patient Detail Dashboard
- **Summary Cards**:
  - Average heart rate
  - Average blood pressure (lying)
  - Average blood pressure (standing)
  - Episode count
- **Stand-Up Test Results**: View all completed tests with timestamps and readings
- **Recent Symptoms**: Quick view of latest symptom logs
- **Action Buttons**: Direct access to VOSS results and episode history

### VOSS Survey Results
- **Score Display**: Large, prominent total score out of 90
- **Severity Classification**:
  - Mild (0-24): Green
  - Moderate (25-44): Orange/Yellow
  - High (45-90): Red
- **Visual Progress Bar**: Color-coded scale with score indicator
- **Clinical Interpretation**: Detailed explanation of score meaning
- **Educational Content**: Information about VOSS assessment

### Episode History
- **Chronological List**: All symptom logs ordered by date
- **Expandable Cards**: Tap to view additional details
- **Severity Badges**: Color-coded severity indicators
- **Symptom Chips**: Visual tags for each reported symptom
- **Context Information**: Time of day, activity type, and additional notes

## File Structure

```
lib/features/clinician/
├── README.md                       # This file
├── seed_test_clinician.dart       # Helper script to create test clinician
├── clinician_code_entry_page.dart # Authentication screen
├── clinician_home_page.dart       # Patient list and dashboard stats
├── add_patient_page.dart          # Add patient by code
├── patient_detail_page.dart       # Patient overview with summary cards
├── voss_results_page.dart         # VOSS survey results display
└── episode_history_page.dart      # Symptom episode history
```

## Database Schema

### Tables

#### `clinicians`
- `id` (uuid, primary key)
- `clinician_code` (text, unique, 6+ chars)
- `name` (text)
- `email` (text, nullable)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `last_login_at` (timestamptz, nullable)

#### `clinician_patients`
- `id` (uuid, primary key)
- `clinician_id` (uuid, foreign key → clinicians)
- `patient_id` (text, foreign key → patients)
- `status` (text: 'active', 'completed', 'inactive')
- `added_at` (timestamptz)
- `updated_at` (timestamptz)

## Navigation Flow

```
Launch Screen
    ↓
Clinician Code Entry
    ↓
Clinician Home (Patient List)
    ↓
    ├── Add New Patient → Enter Patient Code → Back to Home
    └── Select Patient → Patient Detail Dashboard
                            ↓
                            ├── VOSS Results
                            └── Episode History
```

## Usage

### Creating a Test Clinician

To create a test clinician for development:

```dart
import 'features/clinician/seed_test_clinician.dart';

// Call this once to create a test clinician
await seedTestClinician();
```

This will create a clinician with:
- Code: `TEST123`
- Name: Dr. Test Clinician
- Email: test.clinician@example.com

### Adding a Patient

1. From Clinician Home, tap "Add Patient"
2. Enter the patient's unique code (found in patient app)
3. Patient will be added to your dashboard with "Active" status

### Viewing Patient Data

1. Tap any patient card from the list
2. View summary statistics at the top
3. Scroll to see all stand-up test results
4. View recent symptom logs
5. Tap "VOSS Survey" to see questionnaire results
6. Tap "Episodes" to see full symptom history

## Color Scheme

- **Clinician Theme**: Blue gradient (#2196F3 to #00BCD4)
- **Patient Theme**: Teal (#20B2AA)
- **Status Colors**:
  - Active: Green
  - Completed: Blue
  - Inactive: Gray
- **Severity Colors**:
  - Mild (1-3): Green
  - Moderate (4-6): Orange
  - Severe (7-10): Red

## Security

- Row-level security enabled on all tables
- Clinicians can only access their linked patients
- Patient codes required for linking
- Session tracking for audit purposes

## Future Enhancements

Potential additions:
- QR code scanning for patient/clinician codes
- Data export functionality
- Time-series charts for heart rate trends
- Notes/annotations on patient records
- Push notifications for patient activity
- Multi-clinician collaboration on patients
