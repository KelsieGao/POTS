export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      accelerometer_data: {
        Row: {
          activity_type: string | null
          created_at: string | null
          device_id: string
          id: string
          magnitude: number | null
          patient_id: string | null
          recorded_at: string
          x: number
          y: number
          z: number
        }
        Insert: {
          activity_type?: string | null
          created_at?: string | null
          device_id: string
          id?: string
          magnitude?: number | null
          patient_id?: string | null
          recorded_at: string
          x: number
          y: number
          z: number
        }
        Update: {
          activity_type?: string | null
          created_at?: string | null
          device_id?: string
          id?: string
          magnitude?: number | null
          patient_id?: string | null
          recorded_at?: string
          x?: number
          y?: number
          z?: number
        }
        Relationships: [
          {
            foreignKeyName: "accelerometer_data_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      bp_data: {
        Row: {
          created_at: string | null
          device_id: string
          diastolic: number
          id: string
          patient_id: string | null
          recorded_at: string
          systolic: number
        }
        Insert: {
          created_at?: string | null
          device_id: string
          diastolic: number
          id?: string
          patient_id?: string | null
          recorded_at: string
          systolic: number
        }
        Update: {
          created_at?: string | null
          device_id?: string
          diastolic?: number
          id?: string
          patient_id?: string | null
          recorded_at?: string
          systolic?: number
        }
        Relationships: [
          {
            foreignKeyName: "bp_data_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      clinician_profiles: {
        Row: {
          created_at: string | null
          first_name: string | null
          id: string
          join_code: string
          last_name: string | null
          specialty: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          first_name?: string | null
          id: string
          join_code: string
          last_name?: string | null
          specialty?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          first_name?: string | null
          id?: string
          join_code?: string
          last_name?: string | null
          specialty?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      data_sessions: {
        Row: {
          created_at: string | null
          device_id: string
          id: string
          patient_id: string
          session_end: string | null
          session_start: string
          session_type: string
          total_acc_samples: number | null
          total_hr_samples: number | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          device_id: string
          id?: string
          patient_id: string
          session_end?: string | null
          session_start: string
          session_type?: string
          total_acc_samples?: number | null
          total_hr_samples?: number | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          device_id?: string
          id?: string
          patient_id?: string
          session_end?: string | null
          session_start?: string
          session_type?: string
          total_acc_samples?: number | null
          total_hr_samples?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "data_sessions_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      devices: {
        Row: {
          battery_level: number | null
          created_at: string | null
          device_id: string
          device_name: string | null
          device_type: string | null
          firmware_version: string | null
          id: string
          is_active: boolean | null
          last_maintenance_date: string | null
          last_sync: string | null
          patient_id: string | null
          total_recording_hours: number | null
        }
        Insert: {
          battery_level?: number | null
          created_at?: string | null
          device_id: string
          device_name?: string | null
          device_type?: string | null
          firmware_version?: string | null
          id?: string
          is_active?: boolean | null
          last_maintenance_date?: string | null
          last_sync?: string | null
          patient_id?: string | null
          total_recording_hours?: number | null
        }
        Update: {
          battery_level?: number | null
          created_at?: string | null
          device_id?: string
          device_name?: string | null
          device_type?: string | null
          firmware_version?: string | null
          id?: string
          is_active?: boolean | null
          last_maintenance_date?: string | null
          last_sync?: string | null
          patient_id?: string | null
          total_recording_hours?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "devices_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      heartrate_data: {
        Row: {
          contact_status: boolean | null
          contact_status_supported: boolean | null
          created_at: string | null
          device_id: string
          heart_rate: number
          id: string
          patient_id: string | null
          recorded_at: string
          rr_available: boolean | null
          rr_interval_ms: number | null
          signal_quality: number | null
        }
        Insert: {
          contact_status?: boolean | null
          contact_status_supported?: boolean | null
          created_at?: string | null
          device_id: string
          heart_rate: number
          id?: string
          patient_id?: string | null
          recorded_at: string
          rr_available?: boolean | null
          rr_interval_ms?: number | null
          signal_quality?: number | null
        }
        Update: {
          contact_status?: boolean | null
          contact_status_supported?: boolean | null
          created_at?: string | null
          device_id?: string
          heart_rate?: number
          id?: string
          patient_id?: string | null
          recorded_at?: string
          rr_available?: boolean | null
          rr_interval_ms?: number | null
          signal_quality?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "heartrate_data_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      heartrate_hourly_summary: {
        Row: {
          avg_hr: number | null
          created_at: string | null
          hour_timestamp: string
          hr_variability: number | null
          id: string
          max_hr: number | null
          min_hr: number | null
          patient_id: string | null
          resting_hr: number | null
          sample_count: number | null
        }
        Insert: {
          avg_hr?: number | null
          created_at?: string | null
          hour_timestamp: string
          hr_variability?: number | null
          id?: string
          max_hr?: number | null
          min_hr?: number | null
          patient_id?: string | null
          resting_hr?: number | null
          sample_count?: number | null
        }
        Update: {
          avg_hr?: number | null
          created_at?: string | null
          hour_timestamp?: string
          hr_variability?: number | null
          id?: string
          max_hr?: number | null
          min_hr?: number | null
          patient_id?: string | null
          resting_hr?: number | null
          sample_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "heartrate_hourly_summary_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          clinician_id: string
          created_at: string | null
          id: string
          is_read: boolean | null
          message: string
          patient_id: string | null
          title: string
          type: string
        }
        Insert: {
          clinician_id: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          message: string
          patient_id?: string | null
          title: string
          type: string
        }
        Update: {
          clinician_id?: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          message?: string
          patient_id?: string | null
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_clinician_id_fkey"
            columns: ["clinician_id"]
            isOneToOne: false
            referencedRelation: "clinician_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      patients: {
        Row: {
          clinician_id: string | null
          created_at: string | null
          date_of_birth: string
          email: string | null
          first_name: string
          height_cm: number | null
          id: string
          last_name: string
          phone: string | null
          pots_diagnosis_date: string | null
          primary_care_physician: string | null
          reason_for_using_app: string
          sex_assigned_at_birth: string
          updated_at: string | null
          weight_kg: number | null
        }
        Insert: {
          clinician_id?: string | null
          created_at?: string | null
          date_of_birth: string
          email?: string | null
          first_name: string
          height_cm?: number | null
          id?: string
          last_name: string
          phone?: string | null
          pots_diagnosis_date?: string | null
          primary_care_physician?: string | null
          reason_for_using_app: string
          sex_assigned_at_birth: string
          updated_at?: string | null
          weight_kg?: number | null
        }
        Update: {
          clinician_id?: string | null
          created_at?: string | null
          date_of_birth?: string
          email?: string | null
          first_name?: string
          height_cm?: number | null
          id?: string
          last_name?: string
          phone?: string | null
          pots_diagnosis_date?: string | null
          primary_care_physician?: string | null
          reason_for_using_app?: string
          sex_assigned_at_birth?: string
          updated_at?: string | null
          weight_kg?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "patients_clinician_id_fkey"
            columns: ["clinician_id"]
            isOneToOne: false
            referencedRelation: "clinician_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      safety_acknowledgments: {
        Row: {
          acknowledged_at: string
          companion_recommended: boolean
          created_at: string | null
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          emergency_contact_provided: boolean
          id: string
          liability_acknowledged: boolean
          medical_conditions: string | null
          medications: string | null
          patient_id: string
          risk_acknowledged: boolean
          safety_warnings_read: boolean
          test_id: string | null
          updated_at: string | null
        }
        Insert: {
          acknowledged_at: string
          companion_recommended?: boolean
          created_at?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_provided?: boolean
          id?: string
          liability_acknowledged?: boolean
          medical_conditions?: string | null
          medications?: string | null
          patient_id: string
          risk_acknowledged?: boolean
          safety_warnings_read?: boolean
          test_id?: string | null
          updated_at?: string | null
        }
        Update: {
          acknowledged_at?: string
          companion_recommended?: boolean
          created_at?: string | null
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          emergency_contact_provided?: boolean
          id?: string
          liability_acknowledged?: boolean
          medical_conditions?: string | null
          medications?: string | null
          patient_id?: string
          risk_acknowledged?: boolean
          safety_warnings_read?: boolean
          test_id?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      standup_tests: {
        Row: {
          created_at: string | null
          hr_increase_10min: number | null
          hr_increase_1min: number | null
          hr_increase_3min: number | null
          hr_increase_5min: number | null
          id: string
          medications_taken: string | null
          notes: string | null
          patient_id: string | null
          pots_severity: string | null
          questionnaire_id: string | null
          room_temperature: number | null
          standing_10min_hr: number | null
          standing_1min_diastolic: number | null
          standing_1min_hr: number | null
          standing_1min_systolic: number | null
          standing_3min_diastolic: number | null
          standing_3min_hr: number | null
          standing_3min_systolic: number | null
          standing_5min_hr: number | null
          supine_diastolic: number | null
          supine_duration_minutes: number | null
          supine_hr: number | null
          supine_systolic: number | null
          systolic_drop_1min: number | null
          systolic_drop_3min: number | null
          test_date: string
          test_result: string | null
          test_time: string
          time_since_last_meal: number | null
        }
        Insert: {
          created_at?: string | null
          hr_increase_10min?: number | null
          hr_increase_1min?: number | null
          hr_increase_3min?: number | null
          hr_increase_5min?: number | null
          id?: string
          medications_taken?: string | null
          notes?: string | null
          patient_id?: string | null
          pots_severity?: string | null
          questionnaire_id?: string | null
          room_temperature?: number | null
          standing_10min_hr?: number | null
          standing_1min_diastolic?: number | null
          standing_1min_hr?: number | null
          standing_1min_systolic?: number | null
          standing_3min_diastolic?: number | null
          standing_3min_hr?: number | null
          standing_3min_systolic?: number | null
          standing_5min_hr?: number | null
          supine_diastolic?: number | null
          supine_duration_minutes?: number | null
          supine_hr?: number | null
          supine_systolic?: number | null
          systolic_drop_1min?: number | null
          systolic_drop_3min?: number | null
          test_date: string
          test_result?: string | null
          test_time: string
          time_since_last_meal?: number | null
        }
        Update: {
          created_at?: string | null
          hr_increase_10min?: number | null
          hr_increase_1min?: number | null
          hr_increase_3min?: number | null
          hr_increase_5min?: number | null
          id?: string
          medications_taken?: string | null
          notes?: string | null
          patient_id?: string | null
          pots_severity?: string | null
          questionnaire_id?: string | null
          room_temperature?: number | null
          standing_10min_hr?: number | null
          standing_1min_diastolic?: number | null
          standing_1min_hr?: number | null
          standing_1min_systolic?: number | null
          standing_3min_diastolic?: number | null
          standing_3min_hr?: number | null
          standing_3min_systolic?: number | null
          standing_5min_hr?: number | null
          supine_diastolic?: number | null
          supine_duration_minutes?: number | null
          supine_hr?: number | null
          supine_systolic?: number | null
          systolic_drop_1min?: number | null
          systolic_drop_3min?: number | null
          test_date?: string
          test_result?: string | null
          test_time?: string
          time_since_last_meal?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "standup_tests_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "standup_tests_questionnaire_id_fkey"
            columns: ["questionnaire_id"]
            isOneToOne: false
            referencedRelation: "voss_questionnaires"
            referencedColumns: ["id"]
          },
        ]
      }
      symptom_logs: {
        Row: {
          activity_type: string | null
          created_at: string | null
          id: string
          other_details: string | null
          patient_id: string
          severity: number
          symptoms: string[]
          time_of_day: string | null
          timestamp: string
          updated_at: string | null
        }
        Insert: {
          activity_type?: string | null
          created_at?: string | null
          id?: string
          other_details?: string | null
          patient_id: string
          severity: number
          symptoms: string[]
          time_of_day?: string | null
          timestamp: string
          updated_at?: string | null
        }
        Update: {
          activity_type?: string | null
          created_at?: string | null
          id?: string
          other_details?: string | null
          patient_id?: string
          severity?: number
          symptoms?: string[]
          time_of_day?: string | null
          timestamp?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      symptoms: {
        Row: {
          created_at: string | null
          emoji: string
          id: string
          is_custom: boolean | null
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          emoji: string
          id: string
          is_custom?: boolean | null
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          emoji?: string
          id?: string
          is_custom?: boolean | null
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      voss_questionnaires: {
        Row: {
          cognitive_symptoms: number | null
          completed_at: string
          created_at: string | null
          dizziness_frequency: number | null
          fatigue_level: number | null
          id: string
          interpretation: string | null
          notes: string | null
          orthostatic_intolerance: number | null
          patient_id: string | null
          sleep_quality: number | null
          symptom_frequency: number | null
          symptom_severity: number | null
          total_score: number | null
        }
        Insert: {
          cognitive_symptoms?: number | null
          completed_at: string
          created_at?: string | null
          dizziness_frequency?: number | null
          fatigue_level?: number | null
          id?: string
          interpretation?: string | null
          notes?: string | null
          orthostatic_intolerance?: number | null
          patient_id?: string | null
          sleep_quality?: number | null
          symptom_frequency?: number | null
          symptom_severity?: number | null
          total_score?: number | null
        }
        Update: {
          cognitive_symptoms?: number | null
          completed_at?: string
          created_at?: string | null
          dizziness_frequency?: number | null
          fatigue_level?: number | null
          id?: string
          interpretation?: string | null
          notes?: string | null
          orthostatic_intolerance?: number | null
          patient_id?: string | null
          sleep_quality?: number | null
          symptom_frequency?: number | null
          symptom_severity?: number | null
          total_score?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "voss_questionnaires_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      aggregate_hourly_heartrate: { Args: never; Returns: undefined }
      analyze_pots_indicators: {
        Args: { days_back?: number; patient_uuid: string }
        Returns: {
          avg_hr_lying: number
          avg_hr_standing: number
          hr_increase_standing: number
          hr_variability: number
          pots_risk_score: number
        }[]
      }
      cleanup_old_heartrate: { Args: never; Returns: undefined }
      generate_join_code: { Args: never; Returns: string }
      run_scheduled_tasks: { Args: never; Returns: undefined }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
