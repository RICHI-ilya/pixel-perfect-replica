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
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      appointment_status_history: {
        Row: {
          appointment_id: string
          changed_by: string | null
          clinic_id: string
          created_at: string
          from_start_time: string | null
          from_status: Database["public"]["Enums"]["appt_status"] | null
          id: string
          note: string | null
          to_start_time: string | null
          to_status: Database["public"]["Enums"]["appt_status"] | null
        }
        Insert: {
          appointment_id: string
          changed_by?: string | null
          clinic_id: string
          created_at?: string
          from_start_time?: string | null
          from_status?: Database["public"]["Enums"]["appt_status"] | null
          id?: string
          note?: string | null
          to_start_time?: string | null
          to_status?: Database["public"]["Enums"]["appt_status"] | null
        }
        Update: {
          appointment_id?: string
          changed_by?: string | null
          clinic_id?: string
          created_at?: string
          from_start_time?: string | null
          from_status?: Database["public"]["Enums"]["appt_status"] | null
          id?: string
          note?: string | null
          to_start_time?: string | null
          to_status?: Database["public"]["Enums"]["appt_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "appointment_status_history_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_status_history_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      appointment_type_doctors: {
        Row: {
          appointment_type_id: string
          doctor_id: string
        }
        Insert: {
          appointment_type_id: string
          doctor_id: string
        }
        Update: {
          appointment_type_id?: string
          doctor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "appointment_type_doctors_appointment_type_id_fkey"
            columns: ["appointment_type_id"]
            isOneToOne: false
            referencedRelation: "appointment_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointment_type_doctors_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
        ]
      }
      appointment_types: {
        Row: {
          clinic_id: string
          created_at: string
          description: string | null
          duration_minutes: number
          id: string
          is_active: boolean
          name: string
          updated_at: string
        }
        Insert: {
          clinic_id: string
          created_at?: string
          description?: string | null
          duration_minutes: number
          id?: string
          is_active?: boolean
          name: string
          updated_at?: string
        }
        Update: {
          clinic_id?: string
          created_at?: string
          description?: string | null
          duration_minutes?: number
          id?: string
          is_active?: boolean
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "appointment_types_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      appointments: {
        Row: {
          appointment_type_id: string
          cancellation_reason: string | null
          cancelled_at: string | null
          cancelled_by: string | null
          clinic_id: string
          created_at: string
          created_by: string | null
          doctor_id: string
          end_time: string
          id: string
          location_id: string | null
          notes: string | null
          patient_id: string
          room_id: string | null
          start_time: string
          status: Database["public"]["Enums"]["appt_status"]
          updated_at: string
        }
        Insert: {
          appointment_type_id: string
          cancellation_reason?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          clinic_id: string
          created_at?: string
          created_by?: string | null
          doctor_id: string
          end_time: string
          id?: string
          location_id?: string | null
          notes?: string | null
          patient_id: string
          room_id?: string | null
          start_time: string
          status?: Database["public"]["Enums"]["appt_status"]
          updated_at?: string
        }
        Update: {
          appointment_type_id?: string
          cancellation_reason?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          clinic_id?: string
          created_at?: string
          created_by?: string | null
          doctor_id?: string
          end_time?: string
          id?: string
          location_id?: string | null
          notes?: string | null
          patient_id?: string
          room_id?: string | null
          start_time?: string
          status?: Database["public"]["Enums"]["appt_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "appointments_appointment_type_id_fkey"
            columns: ["appointment_type_id"]
            isOneToOne: false
            referencedRelation: "appointment_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "rooms"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          actor_label: string | null
          clinic_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: string
          metadata: Json
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_label?: string | null
          clinic_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: string
          metadata?: Json
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_label?: string | null
          clinic_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: string
          metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      availability_exceptions: {
        Row: {
          clinic_id: string
          created_at: string
          doctor_id: string
          end_time: string
          exception_date: string
          id: string
          is_available: boolean
          reason: string | null
          start_time: string
        }
        Insert: {
          clinic_id: string
          created_at?: string
          doctor_id: string
          end_time?: string
          exception_date: string
          id?: string
          is_available?: boolean
          reason?: string | null
          start_time?: string
        }
        Update: {
          clinic_id?: string
          created_at?: string
          doctor_id?: string
          end_time?: string
          exception_date?: string
          id?: string
          is_available?: boolean
          reason?: string | null
          start_time?: string
        }
        Relationships: [
          {
            foreignKeyName: "availability_exceptions_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "availability_exceptions_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
        ]
      }
      clinic_members: {
        Row: {
          clinic_id: string
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          clinic_id: string
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          clinic_id?: string
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "clinic_members_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      clinics: {
        Row: {
          allow_patient_reschedule: boolean
          close_time: string
          created_at: string
          id: string
          name: string
          open_time: string
          slug: string
          timezone: string
          updated_at: string
        }
        Insert: {
          allow_patient_reschedule?: boolean
          close_time?: string
          created_at?: string
          id?: string
          name: string
          open_time?: string
          slug: string
          timezone?: string
          updated_at?: string
        }
        Update: {
          allow_patient_reschedule?: boolean
          close_time?: string
          created_at?: string
          id?: string
          name?: string
          open_time?: string
          slug?: string
          timezone?: string
          updated_at?: string
        }
        Relationships: []
      }
      doctor_availability: {
        Row: {
          clinic_id: string
          created_at: string
          doctor_id: string
          end_time: string
          id: string
          location_id: string | null
          start_time: string
          weekday: number
        }
        Insert: {
          clinic_id: string
          created_at?: string
          doctor_id: string
          end_time: string
          id?: string
          location_id?: string | null
          start_time: string
          weekday: number
        }
        Update: {
          clinic_id?: string
          created_at?: string
          doctor_id?: string
          end_time?: string
          id?: string
          location_id?: string | null
          start_time?: string
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "doctor_availability_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "doctor_availability_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "doctor_availability_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
        ]
      }
      doctors: {
        Row: {
          clinic_id: string
          created_at: string
          email: string | null
          full_name: string
          id: string
          is_active: boolean
          specialty: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          clinic_id: string
          created_at?: string
          email?: string | null
          full_name: string
          id?: string
          is_active?: boolean
          specialty?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          clinic_id?: string
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          is_active?: boolean
          specialty?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "doctors_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      locations: {
        Row: {
          address: string | null
          clinic_id: string
          created_at: string
          id: string
          is_active: boolean
          name: string
        }
        Insert: {
          address?: string | null
          clinic_id: string
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
        }
        Update: {
          address?: string | null
          clinic_id?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "locations_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          appointment_id: string | null
          body: string | null
          channel: string
          clinic_id: string
          created_at: string
          id: string
          kind: string
          read_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          appointment_id?: string | null
          body?: string | null
          channel?: string
          clinic_id: string
          created_at?: string
          id?: string
          kind: string
          read_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          appointment_id?: string | null
          body?: string | null
          channel?: string
          clinic_id?: string
          created_at?: string
          id?: string
          kind?: string
          read_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      patients: {
        Row: {
          clinic_id: string
          created_at: string
          date_of_birth: string | null
          email: string | null
          full_name: string
          id: string
          info_complete: boolean
          phone: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          clinic_id: string
          created_at?: string
          date_of_birth?: string | null
          email?: string | null
          full_name: string
          id?: string
          info_complete?: boolean
          phone?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          clinic_id?: string
          created_at?: string
          date_of_birth?: string | null
          email?: string | null
          full_name?: string
          id?: string
          info_complete?: boolean
          phone?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "patients_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          email: string | null
          full_name: string
          id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          email?: string | null
          full_name?: string
          id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      rooms: {
        Row: {
          clinic_id: string
          created_at: string
          id: string
          is_active: boolean
          location_id: string | null
          name: string
        }
        Insert: {
          clinic_id: string
          created_at?: string
          id?: string
          is_active?: boolean
          location_id?: string | null
          name: string
        }
        Update: {
          clinic_id?: string
          created_at?: string
          id?: string
          is_active?: boolean
          location_id?: string | null
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "rooms_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rooms_location_id_fkey"
            columns: ["location_id"]
            isOneToOne: false
            referencedRelation: "locations"
            referencedColumns: ["id"]
          },
        ]
      }
      waitlist_entries: {
        Row: {
          appointment_type_id: string
          clinic_id: string
          created_at: string
          doctor_id: string | null
          id: string
          notes: string | null
          patient_id: string
          preferred_from: string
          preferred_time_end: string
          preferred_time_start: string
          preferred_to: string
          priority: Database["public"]["Enums"]["wait_priority"]
          status: string
          updated_at: string
        }
        Insert: {
          appointment_type_id: string
          clinic_id: string
          created_at?: string
          doctor_id?: string | null
          id?: string
          notes?: string | null
          patient_id: string
          preferred_from?: string
          preferred_time_end?: string
          preferred_time_start?: string
          preferred_to?: string
          priority?: Database["public"]["Enums"]["wait_priority"]
          status?: string
          updated_at?: string
        }
        Update: {
          appointment_type_id?: string
          clinic_id?: string
          created_at?: string
          doctor_id?: string | null
          id?: string
          notes?: string | null
          patient_id?: string
          preferred_from?: string
          preferred_time_end?: string
          preferred_time_start?: string
          preferred_to?: string
          priority?: Database["public"]["Enums"]["wait_priority"]
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "waitlist_entries_appointment_type_id_fkey"
            columns: ["appointment_type_id"]
            isOneToOne: false
            referencedRelation: "appointment_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_clinic_id_fkey"
            columns: ["clinic_id"]
            isOneToOne: false
            referencedRelation: "clinics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "waitlist_entries_patient_id_fkey"
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
      available_slots: {
        Args: {
          _appointment_type_id: string
          _clinic_id: string
          _date: string
          _doctor_id?: string
        }
        Returns: {
          doctor_id: string
          doctor_name: string
          slot_end: string
          slot_start: string
        }[]
      }
      book_appointment: {
        Args: {
          _appointment_type_id: string
          _clinic_id: string
          _doctor_id: string
          _location_id?: string
          _notes?: string
          _patient_id: string
          _room_id?: string
          _start: string
        }
        Returns: string
      }
      cancel_appointment: {
        Args: { _appointment_id: string; _reason?: string }
        Returns: string
      }
      has_clinic_role: {
        Args: {
          _clinic_id: string
          _role: Database["public"]["Enums"]["app_role"]
        }
        Returns: boolean
      }
      is_clinic_member: { Args: { _clinic_id: string }; Returns: boolean }
      is_my_doctor_record: { Args: { _doctor_id: string }; Returns: boolean }
      is_my_patient_record: { Args: { _patient_id: string }; Returns: boolean }
      matching_waitlist: {
        Args: { _appointment_id: string }
        Returns: {
          doctor_name: string
          id: string
          notes: string
          patient_name: string
          priority: Database["public"]["Enums"]["wait_priority"]
          type_name: string
        }[]
      }
      my_doctor_id: { Args: { _clinic_id: string }; Returns: string }
      reschedule_appointment: {
        Args: { _appointment_id: string; _doctor_id?: string; _start: string }
        Returns: string
      }
      set_appointment_status: {
        Args: {
          _appointment_id: string
          _status: Database["public"]["Enums"]["appt_status"]
        }
        Returns: string
      }
    }
    Enums: {
      app_role: "patient" | "doctor" | "admin"
      appt_status:
        | "pending"
        | "confirmed"
        | "checked_in"
        | "completed"
        | "cancelled"
        | "no_show"
      wait_priority: "low" | "normal" | "high"
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
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
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
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
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["patient", "doctor", "admin"],
      appt_status: [
        "pending",
        "confirmed",
        "checked_in",
        "completed",
        "cancelled",
        "no_show",
      ],
      wait_priority: ["low", "normal", "high"],
    },
  },
} as const
