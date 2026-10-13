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
    PostgrestVersion: "14.17"
  }
  public: {
    Tables: {
      academy_assignment_submissions: {
        Row: {
          assignment_id: string
          created_at: string
          enrollment_id: string
          feedback: string | null
          graded_at: string | null
          graded_by: string | null
          id: string
          score: number | null
          status: string
          submission_text: string | null
          submission_url: string | null
          submitted_at: string | null
          updated_at: string
        }
        Insert: {
          assignment_id: string
          created_at?: string
          enrollment_id: string
          feedback?: string | null
          graded_at?: string | null
          graded_by?: string | null
          id?: string
          score?: number | null
          status?: string
          submission_text?: string | null
          submission_url?: string | null
          submitted_at?: string | null
          updated_at?: string
        }
        Update: {
          assignment_id?: string
          created_at?: string
          enrollment_id?: string
          feedback?: string | null
          graded_at?: string | null
          graded_by?: string | null
          id?: string
          score?: number | null
          status?: string
          submission_text?: string | null
          submission_url?: string | null
          submitted_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_assignment_submissions_assignment_id_fkey"
            columns: ["assignment_id"]
            isOneToOne: false
            referencedRelation: "academy_assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_assignment_submissions_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "academy_enrollments"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_assignments: {
        Row: {
          cohort_id: string | null
          course_id: string
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          is_published: boolean
          max_score: number
          title: string
          updated_at: string
        }
        Insert: {
          cohort_id?: string | null
          course_id: string
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          is_published?: boolean
          max_score?: number
          title: string
          updated_at?: string
        }
        Update: {
          cohort_id?: string | null
          course_id?: string
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          is_published?: boolean
          max_score?: number
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_assignments_cohort_id_fkey"
            columns: ["cohort_id"]
            isOneToOne: false
            referencedRelation: "academy_cohorts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_assignments_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "academy_courses"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_attendance: {
        Row: {
          enrollment_id: string
          id: string
          notes: string | null
          recorded_at: string
          session_id: string
          status: string
        }
        Insert: {
          enrollment_id: string
          id?: string
          notes?: string | null
          recorded_at?: string
          session_id: string
          status: string
        }
        Update: {
          enrollment_id?: string
          id?: string
          notes?: string | null
          recorded_at?: string
          session_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_attendance_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "academy_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_attendance_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "academy_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_certificate_registry: {
        Row: {
          certificate_code: string
          course_title: string
          issued_at: string
          status: string
        }
        Insert: {
          certificate_code: string
          course_title: string
          issued_at: string
          status: string
        }
        Update: {
          certificate_code?: string
          course_title?: string
          issued_at?: string
          status?: string
        }
        Relationships: []
      }
      academy_certificate_templates: {
        Row: {
          created_at: string
          created_by: string | null
          field_mappings: Json
          id: string
          is_active: boolean
          is_default: boolean
          logo_storage_path: string | null
          mime_type: string | null
          name: string
          original_filename: string | null
          settings: Json
          storage_path: string | null
          template_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          logo_storage_path?: string | null
          mime_type?: string | null
          name?: string
          original_filename?: string | null
          settings?: Json
          storage_path?: string | null
          template_type?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          logo_storage_path?: string | null
          mime_type?: string | null
          name?: string
          original_filename?: string | null
          settings?: Json
          storage_path?: string | null
          template_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      academy_certificates: {
        Row: {
          certificate_code: string
          enrollment_id: string
          id: string
          issued_at: string
          issued_by: string | null
          output_storage_path: string | null
          rendered_at: string | null
          status: string
          template_id: string | null
        }
        Insert: {
          certificate_code?: string
          enrollment_id: string
          id?: string
          issued_at?: string
          issued_by?: string | null
          output_storage_path?: string | null
          rendered_at?: string | null
          status?: string
          template_id?: string | null
        }
        Update: {
          certificate_code?: string
          enrollment_id?: string
          id?: string
          issued_at?: string
          issued_by?: string | null
          output_storage_path?: string | null
          rendered_at?: string | null
          status?: string
          template_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "academy_certificates_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: true
            referencedRelation: "academy_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_certificates_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "academy_certificate_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_cohort_instructors: {
        Row: {
          cohort_id: string
          instructor_id: string
          role: string
        }
        Insert: {
          cohort_id: string
          instructor_id: string
          role?: string
        }
        Update: {
          cohort_id?: string
          instructor_id?: string
          role?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_cohort_instructors_cohort_id_fkey"
            columns: ["cohort_id"]
            isOneToOne: false
            referencedRelation: "academy_cohorts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_cohort_instructors_instructor_id_fkey"
            columns: ["instructor_id"]
            isOneToOne: false
            referencedRelation: "academy_instructors"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_cohorts: {
        Row: {
          capacity: number | null
          course_id: string
          created_at: string
          ends_at: string | null
          id: string
          name: string
          starts_at: string | null
          status: string
          updated_at: string
        }
        Insert: {
          capacity?: number | null
          course_id: string
          created_at?: string
          ends_at?: string | null
          id?: string
          name: string
          starts_at?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          capacity?: number | null
          course_id?: string
          created_at?: string
          ends_at?: string | null
          id?: string
          name?: string
          starts_at?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_cohorts_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "academy_courses"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_courses: {
        Row: {
          category: string
          created_at: string
          delivery_mode: string | null
          description: string | null
          duration_text: string | null
          fee: number | null
          id: string
          is_active: boolean
          slug: string
          title: string
          updated_at: string
        }
        Insert: {
          category: string
          created_at?: string
          delivery_mode?: string | null
          description?: string | null
          duration_text?: string | null
          fee?: number | null
          id?: string
          is_active?: boolean
          slug: string
          title: string
          updated_at?: string
        }
        Update: {
          category?: string
          created_at?: string
          delivery_mode?: string | null
          description?: string | null
          duration_text?: string | null
          fee?: number | null
          id?: string
          is_active?: boolean
          slug?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      academy_enrollments: {
        Row: {
          completed_at: string | null
          course_id: string
          enrolled_at: string
          id: string
          order_id: string | null
          progress: number
          status: string
          user_id: string
        }
        Insert: {
          completed_at?: string | null
          course_id: string
          enrolled_at?: string
          id?: string
          order_id?: string | null
          progress?: number
          status?: string
          user_id: string
        }
        Update: {
          completed_at?: string | null
          course_id?: string
          enrolled_at?: string
          id?: string
          order_id?: string | null
          progress?: number
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_enrollments_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "academy_courses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_enrollments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "academy_enrollments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_instructors: {
        Row: {
          bio: string | null
          created_at: string
          display_name: string
          expertise: string[] | null
          id: string
          is_active: boolean
          updated_at: string
          user_id: string | null
        }
        Insert: {
          bio?: string | null
          created_at?: string
          display_name: string
          expertise?: string[] | null
          id?: string
          is_active?: boolean
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          bio?: string | null
          created_at?: string
          display_name?: string
          expertise?: string[] | null
          id?: string
          is_active?: boolean
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      academy_resources: {
        Row: {
          course_id: string
          created_at: string
          due_at: string | null
          id: string
          resource_type: string
          resource_url: string
          title: string
        }
        Insert: {
          course_id: string
          created_at?: string
          due_at?: string | null
          id?: string
          resource_type?: string
          resource_url: string
          title: string
        }
        Update: {
          course_id?: string
          created_at?: string
          due_at?: string | null
          id?: string
          resource_type?: string
          resource_url?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "academy_resources_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "academy_courses"
            referencedColumns: ["id"]
          },
        ]
      }
      academy_sessions: {
        Row: {
          course_id: string
          ends_at: string | null
          id: string
          meeting_url: string | null
          starts_at: string | null
          status: string
          title: string
          venue: string | null
        }
        Insert: {
          course_id: string
          ends_at?: string | null
          id?: string
          meeting_url?: string | null
          starts_at?: string | null
          status?: string
          title: string
          venue?: string | null
        }
        Update: {
          course_id?: string
          ends_at?: string | null
          id?: string
          meeting_url?: string | null
          starts_at?: string | null
          status?: string
          title?: string
          venue?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "academy_sessions_course_id_fkey"
            columns: ["course_id"]
            isOneToOne: false
            referencedRelation: "academy_courses"
            referencedColumns: ["id"]
          },
        ]
      }
      account_deletion_requests: {
        Row: {
          anonymised: boolean
          approved_at: string | null
          cancelled_at: string | null
          completed_at: string | null
          finalised_by: string | null
          id: string
          reason: string | null
          requested_at: string
          resolution_note: string | null
          resolved_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          anonymised?: boolean
          approved_at?: string | null
          cancelled_at?: string | null
          completed_at?: string | null
          finalised_by?: string | null
          id?: string
          reason?: string | null
          requested_at?: string
          resolution_note?: string | null
          resolved_at?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          anonymised?: boolean
          approved_at?: string | null
          cancelled_at?: string | null
          completed_at?: string | null
          finalised_by?: string | null
          id?: string
          reason?: string | null
          requested_at?: string
          resolution_note?: string | null
          resolved_at?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      admin_product_access: {
        Row: {
          can_approve: boolean
          can_delete: boolean
          can_edit: boolean
          can_manage: boolean
          can_use_command_center: boolean
          can_use_website_builder: boolean
          can_view: boolean
          created_at: string
          id: string
          product: string
          user_id: string
        }
        Insert: {
          can_approve?: boolean
          can_delete?: boolean
          can_edit?: boolean
          can_manage?: boolean
          can_use_command_center?: boolean
          can_use_website_builder?: boolean
          can_view?: boolean
          created_at?: string
          id?: string
          product: string
          user_id: string
        }
        Update: {
          can_approve?: boolean
          can_delete?: boolean
          can_edit?: boolean
          can_manage?: boolean
          can_use_command_center?: boolean
          can_use_website_builder?: boolean
          can_view?: boolean
          created_at?: string
          id?: string
          product?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_product_access_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      app_device_security_preferences: {
        Row: {
          biometric_enabled: boolean
          device_id: string
          passcode_enabled: boolean
          platform: string
          product: string
          updated_at: string
          user_id: string
        }
        Insert: {
          biometric_enabled?: boolean
          device_id: string
          passcode_enabled?: boolean
          platform: string
          product: string
          updated_at?: string
          user_id: string
        }
        Update: {
          biometric_enabled?: boolean
          device_id?: string
          passcode_enabled?: boolean
          platform?: string
          product?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          id: number
          metadata: Json
          product: string | null
          target_id: string | null
          target_type: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          product?: string | null
          target_id?: string | null
          target_type?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          product?: string | null
          target_id?: string | null
          target_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_catalog: {
        Row: {
          base_price: number | null
          category: string
          created_at: string
          description: string | null
          features: Json
          id: string
          is_active: boolean
          name: string
          pricing_unit: string | null
          slug: string
          unit_code: string
          updated_at: string
        }
        Insert: {
          base_price?: number | null
          category: string
          created_at?: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          name: string
          pricing_unit?: string | null
          slug: string
          unit_code: string
          updated_at?: string
        }
        Update: {
          base_price?: number | null
          category?: string
          created_at?: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          name?: string
          pricing_unit?: string | null
          slug?: string
          unit_code?: string
          updated_at?: string
        }
        Relationships: []
      }
      business_files: {
        Row: {
          created_at: string
          file_name: string
          file_type: string | null
          file_url: string
          id: string
          order_id: string
          storage_path: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          file_name: string
          file_type?: string | null
          file_url: string
          id?: string
          order_id: string
          storage_path?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          file_name?: string
          file_type?: string | null
          file_url?: string
          id?: string
          order_id?: string
          storage_path?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_files_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_files_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_invoices: {
        Row: {
          amount: number
          amount_paid: number
          cancelled_from_status: string | null
          created_at: string
          currency: string
          due_at: string | null
          id: string
          invoice_number: string
          order_id: string
          quotation_id: string | null
          replaces_invoice_id: string | null
          service_description: string | null
          service_name: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id: string
          quotation_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id?: string
          quotation_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_invoices_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_invoices_quotation_id_fkey"
            columns: ["quotation_id"]
            isOneToOne: false
            referencedRelation: "business_quotes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_invoices_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "business_invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      business_notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          read_at: string | null
          title: string
          unit_code: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          read_at?: string | null
          title: string
          unit_code: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          read_at?: string | null
          title?: string
          unit_code?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_orders: {
        Row: {
          amount: number | null
          created_at: string
          currency: string
          delivery_method: string | null
          due_at: string | null
          id: string
          order_number: string
          quantity: number | null
          requirements: string
          service_id: string | null
          specifications: Json
          status: string
          title: string
          unit_code: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount?: number | null
          created_at?: string
          currency?: string
          delivery_method?: string | null
          due_at?: string | null
          id?: string
          order_number?: string
          quantity?: number | null
          requirements: string
          service_id?: string | null
          specifications?: Json
          status?: string
          title: string
          unit_code: string
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number | null
          created_at?: string
          currency?: string
          delivery_method?: string | null
          due_at?: string | null
          id?: string
          order_number?: string
          quantity?: number | null
          requirements?: string
          service_id?: string | null
          specifications?: Json
          status?: string
          title?: string
          unit_code?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_orders_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "business_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_orders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_payment_intents: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          order_id: string
          paid_at: string | null
          reference: string
          status: string
          transaction_ref: string | null
          unit_code: string
          updated_at: string
          user_id: string
          virtual_account_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          order_id: string
          paid_at?: string | null
          reference: string
          status?: string
          transaction_ref?: string | null
          unit_code: string
          updated_at?: string
          user_id: string
          virtual_account_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          order_id?: string
          paid_at?: string | null
          reference?: string
          status?: string
          transaction_ref?: string | null
          unit_code?: string
          updated_at?: string
          user_id?: string
          virtual_account_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "business_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_payment_intents_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_payment_intents_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      business_payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          invoice_id: string
          paid_at: string | null
          provider_reference: string | null
          status: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id: string
          paid_at?: string | null
          provider_reference?: string | null
          status?: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id?: string
          paid_at?: string | null
          provider_reference?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "business_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_payments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_production_jobs: {
        Row: {
          assigned_to: string | null
          completed_at: string | null
          id: string
          notes: string | null
          order_id: string
          progress: number
          qc_status: string
          stage: string
          started_at: string | null
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          completed_at?: string | null
          id?: string
          notes?: string | null
          order_id: string
          progress?: number
          qc_status?: string
          stage?: string
          started_at?: string | null
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          completed_at?: string | null
          id?: string
          notes?: string | null
          order_id?: string
          progress?: number
          qc_status?: string
          stage?: string
          started_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_production_jobs_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_production_jobs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      business_quotes: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          notes: string | null
          order_id: string
          quote_number: string
          status: string
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          notes?: string | null
          order_id: string
          quote_number?: string
          status?: string
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          notes?: string | null
          order_id?: string
          quote_number?: string
          status?: string
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_quotes_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      business_support_tickets: {
        Row: {
          admin_response: string | null
          created_at: string
          id: string
          message: string
          priority: string
          status: string
          subject: string
          unit_code: string
          updated_at: string
          user_id: string
        }
        Insert: {
          admin_response?: string | null
          created_at?: string
          id?: string
          message: string
          priority?: string
          status?: string
          subject: string
          unit_code: string
          updated_at?: string
          user_id: string
        }
        Update: {
          admin_response?: string | null
          created_at?: string
          id?: string
          message?: string
          priority?: string
          status?: string
          subject?: string
          unit_code?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_support_tickets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      business_units: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          name: string
          parent_code: string | null
          status: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          parent_code?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          parent_code?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      compute_jobs: {
        Row: {
          compute_profile: string | null
          created_at: string
          dataset_notes: string | null
          estimated_hours: number | null
          id: string
          order_id: string
          status: string
          updated_at: string
          workload_type: string
        }
        Insert: {
          compute_profile?: string | null
          created_at?: string
          dataset_notes?: string | null
          estimated_hours?: number | null
          id?: string
          order_id: string
          status?: string
          updated_at?: string
          workload_type: string
        }
        Update: {
          compute_profile?: string | null
          created_at?: string
          dataset_notes?: string | null
          estimated_hours?: number | null
          id?: string
          order_id?: string
          status?: string
          updated_at?: string
          workload_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "compute_jobs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      compute_usage_records: {
        Row: {
          created_at: string
          credits_used: number
          ended_at: string | null
          equipment_id: string | null
          hours: number
          id: string
          notes: string | null
          order_id: string
          started_at: string | null
        }
        Insert: {
          created_at?: string
          credits_used?: number
          ended_at?: string | null
          equipment_id?: string | null
          hours: number
          id?: string
          notes?: string | null
          order_id: string
          started_at?: string | null
        }
        Update: {
          created_at?: string
          credits_used?: number
          ended_at?: string | null
          equipment_id?: string | null
          hours?: number
          id?: string
          notes?: string | null
          order_id?: string
          started_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "compute_usage_records_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compute_usage_records_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_activity_logs: {
        Row: {
          action: string
          actor_user_id: string | null
          created_at: string | null
          details: Json
          id: string
          project_id: string | null
        }
        Insert: {
          action: string
          actor_user_id?: string | null
          created_at?: string | null
          details?: Json
          id?: string
          project_id?: string | null
        }
        Update: {
          action?: string
          actor_user_id?: string | null
          created_at?: string | null
          details?: Json
          id?: string
          project_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consult_activity_logs_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_change_requests: {
        Row: {
          cost_impact: number | null
          created_at: string
          description: string
          id: string
          project_id: string
          schedule_impact_days: number | null
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          cost_impact?: number | null
          created_at?: string
          description: string
          id?: string
          project_id: string
          schedule_impact_days?: number | null
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          cost_impact?: number | null
          created_at?: string
          description?: string
          id?: string
          project_id?: string
          schedule_impact_days?: number | null
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_change_requests_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_change_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_contracts: {
        Row: {
          accepted_at: string | null
          body: string
          contract_number: string
          contract_type: string
          created_at: string
          id: string
          project_id: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          accepted_at?: string | null
          body?: string
          contract_number?: string
          contract_type?: string
          created_at?: string
          id?: string
          project_id: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          accepted_at?: string | null
          body?: string
          contract_number?: string
          contract_type?: string
          created_at?: string
          id?: string
          project_id?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_contracts_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_deliverables: {
        Row: {
          client_feedback: string | null
          created_at: string
          description: string | null
          file_url: string | null
          id: string
          milestone_id: string | null
          project_id: string
          reviewed_at: string | null
          status: string
          submitted_at: string | null
          title: string
          updated_at: string
        }
        Insert: {
          client_feedback?: string | null
          created_at?: string
          description?: string | null
          file_url?: string | null
          id?: string
          milestone_id?: string | null
          project_id: string
          reviewed_at?: string | null
          status?: string
          submitted_at?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          client_feedback?: string | null
          created_at?: string
          description?: string | null
          file_url?: string | null
          id?: string
          milestone_id?: string | null
          project_id?: string
          reviewed_at?: string | null
          status?: string
          submitted_at?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_deliverables_milestone_id_fkey"
            columns: ["milestone_id"]
            isOneToOne: false
            referencedRelation: "consult_milestones"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_deliverables_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_documents: {
        Row: {
          category: string
          created_at: string
          id: string
          mime_type: string | null
          original_filename: string
          owner_id: string
          project_id: string | null
          proposal_id: string | null
          request_id: string | null
          storage_path: string
          title: string
          version: number
        }
        Insert: {
          category: string
          created_at?: string
          id?: string
          mime_type?: string | null
          original_filename: string
          owner_id: string
          project_id?: string | null
          proposal_id?: string | null
          request_id?: string | null
          storage_path: string
          title: string
          version?: number
        }
        Update: {
          category?: string
          created_at?: string
          id?: string
          mime_type?: string | null
          original_filename?: string
          owner_id?: string
          project_id?: string | null
          proposal_id?: string | null
          request_id?: string | null
          storage_path?: string
          title?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "consult_documents_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_documents_proposal_id_fkey"
            columns: ["proposal_id"]
            isOneToOne: false
            referencedRelation: "consult_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_documents_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "consult_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_invoices: {
        Row: {
          amount: number
          amount_paid: number
          cancelled_from_status: string | null
          created_at: string
          currency: string
          due_at: string | null
          id: string
          invoice_number: string
          paid_at: string | null
          payment_reference: string | null
          project_id: string
          proposal_id: string | null
          quotation_id: string | null
          replaces_invoice_id: string | null
          service_description: string | null
          service_name: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          amount: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          paid_at?: string | null
          payment_reference?: string | null
          project_id: string
          proposal_id?: string | null
          quotation_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          amount?: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          paid_at?: string | null
          payment_reference?: string | null
          project_id?: string
          proposal_id?: string | null
          quotation_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_invoices_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_invoices_proposal_id_fkey"
            columns: ["proposal_id"]
            isOneToOne: false
            referencedRelation: "consult_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_invoices_quotation_id_fkey"
            columns: ["quotation_id"]
            isOneToOne: false
            referencedRelation: "consult_quotations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_invoices_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "consult_invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_messages: {
        Row: {
          body: string
          created_at: string
          id: string
          project_id: string
          sender_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          project_id: string
          sender_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          project_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_messages_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_milestones: {
        Row: {
          created_at: string
          description: string | null
          due_at: string | null
          id: string
          project_id: string
          sort_order: number
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          due_at?: string | null
          id?: string
          project_id: string
          sort_order?: number
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          due_at?: string | null
          id?: string
          project_id?: string
          sort_order?: number
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_milestones_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          kind: string
          project_id: string | null
          read_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          kind?: string
          project_id?: string | null
          read_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          kind?: string
          project_id?: string | null
          read_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_notifications_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_organizations: {
        Row: {
          address: string | null
          billing_email: string | null
          created_at: string | null
          id: string
          name: string
          owner_user_id: string
          phone: string | null
        }
        Insert: {
          address?: string | null
          billing_email?: string | null
          created_at?: string | null
          id?: string
          name: string
          owner_user_id: string
          phone?: string | null
        }
        Update: {
          address?: string | null
          billing_email?: string | null
          created_at?: string | null
          id?: string
          name?: string
          owner_user_id?: string
          phone?: string | null
        }
        Relationships: []
      }
      consult_payment_intents: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          paid_at: string | null
          project_id: string
          reference: string
          status: string
          transaction_ref: string | null
          updated_at: string
          user_id: string
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          paid_at?: string | null
          project_id: string
          reference: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id: string
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          paid_at?: string | null
          project_id?: string
          reference?: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id?: string
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consult_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "consult_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_payment_intents_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_payments: {
        Row: {
          amount: number
          created_at: string
          description: string
          due_at: string | null
          id: string
          paid_at: string | null
          payment_reference: string
          project_id: string
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          description: string
          due_at?: string | null
          id?: string
          paid_at?: string | null
          payment_reference?: string
          project_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          description?: string
          due_at?: string | null
          id?: string
          paid_at?: string | null
          payment_reference?: string
          project_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_payments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_projects: {
        Row: {
          created_at: string
          due_at: string | null
          id: string
          name: string
          outstanding_amount: number
          progress: number
          project_manager: string | null
          project_number: string
          quoted_amount: number | null
          request_id: string | null
          service_category: string
          stage: string
          started_at: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          due_at?: string | null
          id?: string
          name: string
          outstanding_amount?: number
          progress?: number
          project_manager?: string | null
          project_number?: string
          quoted_amount?: number | null
          request_id?: string | null
          service_category: string
          stage?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          due_at?: string | null
          id?: string
          name?: string
          outstanding_amount?: number
          progress?: number
          project_manager?: string | null
          project_number?: string
          quoted_amount?: number | null
          request_id?: string | null
          service_category?: string
          stage?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_projects_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "consult_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_proposals: {
        Row: {
          accepted_at: string | null
          created_at: string
          id: string
          mime_type: string | null
          notes: string | null
          original_filename: string
          project_id: string
          rejected_at: string | null
          revision_requested_at: string | null
          status: string
          storage_path: string
          title: string
          updated_at: string
          user_id: string
          valid_until: string | null
          version: number
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          id?: string
          mime_type?: string | null
          notes?: string | null
          original_filename: string
          project_id: string
          rejected_at?: string | null
          revision_requested_at?: string | null
          status?: string
          storage_path: string
          title: string
          updated_at?: string
          user_id: string
          valid_until?: string | null
          version?: number
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          id?: string
          mime_type?: string | null
          notes?: string | null
          original_filename?: string
          project_id?: string
          rejected_at?: string | null
          revision_requested_at?: string | null
          status?: string
          storage_path?: string
          title?: string
          updated_at?: string
          user_id?: string
          valid_until?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "consult_proposals_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_quotations: {
        Row: {
          amount: number
          created_at: string
          id: string
          project_id: string
          quote_number: string
          scope_summary: string
          status: string
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          project_id: string
          quote_number?: string
          scope_summary: string
          status?: string
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          project_id?: string
          quote_number?: string
          scope_summary?: string
          status?: string
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consult_quotations_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_requests: {
        Row: {
          admin_notes: string | null
          budget_range: string | null
          company_name: string | null
          created_at: string
          description: string
          engagement_type: string | null
          id: string
          meeting_format: string | null
          preferred_date: string | null
          preferred_time: string | null
          request_number: string
          request_type: string
          service_category: string
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          admin_notes?: string | null
          budget_range?: string | null
          company_name?: string | null
          created_at?: string
          description: string
          engagement_type?: string | null
          id?: string
          meeting_format?: string | null
          preferred_date?: string | null
          preferred_time?: string | null
          request_number?: string
          request_type: string
          service_category: string
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          admin_notes?: string | null
          budget_range?: string | null
          company_name?: string | null
          created_at?: string
          description?: string
          engagement_type?: string | null
          id?: string
          meeting_format?: string | null
          preferred_date?: string | null
          preferred_time?: string | null
          request_number?: string
          request_type?: string
          service_category?: string
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      consult_retainers: {
        Row: {
          amount: number
          billing_cycle: string
          created_at: string | null
          id: string
          name: string
          next_billing_date: string | null
          project_id: string
          status: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          amount: number
          billing_cycle?: string
          created_at?: string | null
          id?: string
          name: string
          next_billing_date?: string | null
          project_id: string
          status?: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          billing_cycle?: string
          created_at?: string | null
          id?: string
          name?: string
          next_billing_date?: string | null
          project_id?: string
          status?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_retainers_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_reviews: {
        Row: {
          comment: string | null
          created_at: string | null
          id: string
          project_id: string
          publish_status: string
          rating: number
          user_id: string
        }
        Insert: {
          comment?: string | null
          created_at?: string | null
          id?: string
          project_id: string
          publish_status?: string
          rating: number
          user_id: string
        }
        Update: {
          comment?: string | null
          created_at?: string | null
          id?: string
          project_id?: string
          publish_status?: string
          rating?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_reviews_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_service_catalog: {
        Row: {
          category: string
          created_at: string | null
          description: string | null
          id: string
          is_active: boolean
          name: string
          slug: string
          sort_order: number
          starting_price: number | null
          typical_timeline: string | null
          updated_at: string | null
        }
        Insert: {
          category: string
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          slug: string
          sort_order?: number
          starting_price?: number | null
          typical_timeline?: string | null
          updated_at?: string | null
        }
        Update: {
          category?: string
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          sort_order?: number
          starting_price?: number | null
          typical_timeline?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      consult_team_members: {
        Row: {
          created_at: string
          display_name: string
          id: string
          is_active: boolean
          member_user_id: string | null
          project_id: string
          role_title: string
        }
        Insert: {
          created_at?: string
          display_name: string
          id?: string
          is_active?: boolean
          member_user_id?: string | null
          project_id: string
          role_title: string
        }
        Update: {
          created_at?: string
          display_name?: string
          id?: string
          is_active?: boolean
          member_user_id?: string | null
          project_id?: string
          role_title?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_team_members_member_user_id_fkey"
            columns: ["member_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consult_team_members_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      consult_time_entries: {
        Row: {
          billable: boolean
          created_at: string | null
          description: string
          hours: number
          id: string
          project_id: string
          user_id: string | null
          work_date: string
        }
        Insert: {
          billable?: boolean
          created_at?: string | null
          description: string
          hours: number
          id?: string
          project_id: string
          user_id?: string | null
          work_date?: string
        }
        Update: {
          billable?: boolean
          created_at?: string | null
          description?: string
          hours?: number
          id?: string
          project_id?: string
          user_id?: string | null
          work_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "consult_time_entries_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "consult_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      cost_centres: {
        Row: {
          business_unit_id: string | null
          code: string
          created_at: string
          id: string
          is_active: boolean
          name: string
        }
        Insert: {
          business_unit_id?: string | null
          code: string
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
        }
        Update: {
          business_unit_id?: string | null
          code?: string
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "cost_centres_business_unit_id_fkey"
            columns: ["business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_service_access: {
        Row: {
          activated_at: string | null
          created_at: string
          id: string
          last_opened_at: string | null
          plan_name: string | null
          product: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          activated_at?: string | null
          created_at?: string
          id?: string
          last_opened_at?: string | null
          plan_name?: string | null
          product: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          activated_at?: string | null
          created_at?: string
          id?: string
          last_opened_at?: string | null
          plan_name?: string | null
          product?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_service_access_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_airtime_conversion_requests: {
        Row: {
          airtime_amount: number
          created_at: string
          id: string
          network: string
          provider_reference: string | null
          quoted_cash_amount: number | null
          sender_phone: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          airtime_amount: number
          created_at?: string
          id?: string
          network: string
          provider_reference?: string | null
          quoted_cash_amount?: number | null
          sender_phone: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          airtime_amount?: number
          created_at?: string
          id?: string
          network?: string
          provider_reference?: string | null
          quoted_cash_amount?: number | null
          sender_phone?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_airtime_conversion_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_api_credentials: {
        Row: {
          created_at: string
          expires_at: string | null
          id: string
          key_hash: string
          key_prefix: string
          label: string
          last_used_at: string | null
          mode: string
          revoked_at: string | null
          status: string
          user_id: string
        }
        Insert: {
          created_at?: string
          expires_at?: string | null
          id?: string
          key_hash: string
          key_prefix: string
          label: string
          last_used_at?: string | null
          mode: string
          revoked_at?: string | null
          status?: string
          user_id: string
        }
        Update: {
          created_at?: string
          expires_at?: string | null
          id?: string
          key_hash?: string
          key_prefix?: string
          label?: string
          last_used_at?: string | null
          mode?: string
          revoked_at?: string | null
          status?: string
          user_id?: string
        }
        Relationships: []
      }
      datasub_api_usage: {
        Row: {
          created_at: string
          credential_id: string
          endpoint: string
          id: number
          method: string
          request_units: number
          response_ms: number
          status_code: number
          user_id: string
        }
        Insert: {
          created_at?: string
          credential_id: string
          endpoint: string
          id?: never
          method: string
          request_units?: number
          response_ms?: number
          status_code: number
          user_id: string
        }
        Update: {
          created_at?: string
          credential_id?: string
          endpoint?: string
          id?: never
          method?: string
          request_units?: number
          response_ms?: number
          status_code?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_api_usage_credential_id_fkey"
            columns: ["credential_id"]
            isOneToOne: false
            referencedRelation: "datasub_api_credentials"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_api_webhooks: {
        Row: {
          active: boolean
          created_at: string
          events: string[]
          id: string
          secret_hash: string | null
          url: string
          user_id: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          events?: string[]
          id?: string
          secret_hash?: string | null
          url: string
          user_id: string
        }
        Update: {
          active?: boolean
          created_at?: string
          events?: string[]
          id?: string
          secret_hash?: string | null
          url?: string
          user_id?: string
        }
        Relationships: []
      }
      datasub_beneficiaries: {
        Row: {
          created_at: string
          id: string
          name: string
          provider: string
          recipient: string
          service_type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          provider: string
          recipient: string
          service_type: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          provider?: string
          recipient?: string
          service_type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_beneficiaries_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_bulk_jobs: {
        Row: {
          created_at: string
          failed_items: number
          id: string
          processed_items: number
          service_type: string
          status: string
          total_items: number
          user_id: string
        }
        Insert: {
          created_at?: string
          failed_items?: number
          id?: string
          processed_items?: number
          service_type: string
          status?: string
          total_items?: number
          user_id: string
        }
        Update: {
          created_at?: string
          failed_items?: number
          id?: string
          processed_items?: number
          service_type?: string
          status?: string
          total_items?: number
          user_id?: string
        }
        Relationships: []
      }
      datasub_catalog_availability: {
        Row: {
          healthy_route_count: number
          offering_id: string
          provider_available: boolean
          updated_at: string
        }
        Insert: {
          healthy_route_count?: number
          offering_id: string
          provider_available?: boolean
          updated_at?: string
        }
        Update: {
          healthy_route_count?: number
          offering_id?: string
          provider_available?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_catalog_availability_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: true
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_catalog_availability_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: true
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_catalog_availability_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: true
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_catalog_import_text: {
        Row: {
          csv_text: string
          provider: string
        }
        Insert: {
          csv_text: string
          provider: string
        }
        Update: {
          csv_text?: string
          provider?: string
        }
        Relationships: []
      }
      datasub_catalog_offerings: {
        Row: {
          api_price: number
          base_provider_cost: number
          created_at: string
          customer_enabled: boolean
          id: string
          ihlink_plan_id: string
          markup_policy: Json
          name: string
          network: string | null
          plan_type: string | null
          reseller_price: number
          service_type: string
          smart_earner_price: number
          spec_key: string
          top_seller_price: number
          updated_at: string
          validity: string | null
        }
        Insert: {
          api_price?: number
          base_provider_cost?: number
          created_at?: string
          customer_enabled?: boolean
          id?: string
          ihlink_plan_id: string
          markup_policy?: Json
          name: string
          network?: string | null
          plan_type?: string | null
          reseller_price?: number
          service_type: string
          smart_earner_price?: number
          spec_key: string
          top_seller_price?: number
          updated_at?: string
          validity?: string | null
        }
        Update: {
          api_price?: number
          base_provider_cost?: number
          created_at?: string
          customer_enabled?: boolean
          id?: string
          ihlink_plan_id?: string
          markup_policy?: Json
          name?: string
          network?: string | null
          plan_type?: string | null
          reseller_price?: number
          service_type?: string
          smart_earner_price?: number
          spec_key?: string
          top_seller_price?: number
          updated_at?: string
          validity?: string | null
        }
        Relationships: []
      }
      datasub_catalog_routes: {
        Row: {
          created_at: string
          id: string
          offering_id: string
          price_difference: number
          priority: number
          route_enabled: boolean
          upstream_catalog_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          offering_id: string
          price_difference?: number
          priority?: number
          route_enabled?: boolean
          upstream_catalog_id: string
        }
        Update: {
          created_at?: string
          id?: string
          offering_id?: string
          price_difference?: number
          priority?: number
          route_enabled?: boolean
          upstream_catalog_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_catalog_routes_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_catalog_routes_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_catalog_routes_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_catalog_routes_upstream_catalog_id_fkey"
            columns: ["upstream_catalog_id"]
            isOneToOne: false
            referencedRelation: "datasub_upstream_catalog"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_disputes: {
        Row: {
          category: string
          created_at: string
          details: string
          id: string
          resolution: string | null
          status: string
          transaction_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          category: string
          created_at?: string
          details: string
          id?: string
          resolution?: string | null
          status?: string
          transaction_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          category?: string
          created_at?: string
          details?: string
          id?: string
          resolution?: string | null
          status?: string
          transaction_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_disputes_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_favourites: {
        Row: {
          created_at: string
          id: string
          label: string | null
          offering_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          label?: string | null
          offering_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          label?: string | null
          offering_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_favourites_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_favourites_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_favourites_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_network_availability: {
        Row: {
          available: boolean
          checked_at: string
          evidence_source: string
          network: string
          provider_id: string
          service_type: string
        }
        Insert: {
          available: boolean
          checked_at?: string
          evidence_source: string
          network: string
          provider_id: string
          service_type: string
        }
        Update: {
          available?: boolean
          checked_at?: string
          evidence_source?: string
          network?: string
          provider_id?: string
          service_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_network_availability_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_pin_recovery_attempts: {
        Row: {
          attempts: number
          user_id: string
          window_started_at: string
        }
        Insert: {
          attempts?: number
          user_id: string
          window_started_at?: string
        }
        Update: {
          attempts?: number
          user_id?: string
          window_started_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_pin_recovery_attempts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_prices: {
        Row: {
          active: boolean
          customer_tier: string
          effective_from: string
          id: string
          product_id: string
          selling_price: number
        }
        Insert: {
          active?: boolean
          customer_tier: string
          effective_from?: string
          id?: string
          product_id: string
          selling_price: number
        }
        Update: {
          active?: boolean
          customer_tier?: string
          effective_from?: string
          id?: string
          product_id?: string
          selling_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "datasub_prices_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "datasub_products"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_pricing_audit: {
        Row: {
          action: string
          changed_by: string | null
          created_at: string
          field_name: string | null
          id: string
          new_value: Json | null
          offering_id: string | null
          old_value: Json | null
          provider_id: string | null
          reason: string | null
        }
        Insert: {
          action: string
          changed_by?: string | null
          created_at?: string
          field_name?: string | null
          id?: string
          new_value?: Json | null
          offering_id?: string | null
          old_value?: Json | null
          provider_id?: string | null
          reason?: string | null
        }
        Update: {
          action?: string
          changed_by?: string | null
          created_at?: string
          field_name?: string | null
          id?: string
          new_value?: Json | null
          offering_id?: string | null
          old_value?: Json | null
          provider_id?: string | null
          reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_pricing_audit_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_pricing_audit_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_pricing_audit_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_pricing_audit_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_products: {
        Row: {
          api_price: number
          catalogue_source: string
          code: string
          created_at: string
          description: string | null
          id: string
          internal_plan_id: string | null
          is_active: boolean
          markup_policy: Json
          metadata: Json
          name: string
          plan_category: string | null
          provider: string
          provider_cost: number
          provider_plan_id: string | null
          reseller_price: number
          retail_price: number
          routing_priority: number
          service_type: string
          sort_order: number
          updated_at: string
          validity_label: string | null
        }
        Insert: {
          api_price: number
          catalogue_source?: string
          code: string
          created_at?: string
          description?: string | null
          id?: string
          internal_plan_id?: string | null
          is_active?: boolean
          markup_policy?: Json
          metadata?: Json
          name: string
          plan_category?: string | null
          provider: string
          provider_cost: number
          provider_plan_id?: string | null
          reseller_price: number
          retail_price: number
          routing_priority?: number
          service_type: string
          sort_order?: number
          updated_at?: string
          validity_label?: string | null
        }
        Update: {
          api_price?: number
          catalogue_source?: string
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          internal_plan_id?: string | null
          is_active?: boolean
          markup_policy?: Json
          metadata?: Json
          name?: string
          plan_category?: string | null
          provider?: string
          provider_cost?: number
          provider_plan_id?: string | null
          reseller_price?: number
          retail_price?: number
          routing_priority?: number
          service_type?: string
          sort_order?: number
          updated_at?: string
          validity_label?: string | null
        }
        Relationships: []
      }
      datasub_provider_activation_checks: {
        Row: {
          balance_verified: boolean
          callback_verified: boolean
          catalogue_verified: boolean
          checked_at: string
          checked_by: string | null
          credentials_configured: boolean
          health_verified: boolean
          notes: string | null
          provider_id: string
          routing_verified: boolean
        }
        Insert: {
          balance_verified?: boolean
          callback_verified?: boolean
          catalogue_verified?: boolean
          checked_at?: string
          checked_by?: string | null
          credentials_configured?: boolean
          health_verified?: boolean
          notes?: string | null
          provider_id: string
          routing_verified?: boolean
        }
        Update: {
          balance_verified?: boolean
          callback_verified?: boolean
          catalogue_verified?: boolean
          checked_at?: string
          checked_by?: string | null
          credentials_configured?: boolean
          health_verified?: boolean
          notes?: string | null
          provider_id?: string
          routing_verified?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_activation_checks_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: true
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_provider_attempts: {
        Row: {
          created_at: string
          id: string
          is_ambiguous: boolean
          latency_ms: number | null
          provider_cost: number
          provider_id: string
          provider_path: string | null
          provider_reference: string | null
          reconciled_at: string | null
          request_key: string
          request_payload: Json
          response_status: string
          safe_response: Json
          transaction_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_ambiguous?: boolean
          latency_ms?: number | null
          provider_cost: number
          provider_id: string
          provider_path?: string | null
          provider_reference?: string | null
          reconciled_at?: string | null
          request_key: string
          request_payload?: Json
          response_status: string
          safe_response?: Json
          transaction_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_ambiguous?: boolean
          latency_ms?: number | null
          provider_cost?: number
          provider_id?: string
          provider_path?: string | null
          provider_reference?: string | null
          reconciled_at?: string | null
          request_key?: string
          request_payload?: Json
          response_status?: string
          safe_response?: Json
          transaction_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_attempts_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_provider_attempts_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_provider_connections: {
        Row: {
          available_balance: number | null
          average_response_ms: number | null
          code: string
          display_name: string
          is_active: boolean
          last_callback_at: string | null
          priority: number
          status: string
          success_rate: number
          token_hash: string | null
          token_prefix: string | null
          updated_at: string
        }
        Insert: {
          available_balance?: number | null
          average_response_ms?: number | null
          code: string
          display_name: string
          is_active?: boolean
          last_callback_at?: string | null
          priority?: number
          status?: string
          success_rate?: number
          token_hash?: string | null
          token_prefix?: string | null
          updated_at?: string
        }
        Update: {
          available_balance?: number | null
          average_response_ms?: number | null
          code?: string
          display_name?: string
          is_active?: boolean
          last_callback_at?: string | null
          priority?: number
          status?: string
          success_rate?: number
          token_hash?: string | null
          token_prefix?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      datasub_provider_events: {
        Row: {
          created_at: string
          external_event_id: string
          id: string
          payload: Json
          processing_result: string
          provider_code: string
          provider_reference: string | null
          received_status: string
          response_ms: number | null
          transaction_reference: string | null
        }
        Insert: {
          created_at?: string
          external_event_id: string
          id?: string
          payload?: Json
          processing_result?: string
          provider_code: string
          provider_reference?: string | null
          received_status: string
          response_ms?: number | null
          transaction_reference?: string | null
        }
        Update: {
          created_at?: string
          external_event_id?: string
          id?: string
          payload?: Json
          processing_result?: string
          provider_code?: string
          provider_reference?: string | null
          received_status?: string
          response_ms?: number | null
          transaction_reference?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_events_provider_code_fkey"
            columns: ["provider_code"]
            isOneToOne: false
            referencedRelation: "datasub_provider_connections"
            referencedColumns: ["code"]
          },
        ]
      }
      datasub_provider_health: {
        Row: {
          available_balance: number | null
          average_latency_ms: number | null
          consecutive_failures: number
          last_failure: string | null
          last_success: string | null
          p95_latency_ms: number | null
          provider_id: string
          state: string
          success_rate_15m: number | null
          success_rate_1h: number | null
          success_rate_24h: number | null
          timeout_rate_15m: number | null
          updated_at: string
        }
        Insert: {
          available_balance?: number | null
          average_latency_ms?: number | null
          consecutive_failures?: number
          last_failure?: string | null
          last_success?: string | null
          p95_latency_ms?: number | null
          provider_id: string
          state?: string
          success_rate_15m?: number | null
          success_rate_1h?: number | null
          success_rate_24h?: number | null
          timeout_rate_15m?: number | null
          updated_at?: string
        }
        Update: {
          available_balance?: number | null
          average_latency_ms?: number | null
          consecutive_failures?: number
          last_failure?: string | null
          last_success?: string | null
          p95_latency_ms?: number | null
          provider_id?: string
          state?: string
          success_rate_15m?: number | null
          success_rate_1h?: number | null
          success_rate_24h?: number | null
          timeout_rate_15m?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_health_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: true
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_provider_products: {
        Row: {
          active: boolean
          external_plan_id: string
          id: string
          last_synced_at: string | null
          product_id: string
          provider_cost: number
          provider_id: string
          raw_metadata: Json
        }
        Insert: {
          active?: boolean
          external_plan_id: string
          id?: string
          last_synced_at?: string | null
          product_id: string
          provider_cost: number
          provider_id: string
          raw_metadata?: Json
        }
        Update: {
          active?: boolean
          external_plan_id?: string
          id?: string
          last_synced_at?: string | null
          product_id?: string
          provider_cost?: number
          provider_id?: string
          raw_metadata?: Json
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_products_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "datasub_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_provider_products_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_provider_webhook_events: {
        Row: {
          id: string
          payload: Json
          processed: boolean
          processed_at: string | null
          provider_id: string
          received_at: string
          request_id: string
          response_text: string | null
          status: string
          transaction_id: string | null
        }
        Insert: {
          id?: string
          payload?: Json
          processed?: boolean
          processed_at?: string | null
          provider_id: string
          received_at?: string
          request_id: string
          response_text?: string | null
          status: string
          transaction_id?: string | null
        }
        Update: {
          id?: string
          payload?: Json
          processed?: boolean
          processed_at?: string | null
          provider_id?: string
          received_at?: string
          request_id?: string
          response_text?: string | null
          status?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_provider_webhook_events_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_provider_webhook_events_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_providers: {
        Row: {
          available_balance: number | null
          code: string
          created_at: string
          display_name: string
          id: string
          is_active: boolean
          metadata: Json
          priority: number
          state: string
          updated_at: string
        }
        Insert: {
          available_balance?: number | null
          code: string
          created_at?: string
          display_name: string
          id?: string
          is_active?: boolean
          metadata?: Json
          priority?: number
          state?: string
          updated_at?: string
        }
        Update: {
          available_balance?: number | null
          code?: string
          created_at?: string
          display_name?: string
          id?: string
          is_active?: boolean
          metadata?: Json
          priority?: number
          state?: string
          updated_at?: string
        }
        Relationships: []
      }
      datasub_purchase_deliveries: {
        Row: {
          created_at: string
          details: Json
          transaction_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          details: Json
          transaction_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          details?: Json
          transaction_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_purchase_deliveries_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: true
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_referral_codes: {
        Row: {
          code: string
          created_at: string
          user_id: string
        }
        Insert: {
          code?: string
          created_at?: string
          user_id: string
        }
        Update: {
          code?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_referral_codes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_referral_invitees: {
        Row: {
          created_at: string
          referred_user_id: string
          referrer_user_id: string
        }
        Insert: {
          created_at?: string
          referred_user_id: string
          referrer_user_id: string
        }
        Update: {
          created_at?: string
          referred_user_id?: string
          referrer_user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_referral_invitees_referred_user_id_fkey"
            columns: ["referred_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_referral_invitees_referrer_user_id_fkey"
            columns: ["referrer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_referral_program: {
        Row: {
          enabled: boolean
          id: boolean
          minimum_purchase: number
          reward_amount: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          enabled?: boolean
          id?: boolean
          minimum_purchase?: number
          reward_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          enabled?: boolean
          id?: boolean
          minimum_purchase?: number
          reward_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_referral_program_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_referral_rewards: {
        Row: {
          amount: number
          approved_by: string
          created_at: string
          id: string
          reason: string
          referred_user_id: string
          referrer_user_id: string
          transaction_id: string
        }
        Insert: {
          amount: number
          approved_by: string
          created_at?: string
          id?: string
          reason: string
          referred_user_id: string
          referrer_user_id: string
          transaction_id: string
        }
        Update: {
          amount?: number
          approved_by?: string
          created_at?: string
          id?: string
          reason?: string
          referred_user_id?: string
          referrer_user_id?: string
          transaction_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_referral_rewards_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_referral_rewards_referred_user_id_fkey"
            columns: ["referred_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_referral_rewards_referrer_user_id_fkey"
            columns: ["referrer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_referral_rewards_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: true
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_referrals: {
        Row: {
          code: string
          commission: number
          created_at: string
          id: string
          referred_user_id: string | null
          referrer_user_id: string
          status: string
        }
        Insert: {
          code: string
          commission?: number
          created_at?: string
          id?: string
          referred_user_id?: string | null
          referrer_user_id: string
          status?: string
        }
        Update: {
          code?: string
          commission?: number
          created_at?: string
          id?: string
          referred_user_id?: string | null
          referrer_user_id?: string
          status?: string
        }
        Relationships: []
      }
      datasub_reseller_accounts: {
        Row: {
          api_access_approved: boolean
          api_approved_at: string | null
          api_approved_by: string | null
          api_website_url: string | null
          approved_at: string | null
          approved_by: string | null
          business_name: string
          created_at: string
          phone: string
          status: string
          tier_code: string
          total_profit: number
          total_sales: number
          updated_at: string
          user_id: string
        }
        Insert: {
          api_access_approved?: boolean
          api_approved_at?: string | null
          api_approved_by?: string | null
          api_website_url?: string | null
          approved_at?: string | null
          approved_by?: string | null
          business_name: string
          created_at?: string
          phone: string
          status?: string
          tier_code?: string
          total_profit?: number
          total_sales?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          api_access_approved?: boolean
          api_approved_at?: string | null
          api_approved_by?: string | null
          api_website_url?: string | null
          approved_at?: string | null
          approved_by?: string | null
          business_name?: string
          created_at?: string
          phone?: string
          status?: string
          tier_code?: string
          total_profit?: number
          total_sales?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_reseller_accounts_api_approved_by_fkey"
            columns: ["api_approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_reseller_accounts_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_reseller_accounts_tier_code_fkey"
            columns: ["tier_code"]
            isOneToOne: false
            referencedRelation: "datasub_reseller_tiers"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "datasub_reseller_accounts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_reseller_commissions: {
        Row: {
          calculation_basis: string
          commission_amount: number
          created_at: string
          id: string
          reseller_user_id: string
          sale_amount: number
          tier_code: string
          transaction_id: string
        }
        Insert: {
          calculation_basis: string
          commission_amount: number
          created_at?: string
          id?: string
          reseller_user_id: string
          sale_amount: number
          tier_code: string
          transaction_id: string
        }
        Update: {
          calculation_basis?: string
          commission_amount?: number
          created_at?: string
          id?: string
          reseller_user_id?: string
          sale_amount?: number
          tier_code?: string
          transaction_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_reseller_commissions_reseller_user_id_fkey"
            columns: ["reseller_user_id"]
            isOneToOne: false
            referencedRelation: "datasub_reseller_accounts"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "datasub_reseller_commissions_tier_code_fkey"
            columns: ["tier_code"]
            isOneToOne: false
            referencedRelation: "datasub_reseller_tiers"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "datasub_reseller_commissions_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: true
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_reseller_product_prices: {
        Row: {
          created_at: string
          is_active: boolean
          product_id: string
          reseller_plan_id: string
          reseller_user_id: string
          selling_price: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          is_active?: boolean
          product_id: string
          reseller_plan_id: string
          reseller_user_id: string
          selling_price: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          is_active?: boolean
          product_id?: string
          reseller_plan_id?: string
          reseller_user_id?: string
          selling_price?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_reseller_product_prices_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "datasub_products"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_reseller_tiers: {
        Row: {
          api_access: boolean
          code: string
          discount_percent: number
          is_active: boolean
          minimum_monthly_sales: number
          name: string
          sort_order: number
        }
        Insert: {
          api_access?: boolean
          code: string
          discount_percent: number
          is_active?: boolean
          minimum_monthly_sales?: number
          name: string
          sort_order?: number
        }
        Update: {
          api_access?: boolean
          code?: string
          discount_percent?: number
          is_active?: boolean
          minimum_monthly_sales?: number
          name?: string
          sort_order?: number
        }
        Relationships: []
      }
      datasub_routing_events: {
        Row: {
          created_at: string
          details: Json
          event_type: string
          id: string
          provider_id: string | null
          reason: string
          transaction_id: string | null
        }
        Insert: {
          created_at?: string
          details?: Json
          event_type: string
          id?: string
          provider_id?: string | null
          reason: string
          transaction_id?: string | null
        }
        Update: {
          created_at?: string
          details?: Json
          event_type?: string
          id?: string
          provider_id?: string | null
          reason?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_routing_events_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_routing_events_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_scheduled_purchases: {
        Row: {
          active: boolean
          amount: number | null
          created_at: string
          frequency: string
          id: string
          next_run_at: string
          offering_id: string
          recipient: string
          user_id: string
        }
        Insert: {
          active?: boolean
          amount?: number | null
          created_at?: string
          frequency?: string
          id?: string
          next_run_at: string
          offering_id: string
          recipient: string
          user_id: string
        }
        Update: {
          active?: boolean
          amount?: number | null
          created_at?: string
          frequency?: string
          id?: string
          next_run_at?: string
          offering_id?: string
          recipient?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_scheduled_purchases_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_scheduled_purchases_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_scheduled_purchases_offering_id_fkey"
            columns: ["offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_sms_campaigns: {
        Row: {
          created_at: string
          id: string
          message: string
          name: string
          recipient_count: number
          scheduled_at: string | null
          status: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message: string
          name: string
          recipient_count?: number
          scheduled_at?: string | null
          status?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string
          name?: string
          recipient_count?: number
          scheduled_at?: string | null
          status?: string
          user_id?: string
        }
        Relationships: []
      }
      datasub_spending_limits: {
        Row: {
          daily_limit: number | null
          id: string
          monthly_limit: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          daily_limit?: number | null
          id?: string
          monthly_limit?: number | null
          updated_at?: string
          user_id: string
        }
        Update: {
          daily_limit?: number | null
          id?: string
          monthly_limit?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      datasub_transaction_pins: {
        Row: {
          failed_attempts: number
          locked_until: string | null
          pin_hash: string
          updated_at: string
          user_id: string
        }
        Insert: {
          failed_attempts?: number
          locked_until?: string | null
          pin_hash: string
          updated_at?: string
          user_id: string
        }
        Update: {
          failed_attempts?: number
          locked_until?: string | null
          pin_hash?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_transaction_pins_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_transactions: {
        Row: {
          amount: number
          catalog_offering_id: string | null
          created_at: string
          id: string
          last_reconciled_at: string | null
          metadata: Json
          product_id: string | null
          provider: string
          provider_cost: number | null
          provider_reference: string | null
          recipient: string
          reference: string
          routing_state: string
          selling_price: number | null
          service_type: string
          status: Database["public"]["Enums"]["datasub_transaction_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          catalog_offering_id?: string | null
          created_at?: string
          id?: string
          last_reconciled_at?: string | null
          metadata?: Json
          product_id?: string | null
          provider: string
          provider_cost?: number | null
          provider_reference?: string | null
          recipient: string
          reference: string
          routing_state?: string
          selling_price?: number | null
          service_type: string
          status?: Database["public"]["Enums"]["datasub_transaction_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          catalog_offering_id?: string | null
          created_at?: string
          id?: string
          last_reconciled_at?: string | null
          metadata?: Json
          product_id?: string | null
          provider?: string
          provider_cost?: number | null
          provider_reference?: string | null
          recipient?: string
          reference?: string
          routing_state?: string
          selling_price?: number | null
          service_type?: string
          status?: Database["public"]["Enums"]["datasub_transaction_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_transactions_catalog_offering_id_fkey"
            columns: ["catalog_offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_admin_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_transactions_catalog_offering_id_fkey"
            columns: ["catalog_offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_catalog_offerings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_transactions_catalog_offering_id_fkey"
            columns: ["catalog_offering_id"]
            isOneToOne: false
            referencedRelation: "datasub_customer_catalogue"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_transactions_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "datasub_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_upgrade_offers: {
        Row: {
          api_access: boolean
          base_price: number
          benefits: Json
          code: string
          description: string
          is_active: boolean
          name: string
          promo_discount_percent: number
          promo_ends_at: string | null
          promo_starts_at: string | null
          sort_order: number
          target_tier_code: string | null
          updated_at: string
        }
        Insert: {
          api_access?: boolean
          base_price: number
          benefits?: Json
          code: string
          description?: string
          is_active?: boolean
          name: string
          promo_discount_percent?: number
          promo_ends_at?: string | null
          promo_starts_at?: string | null
          sort_order?: number
          target_tier_code?: string | null
          updated_at?: string
        }
        Update: {
          api_access?: boolean
          base_price?: number
          benefits?: Json
          code?: string
          description?: string
          is_active?: boolean
          name?: string
          promo_discount_percent?: number
          promo_ends_at?: string | null
          promo_starts_at?: string | null
          sort_order?: number
          target_tier_code?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_upgrade_offers_target_tier_code_fkey"
            columns: ["target_tier_code"]
            isOneToOne: false
            referencedRelation: "datasub_reseller_tiers"
            referencedColumns: ["code"]
          },
        ]
      }
      datasub_upgrade_requests: {
        Row: {
          contact_channel: string | null
          created_at: string
          id: string
          offer_code: string
          quoted_price: number
          request_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
          website_url: string | null
        }
        Insert: {
          contact_channel?: string | null
          created_at?: string
          id?: string
          offer_code: string
          quoted_price: number
          request_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id: string
          website_url?: string | null
        }
        Update: {
          contact_channel?: string | null
          created_at?: string
          id?: string
          offer_code?: string
          quoted_price?: number
          request_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          updated_at?: string
          user_id?: string
          website_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_upgrade_requests_offer_code_fkey"
            columns: ["offer_code"]
            isOneToOne: false
            referencedRelation: "datasub_upgrade_offers"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "datasub_upgrade_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_upgrade_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_upstream_catalog: {
        Row: {
          active: boolean
          currency: string
          external_plan_id: string
          id: string
          last_synced_at: string
          name: string
          network: string | null
          plan_type: string | null
          provider_cost: number
          provider_id: string
          raw_metadata: Json
          service_type: string
          validity: string | null
        }
        Insert: {
          active?: boolean
          currency?: string
          external_plan_id: string
          id?: string
          last_synced_at?: string
          name: string
          network?: string | null
          plan_type?: string | null
          provider_cost: number
          provider_id: string
          raw_metadata?: Json
          service_type: string
          validity?: string | null
        }
        Update: {
          active?: boolean
          currency?: string
          external_plan_id?: string
          id?: string
          last_synced_at?: string
          name?: string
          network?: string | null
          plan_type?: string | null
          provider_cost?: number
          provider_id?: string
          raw_metadata?: Json
          service_type?: string
          validity?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_upstream_catalog_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "datasub_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_voucher_batches: {
        Row: {
          created_at: string
          denomination: number
          id: string
          network: string
          provider_reference: string | null
          quantity: number
          status: string
          updated_at: string
          user_id: string
          voucher_type: string
        }
        Insert: {
          created_at?: string
          denomination: number
          id?: string
          network: string
          provider_reference?: string | null
          quantity: number
          status?: string
          updated_at?: string
          user_id: string
          voucher_type: string
        }
        Update: {
          created_at?: string
          denomination?: number
          id?: string
          network?: string
          provider_reference?: string | null
          quantity?: number
          status?: string
          updated_at?: string
          user_id?: string
          voucher_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_voucher_batches_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_wallet_funding_requests: {
        Row: {
          amount: number
          created_at: string
          id: string
          payment_method: string
          payment_reference: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["wallet_funding_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          payment_method: string
          payment_reference: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["wallet_funding_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          payment_method?: string
          payment_reference?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["wallet_funding_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_wallet_funding_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_wallet_funding_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_wallet_transfers: {
        Row: {
          amount: number
          created_at: string
          id: string
          recipient_account_id: string
          recipient_id: string
          request_id: string
          sender_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          recipient_account_id: string
          recipient_id: string
          request_id: string
          sender_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          recipient_account_id?: string
          recipient_id?: string
          request_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_wallet_transfers_recipient_account_id_fkey"
            columns: ["recipient_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_wallet_transfers_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_wallet_transfers_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_wallets: {
        Row: {
          balance: number
          currency: string
          referral_balance: number
          updated_at: string
          user_id: string
        }
        Insert: {
          balance?: number
          currency?: string
          referral_balance?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          balance?: number
          currency?: string
          referral_balance?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_wallets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_webhook_deliveries: {
        Row: {
          attempts: number
          created_at: string
          delivered_at: string | null
          event_type: string
          id: string
          last_error: string | null
          last_status_code: number | null
          locked_at: string | null
          next_attempt_at: string
          payload: Json
          status: string
          transaction_id: string
          user_id: string
          webhook_id: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          delivered_at?: string | null
          event_type: string
          id?: string
          last_error?: string | null
          last_status_code?: number | null
          locked_at?: string | null
          next_attempt_at?: string
          payload: Json
          status?: string
          transaction_id: string
          user_id: string
          webhook_id: string
        }
        Update: {
          attempts?: number
          created_at?: string
          delivered_at?: string | null
          event_type?: string
          id?: string
          last_error?: string | null
          last_status_code?: number | null
          locked_at?: string | null
          next_attempt_at?: string
          payload?: Json
          status?: string
          transaction_id?: string
          user_id?: string
          webhook_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "datasub_webhook_deliveries_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "datasub_webhook_deliveries_webhook_id_fkey"
            columns: ["webhook_id"]
            isOneToOne: false
            referencedRelation: "datasub_api_webhooks"
            referencedColumns: ["id"]
          },
        ]
      }
      digital_business_requests: {
        Row: {
          amount: number | null
          created_at: string
          details: string
          id: string
          service_type: string
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount?: number | null
          created_at?: string
          details: string
          id?: string
          service_type: string
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number | null
          created_at?: string
          details?: string
          id?: string
          service_type?: string
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "digital_business_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      direct_transfer_submissions: {
        Row: {
          admin_note: string | null
          amount: number
          bank_account_id: string
          created_at: string
          customer_reference: string
          id: string
          invoice_id: string | null
          platform_code: string
          proof_storage_path: string | null
          sender_bank: string | null
          sender_name: string
          source_reference: string
          status: string
          transferred_at: string | null
          updated_at: string
          user_id: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          admin_note?: string | null
          amount: number
          bank_account_id: string
          created_at?: string
          customer_reference: string
          id?: string
          invoice_id?: string | null
          platform_code: string
          proof_storage_path?: string | null
          sender_bank?: string | null
          sender_name: string
          source_reference: string
          status?: string
          transferred_at?: string | null
          updated_at?: string
          user_id: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          admin_note?: string | null
          amount?: number
          bank_account_id?: string
          created_at?: string
          customer_reference?: string
          id?: string
          invoice_id?: string | null
          platform_code?: string
          proof_storage_path?: string | null
          sender_bank?: string | null
          sender_name?: string
          source_reference?: string
          status?: string
          transferred_at?: string | null
          updated_at?: string
          user_id?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "direct_transfer_submissions_bank_account_id_fkey"
            columns: ["bank_account_id"]
            isOneToOne: false
            referencedRelation: "ihlink_bank_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_change_requests: {
        Row: {
          cost_impact: number | null
          created_at: string
          description: string
          id: string
          project_id: string
          schedule_impact_days: number | null
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          cost_impact?: number | null
          created_at?: string
          description: string
          id?: string
          project_id: string
          schedule_impact_days?: number | null
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          cost_impact?: number | null
          created_at?: string
          description?: string
          id?: string
          project_id?: string
          schedule_impact_days?: number | null
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_change_requests_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_change_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_documents: {
        Row: {
          approval_status: string
          created_at: string
          document_type: string
          file_url: string | null
          id: string
          notes: string | null
          project_id: string
          title: string
          updated_at: string
          version: string | null
        }
        Insert: {
          approval_status?: string
          created_at?: string
          document_type: string
          file_url?: string | null
          id?: string
          notes?: string | null
          project_id: string
          title: string
          updated_at?: string
          version?: string | null
        }
        Update: {
          approval_status?: string
          created_at?: string
          document_type?: string
          file_url?: string | null
          id?: string
          notes?: string | null
          project_id?: string
          title?: string
          updated_at?: string
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engineering_documents_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_equipment: {
        Row: {
          created_at: string
          id: string
          item_name: string
          project_id: string
          quantity: number
          specification: string | null
          status: string
          supplier: string | null
          unit: string
        }
        Insert: {
          created_at?: string
          id?: string
          item_name: string
          project_id: string
          quantity?: number
          specification?: string | null
          status?: string
          supplier?: string | null
          unit?: string
        }
        Update: {
          created_at?: string
          id?: string
          item_name?: string
          project_id?: string
          quantity?: number
          specification?: string | null
          status?: string
          supplier?: string | null
          unit?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_equipment_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_field_reports: {
        Row: {
          created_at: string
          created_by: string
          id: string
          issues: string | null
          next_actions: string | null
          observations: string | null
          project_id: string
          report_date: string
          work_completed: string
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          issues?: string | null
          next_actions?: string | null
          observations?: string | null
          project_id: string
          report_date?: string
          work_completed: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          issues?: string | null
          next_actions?: string | null
          observations?: string | null
          project_id?: string
          report_date?: string
          work_completed?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_field_reports_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_invoices: {
        Row: {
          amount: number
          amount_paid: number
          cancelled_from_status: string | null
          created_at: string
          currency: string
          due_at: string | null
          id: string
          invoice_number: string
          project_id: string
          proposal_id: string | null
          replaces_invoice_id: string | null
          service_description: string | null
          service_name: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          amount: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          project_id: string
          proposal_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          amount?: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          project_id?: string
          proposal_id?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_invoices_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_invoices_proposal_id_fkey"
            columns: ["proposal_id"]
            isOneToOne: false
            referencedRelation: "engineering_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_invoices_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "engineering_invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_maintenance: {
        Row: {
          created_at: string
          frequency: string | null
          id: string
          notes: string | null
          project_id: string
          scheduled_date: string
          status: string
          title: string
        }
        Insert: {
          created_at?: string
          frequency?: string | null
          id?: string
          notes?: string | null
          project_id: string
          scheduled_date: string
          status?: string
          title: string
        }
        Update: {
          created_at?: string
          frequency?: string | null
          id?: string
          notes?: string | null
          project_id?: string
          scheduled_date?: string
          status?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_maintenance_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_messages: {
        Row: {
          body: string
          created_at: string
          id: string
          project_id: string
          sender_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          project_id: string
          sender_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          project_id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_messages_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_milestones: {
        Row: {
          created_at: string
          description: string | null
          due_at: string | null
          id: string
          progress: number
          project_id: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          due_at?: string | null
          id?: string
          progress?: number
          project_id: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          due_at?: string | null
          id?: string
          progress?: number
          project_id?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_milestones_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          kind: string
          project_id: string | null
          read_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          kind?: string
          project_id?: string | null
          read_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          kind?: string
          project_id?: string | null
          read_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_notifications_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_payment_intents: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          paid_at: string | null
          project_id: string
          reference: string
          status: string
          transaction_ref: string | null
          updated_at: string
          user_id: string
          virtual_account_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          paid_at?: string | null
          project_id: string
          reference: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id: string
          virtual_account_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          paid_at?: string | null
          project_id?: string
          reference?: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id?: string
          virtual_account_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "engineering_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_payment_intents_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          invoice_id: string
          paid_at: string
          payment_intent_id: string | null
          provider: string
          provider_reference: string
          status: string
          transaction_ref: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id: string
          paid_at: string
          payment_intent_id?: string | null
          provider?: string
          provider_reference: string
          status?: string
          transaction_ref: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id?: string
          paid_at?: string
          payment_intent_id?: string | null
          provider?: string
          provider_reference?: string
          status?: string
          transaction_ref?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "engineering_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_payments_payment_intent_id_fkey"
            columns: ["payment_intent_id"]
            isOneToOne: true
            referencedRelation: "engineering_payment_intents"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_projects: {
        Row: {
          created_at: string
          discipline: string
          due_at: string | null
          id: string
          lead_engineer: string | null
          name: string
          progress: number
          project_number: string
          request_id: string | null
          stage: string
          started_at: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          discipline: string
          due_at?: string | null
          id?: string
          lead_engineer?: string | null
          name: string
          progress?: number
          project_number?: string
          request_id?: string | null
          stage?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          discipline?: string
          due_at?: string | null
          id?: string
          lead_engineer?: string | null
          name?: string
          progress?: number
          project_number?: string
          request_id?: string | null
          stage?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_projects_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "engineering_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_proposals: {
        Row: {
          amount: number | null
          created_at: string
          currency: string
          id: string
          project_id: string
          proposal_number: string
          scope: string
          status: string
          title: string
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          amount?: number | null
          created_at?: string
          currency?: string
          id?: string
          project_id: string
          proposal_number?: string
          scope?: string
          status?: string
          title: string
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          amount?: number | null
          created_at?: string
          currency?: string
          id?: string
          project_id?: string
          proposal_number?: string
          scope?: string
          status?: string
          title?: string
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engineering_proposals_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_requests: {
        Row: {
          budget_range: string | null
          created_at: string
          discipline: string
          id: string
          location: string | null
          organisation: string | null
          preferred_assessment_date: string | null
          problem_statement: string
          project_title: string
          request_number: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          budget_range?: string | null
          created_at?: string
          discipline: string
          id?: string
          location?: string | null
          organisation?: string | null
          preferred_assessment_date?: string | null
          problem_statement: string
          project_title: string
          request_number?: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          budget_range?: string | null
          created_at?: string
          discipline?: string
          id?: string
          location?: string | null
          organisation?: string | null
          preferred_assessment_date?: string | null
          problem_statement?: string
          project_title?: string
          request_number?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      engineering_risks: {
        Row: {
          created_at: string
          description: string | null
          id: string
          impact: string | null
          likelihood: string | null
          mitigation: string | null
          owner: string | null
          project_id: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          impact?: string | null
          likelihood?: string | null
          mitigation?: string | null
          owner?: string | null
          project_id: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          impact?: string | null
          likelihood?: string | null
          mitigation?: string | null
          owner?: string | null
          project_id?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_risks_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_site_assessments: {
        Row: {
          contact_person: string | null
          created_at: string
          findings: string | null
          id: string
          project_id: string
          recommendations: string | null
          scheduled_at: string | null
          site_address: string | null
          status: string
        }
        Insert: {
          contact_person?: string | null
          created_at?: string
          findings?: string | null
          id?: string
          project_id: string
          recommendations?: string | null
          scheduled_at?: string | null
          site_address?: string | null
          status?: string
        }
        Update: {
          contact_person?: string | null
          created_at?: string
          findings?: string | null
          id?: string
          project_id?: string
          recommendations?: string | null
          scheduled_at?: string | null
          site_address?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_site_assessments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_support_tickets: {
        Row: {
          category: string
          created_at: string
          id: string
          message: string
          project_id: string | null
          status: string
          subject: string
          updated_at: string
          user_id: string
        }
        Insert: {
          category: string
          created_at?: string
          id?: string
          message: string
          project_id?: string | null
          status?: string
          subject: string
          updated_at?: string
          user_id: string
        }
        Update: {
          category?: string
          created_at?: string
          id?: string
          message?: string
          project_id?: string | null
          status?: string
          subject?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_support_tickets_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_team_members: {
        Row: {
          created_at: string
          discipline: string | null
          display_name: string
          id: string
          is_active: boolean
          member_user_id: string | null
          project_id: string
          role_title: string
        }
        Insert: {
          created_at?: string
          discipline?: string | null
          display_name: string
          id?: string
          is_active?: boolean
          member_user_id?: string | null
          project_id: string
          role_title: string
        }
        Update: {
          created_at?: string
          discipline?: string | null
          display_name?: string
          id?: string
          is_active?: boolean
          member_user_id?: string | null
          project_id?: string
          role_title?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_team_members_member_user_id_fkey"
            columns: ["member_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engineering_team_members_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      engineering_tests: {
        Row: {
          acceptance_criteria: string | null
          created_at: string
          id: string
          performed_at: string | null
          procedure: string | null
          project_id: string
          result: string | null
          status: string
          test_type: string
          title: string
          updated_at: string
        }
        Insert: {
          acceptance_criteria?: string | null
          created_at?: string
          id?: string
          performed_at?: string | null
          procedure?: string | null
          project_id: string
          result?: string | null
          status?: string
          test_type: string
          title: string
          updated_at?: string
        }
        Update: {
          acceptance_criteria?: string | null
          created_at?: string
          id?: string
          performed_at?: string | null
          procedure?: string | null
          project_id?: string
          result?: string | null
          status?: string
          test_type?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engineering_tests_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "engineering_projects"
            referencedColumns: ["id"]
          },
        ]
      }
      equipment: {
        Row: {
          asset_id: string
          assigned_custodian: string | null
          business_unit_id: string | null
          category: string | null
          created_at: string
          equipment_name: string
          id: string
          last_maintenance: string | null
          location: string | null
          maintenance_schedule: string | null
          manufacturer: string | null
          model: string | null
          next_maintenance: string | null
          notes: string | null
          operating_status: string
          power_requirement: string | null
          purchase_date: string | null
          purchase_price: number | null
          serial_number: string | null
          supplier_id: string | null
          updated_at: string
          warranty_until: string | null
        }
        Insert: {
          asset_id: string
          assigned_custodian?: string | null
          business_unit_id?: string | null
          category?: string | null
          created_at?: string
          equipment_name: string
          id?: string
          last_maintenance?: string | null
          location?: string | null
          maintenance_schedule?: string | null
          manufacturer?: string | null
          model?: string | null
          next_maintenance?: string | null
          notes?: string | null
          operating_status?: string
          power_requirement?: string | null
          purchase_date?: string | null
          purchase_price?: number | null
          serial_number?: string | null
          supplier_id?: string | null
          updated_at?: string
          warranty_until?: string | null
        }
        Update: {
          asset_id?: string
          assigned_custodian?: string | null
          business_unit_id?: string | null
          category?: string | null
          created_at?: string
          equipment_name?: string
          id?: string
          last_maintenance?: string | null
          location?: string | null
          maintenance_schedule?: string | null
          manufacturer?: string | null
          model?: string | null
          next_maintenance?: string | null
          notes?: string | null
          operating_status?: string
          power_requirement?: string | null
          purchase_date?: string | null
          purchase_price?: number | null
          serial_number?: string | null
          supplier_id?: string | null
          updated_at?: string
          warranty_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "equipment_assigned_custodian_fkey"
            columns: ["assigned_custodian"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "equipment_business_unit_id_fkey"
            columns: ["business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "equipment_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      fabrication_jobs: {
        Row: {
          created_at: string
          design_file_url: string | null
          dimensions: string | null
          id: string
          machine_notes: string | null
          material: string | null
          order_id: string
          process: string
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          design_file_url?: string | null
          dimensions?: string | null
          id?: string
          machine_notes?: string | null
          material?: string | null
          order_id: string
          process: string
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          design_file_url?: string | null
          dimensions?: string | null
          id?: string
          machine_notes?: string | null
          material?: string | null
          order_id?: string
          process?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fabrication_jobs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "business_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      finance_ledger_entries: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          currency: string
          description: string
          direction: string
          entry_type: string
          id: string
          occurred_at: string
          product: string
          reference: string
          source_id: string | null
          source_table: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by: string
          currency?: string
          description: string
          direction: string
          entry_type: string
          id?: string
          occurred_at?: string
          product: string
          reference?: string
          source_id?: string | null
          source_table?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by?: string
          currency?: string
          description?: string
          direction?: string
          entry_type?: string
          id?: string
          occurred_at?: string
          product?: string
          reference?: string
          source_id?: string | null
          source_table?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      finance_refund_requests: {
        Row: {
          amount: number
          created_at: string
          currency: string
          customer_user_id: string | null
          id: string
          payment_transaction_id: string | null
          processed_at: string | null
          product: string
          provider_refund_reference: string | null
          reason: string
          refund_number: string
          requested_by: string
          reviewed_at: string | null
          reviewed_by: string | null
          source_reference: string
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          customer_user_id?: string | null
          id?: string
          payment_transaction_id?: string | null
          processed_at?: string | null
          product: string
          provider_refund_reference?: string | null
          reason: string
          refund_number?: string
          requested_by: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          source_reference: string
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          customer_user_id?: string | null
          id?: string
          payment_transaction_id?: string | null
          processed_at?: string | null
          product?: string
          provider_refund_reference?: string | null
          reason?: string
          refund_number?: string
          requested_by?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          source_reference?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "finance_refund_requests_payment_transaction_id_fkey"
            columns: ["payment_transaction_id"]
            isOneToOne: false
            referencedRelation: "customer_payment_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "finance_refund_requests_payment_transaction_id_fkey"
            columns: ["payment_transaction_id"]
            isOneToOne: false
            referencedRelation: "payment_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      host_backups: {
        Row: {
          backup_type: string
          completed_at: string | null
          created_at: string
          expires_at: string | null
          id: string
          service_id: string
          started_at: string | null
          status: string
          storage_reference: string | null
        }
        Insert: {
          backup_type?: string
          completed_at?: string | null
          created_at?: string
          expires_at?: string | null
          id?: string
          service_id: string
          started_at?: string | null
          status?: string
          storage_reference?: string | null
        }
        Update: {
          backup_type?: string
          completed_at?: string | null
          created_at?: string
          expires_at?: string | null
          id?: string
          service_id?: string
          started_at?: string | null
          status?: string
          storage_reference?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "host_backups_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
        ]
      }
      host_dns_records: {
        Row: {
          created_at: string
          id: string
          name: string
          priority: number | null
          record_type: string
          status: string
          ttl: number
          updated_at: string
          value: string
          zone_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          priority?: number | null
          record_type: string
          status?: string
          ttl?: number
          updated_at?: string
          value: string
          zone_id: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          priority?: number | null
          record_type?: string
          status?: string
          ttl?: number
          updated_at?: string
          value?: string
          zone_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_dns_records_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "host_dns_zones"
            referencedColumns: ["id"]
          },
        ]
      }
      host_dns_zones: {
        Row: {
          created_at: string
          domain_name: string
          id: string
          service_id: string
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          domain_name: string
          id?: string
          service_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          domain_name?: string
          id?: string
          service_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_dns_zones_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
        ]
      }
      host_domain_prices: {
        Row: {
          eligibility_summary: string | null
          extension: string
          id: string
          is_active: boolean
          is_restricted: boolean
          lookup_provider: string
          lookup_url: string | null
          registration_price: number
          renewal_price: number
          requirements: Json
          transfer_price: number
          updated_at: string
        }
        Insert: {
          eligibility_summary?: string | null
          extension: string
          id?: string
          is_active?: boolean
          is_restricted?: boolean
          lookup_provider?: string
          lookup_url?: string | null
          registration_price: number
          renewal_price: number
          requirements?: Json
          transfer_price: number
          updated_at?: string
        }
        Update: {
          eligibility_summary?: string | null
          extension?: string
          id?: string
          is_active?: boolean
          is_restricted?: boolean
          lookup_provider?: string
          lookup_url?: string | null
          registration_price?: number
          renewal_price?: number
          requirements?: Json
          transfer_price?: number
          updated_at?: string
        }
        Relationships: []
      }
      host_invoices: {
        Row: {
          amount: number
          cancelled_from_status: string | null
          created_at: string
          currency: string
          due_at: string | null
          id: string
          invoice_number: string
          order_id: string | null
          paid_at: string | null
          payment_id: string | null
          payment_reference: string | null
          replaces_invoice_id: string | null
          service_description: string | null
          service_name: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id?: string | null
          paid_at?: string | null
          payment_id?: string | null
          payment_reference?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id?: string | null
          paid_at?: string | null
          payment_id?: string | null
          payment_reference?: string | null
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_invoices_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "host_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_invoices_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "host_payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_invoices_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "host_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_invoices_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_mailboxes: {
        Row: {
          created_at: string
          email_address: string
          id: string
          quota_mb: number | null
          service_id: string
          status: string
        }
        Insert: {
          created_at?: string
          email_address: string
          id?: string
          quota_mb?: number | null
          service_id: string
          status?: string
        }
        Update: {
          created_at?: string
          email_address?: string
          id?: string
          quota_mb?: number | null
          service_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_mailboxes_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
        ]
      }
      host_migrations: {
        Row: {
          created_at: string
          id: string
          notes: string | null
          preferred_date: string | null
          scope: string | null
          service_id: string | null
          source_domain: string
          source_host: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          notes?: string | null
          preferred_date?: string | null
          scope?: string | null
          service_id?: string | null
          source_domain: string
          source_host?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          notes?: string | null
          preferred_date?: string | null
          scope?: string | null
          service_id?: string | null
          source_domain?: string
          source_host?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_migrations_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_migrations_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          kind: string
          read_at: string | null
          service_id: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          kind?: string
          read_at?: string | null
          service_id?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          kind?: string
          read_at?: string | null
          service_id?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_notifications_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_orders: {
        Row: {
          admin_notes: string | null
          amount: number
          billing_cycle_months: number
          created_at: string
          currency: string
          customer_notes: string | null
          domain_name: string | null
          id: string
          order_number: string
          order_type: string
          paid_at: string | null
          payment_status: string
          plan_id: string | null
          provider_reference: string | null
          provisioning_status: string
          renewal_service_id: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          admin_notes?: string | null
          amount: number
          billing_cycle_months?: number
          created_at?: string
          currency?: string
          customer_notes?: string | null
          domain_name?: string | null
          id?: string
          order_number?: string
          order_type: string
          paid_at?: string | null
          payment_status?: string
          plan_id?: string | null
          provider_reference?: string | null
          provisioning_status?: string
          renewal_service_id?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          admin_notes?: string | null
          amount?: number
          billing_cycle_months?: number
          created_at?: string
          currency?: string
          customer_notes?: string | null
          domain_name?: string | null
          id?: string
          order_number?: string
          order_type?: string
          paid_at?: string | null
          payment_status?: string
          plan_id?: string | null
          provider_reference?: string | null
          provisioning_status?: string
          renewal_service_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_orders_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "host_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_orders_renewal_service_id_fkey"
            columns: ["renewal_service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_orders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_payment_intents: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          order_id: string
          paid_at: string | null
          reference: string
          status: string
          transaction_ref: string | null
          updated_at: string
          user_id: string
          virtual_account_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          order_id: string
          paid_at?: string | null
          reference: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id: string
          virtual_account_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          order_id?: string
          paid_at?: string | null
          reference?: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id?: string
          virtual_account_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "host_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_payment_intents_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "host_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      host_payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          invoice_id: string | null
          paid_at: string | null
          provider_payload: Json
          provider_reference: string | null
          status: string
          transaction_ref: string | null
          user_id: string
          verified_at: string | null
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id?: string | null
          paid_at?: string | null
          provider_payload?: Json
          provider_reference?: string | null
          status?: string
          transaction_ref?: string | null
          user_id: string
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id?: string | null
          paid_at?: string | null
          provider_payload?: Json
          provider_reference?: string | null
          status?: string
          transaction_ref?: string | null
          user_id?: string
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "host_payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "host_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_payments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_payments_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      host_plans: {
        Row: {
          category: string
          code: string
          description: string | null
          features: Json
          id: string
          is_active: boolean
          monthly_price: number
          name: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          category: string
          code: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          monthly_price: number
          name: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          category?: string
          code?: string
          description?: string | null
          features?: Json
          id?: string
          is_active?: boolean
          monthly_price?: number
          name?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      host_provider_adapters: {
        Row: {
          code: string
          credential_secret_name: string | null
          id: string
          name: string
          notes: string | null
          service_scope: string
          status: string
          updated_at: string
        }
        Insert: {
          code: string
          credential_secret_name?: string | null
          id?: string
          name: string
          notes?: string | null
          service_scope: string
          status?: string
          updated_at?: string
        }
        Update: {
          code?: string
          credential_secret_name?: string | null
          id?: string
          name?: string
          notes?: string | null
          service_scope?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      host_provisioning_jobs: {
        Row: {
          action: string
          attempts: number
          completed_at: string | null
          id: string
          last_error: string | null
          order_id: string
          provider_code: string | null
          provider_reference: string | null
          requested_at: string
          started_at: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          action: string
          attempts?: number
          completed_at?: string | null
          id?: string
          last_error?: string | null
          order_id: string
          provider_code?: string | null
          provider_reference?: string | null
          requested_at?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          action?: string
          attempts?: number
          completed_at?: string | null
          id?: string
          last_error?: string | null
          order_id?: string
          provider_code?: string | null
          provider_reference?: string | null
          requested_at?: string
          started_at?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_provisioning_jobs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "host_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_provisioning_jobs_provider_code_fkey"
            columns: ["provider_code"]
            isOneToOne: false
            referencedRelation: "host_provider_adapters"
            referencedColumns: ["code"]
          },
        ]
      }
      host_services: {
        Row: {
          activated_at: string | null
          control_panel_url: string | null
          created_at: string
          domain_name: string | null
          id: string
          nameservers: Json
          order_id: string
          provider_reference: string | null
          renews_at: string | null
          service_name: string
          service_type: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          activated_at?: string | null
          control_panel_url?: string | null
          created_at?: string
          domain_name?: string | null
          id?: string
          nameservers?: Json
          order_id: string
          provider_reference?: string | null
          renews_at?: string | null
          service_name: string
          service_type: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          activated_at?: string | null
          control_panel_url?: string | null
          created_at?: string
          domain_name?: string | null
          id?: string
          nameservers?: Json
          order_id?: string
          provider_reference?: string | null
          renews_at?: string | null
          service_name?: string
          service_type?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_services_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "host_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "host_services_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_ssl_certificates: {
        Row: {
          auto_renew: boolean
          created_at: string
          domain_name: string
          expires_at: string | null
          id: string
          issued_at: string | null
          issuer: string | null
          service_id: string
          status: string
        }
        Insert: {
          auto_renew?: boolean
          created_at?: string
          domain_name: string
          expires_at?: string | null
          id?: string
          issued_at?: string | null
          issuer?: string | null
          service_id: string
          status?: string
        }
        Update: {
          auto_renew?: boolean
          created_at?: string
          domain_name?: string
          expires_at?: string | null
          id?: string
          issued_at?: string | null
          issuer?: string | null
          service_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_ssl_certificates_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
        ]
      }
      host_support_tickets: {
        Row: {
          admin_response: string | null
          category: string
          created_at: string
          id: string
          message: string
          priority: string
          status: string
          subject: string
          updated_at: string
          user_id: string
        }
        Insert: {
          admin_response?: string | null
          category: string
          created_at?: string
          id?: string
          message: string
          priority?: string
          status?: string
          subject: string
          updated_at?: string
          user_id: string
        }
        Update: {
          admin_response?: string | null
          category?: string
          created_at?: string
          id?: string
          message?: string
          priority?: string
          status?: string
          subject?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_support_tickets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      host_usage_snapshots: {
        Row: {
          bandwidth_mb: number | null
          databases_count: number | null
          disk_mb: number | null
          id: string
          mailboxes_count: number | null
          recorded_at: string
          service_id: string
        }
        Insert: {
          bandwidth_mb?: number | null
          databases_count?: number | null
          disk_mb?: number | null
          id?: string
          mailboxes_count?: number | null
          recorded_at?: string
          service_id: string
        }
        Update: {
          bandwidth_mb?: number | null
          databases_count?: number | null
          disk_mb?: number | null
          id?: string
          mailboxes_count?: number | null
          recorded_at?: string
          service_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "host_usage_snapshots_service_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "host_services"
            referencedColumns: ["id"]
          },
        ]
      }
      ihlink_bank_accounts: {
        Row: {
          account_name: string
          account_number: string
          bank_name: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          is_default: boolean
          label: string
          updated_at: string
        }
        Insert: {
          account_name: string
          account_number: string
          bank_name: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          label?: string
          updated_at?: string
        }
        Update: {
          account_name?: string
          account_number?: string
          bank_name?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          label?: string
          updated_at?: string
        }
        Relationships: []
      }
      ihlink_document_templates: {
        Row: {
          content: string | null
          created_at: string
          created_by: string | null
          description: string | null
          field_mappings: Json
          id: string
          is_active: boolean
          is_default: boolean
          layout: Json
          mime_type: string | null
          name: string
          original_filename: string | null
          platform_code: string
          preview_mode: string
          source_format: string
          storage_path: string | null
          template_type: string
          updated_at: string
          version: number
        }
        Insert: {
          content?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          layout?: Json
          mime_type?: string | null
          name: string
          original_filename?: string | null
          platform_code: string
          preview_mode?: string
          source_format?: string
          storage_path?: string | null
          template_type: string
          updated_at?: string
          version?: number
        }
        Update: {
          content?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          layout?: Json
          mime_type?: string | null
          name?: string
          original_filename?: string | null
          platform_code?: string
          preview_mode?: string
          source_format?: string
          storage_path?: string | null
          template_type?: string
          updated_at?: string
          version?: number
        }
        Relationships: []
      }
      ihlink_email_queue: {
        Row: {
          accepted_at: string | null
          action_url: string | null
          attempts: number
          created_at: string
          id: string
          last_error: string | null
          locked_at: string | null
          message: string
          next_attempt_at: string
          product: string
          provider_message_id: string | null
          recipient_email: string
          recipient_name: string | null
          school_id: string | null
          source: string
          source_id: string
          status: string
          subject: string
          user_id: string
        }
        Insert: {
          accepted_at?: string | null
          action_url?: string | null
          attempts?: number
          created_at?: string
          id?: string
          last_error?: string | null
          locked_at?: string | null
          message: string
          next_attempt_at?: string
          product: string
          provider_message_id?: string | null
          recipient_email: string
          recipient_name?: string | null
          school_id?: string | null
          source: string
          source_id: string
          status?: string
          subject: string
          user_id: string
        }
        Update: {
          accepted_at?: string | null
          action_url?: string | null
          attempts?: number
          created_at?: string
          id?: string
          last_error?: string | null
          locked_at?: string | null
          message?: string
          next_attempt_at?: string
          product?: string
          provider_message_id?: string | null
          recipient_email?: string
          recipient_name?: string | null
          school_id?: string | null
          source?: string
          source_id?: string
          status?: string
          subject?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ihlink_email_queue_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      ihlink_email_templates: {
        Row: {
          created_at: string
          created_by: string | null
          html_body: string
          id: string
          is_active: boolean
          name: string
          platform_code: string
          subject: string
          template_key: string
          text_body: string
          updated_at: string
          variables: Json
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          html_body?: string
          id?: string
          is_active?: boolean
          name: string
          platform_code: string
          subject: string
          template_key: string
          text_body?: string
          updated_at?: string
          variables?: Json
        }
        Update: {
          created_at?: string
          created_by?: string | null
          html_body?: string
          id?: string
          is_active?: boolean
          name?: string
          platform_code?: string
          subject?: string
          template_key?: string
          text_body?: string
          updated_at?: string
          variables?: Json
        }
        Relationships: []
      }
      ihlink_generated_documents: {
        Row: {
          document_number: string
          document_type: string
          generated_at: string
          id: string
          issued_at: string | null
          merge_values: Json
          output_storage_path: string | null
          owner_user_id: string | null
          platform_code: string
          rendered_content: string | null
          source_id: string | null
          source_reference: string | null
          source_table: string | null
          status: string
          template_id: string | null
        }
        Insert: {
          document_number: string
          document_type: string
          generated_at?: string
          id?: string
          issued_at?: string | null
          merge_values?: Json
          output_storage_path?: string | null
          owner_user_id?: string | null
          platform_code: string
          rendered_content?: string | null
          source_id?: string | null
          source_reference?: string | null
          source_table?: string | null
          status?: string
          template_id?: string | null
        }
        Update: {
          document_number?: string
          document_type?: string
          generated_at?: string
          id?: string
          issued_at?: string | null
          merge_values?: Json
          output_storage_path?: string | null
          owner_user_id?: string | null
          platform_code?: string
          rendered_content?: string | null
          source_id?: string | null
          source_reference?: string | null
          source_table?: string | null
          status?: string
          template_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ihlink_generated_documents_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "ihlink_document_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_items: {
        Row: {
          business_unit_id: string | null
          category: string | null
          cost_price: number | null
          created_at: string
          id: string
          is_active: boolean
          name: string
          quantity_on_hand: number
          reorder_level: number
          selling_price: number | null
          sku: string
          supplier_id: string | null
          unit: string
          updated_at: string
        }
        Insert: {
          business_unit_id?: string | null
          category?: string | null
          cost_price?: number | null
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          quantity_on_hand?: number
          reorder_level?: number
          selling_price?: number | null
          sku: string
          supplier_id?: string | null
          unit?: string
          updated_at?: string
        }
        Update: {
          business_unit_id?: string | null
          category?: string | null
          cost_price?: number | null
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          quantity_on_hand?: number
          reorder_level?: number
          selling_price?: number | null
          sku?: string
          supplier_id?: string | null
          unit?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "inventory_items_business_unit_id_fkey"
            columns: ["business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_items_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_transactions: {
        Row: {
          created_at: string
          id: string
          inventory_item_id: string
          notes: string | null
          performed_by: string | null
          quantity: number
          reference: string | null
          transaction_type: string
          unit_cost: number | null
        }
        Insert: {
          created_at?: string
          id?: string
          inventory_item_id: string
          notes?: string | null
          performed_by?: string | null
          quantity: number
          reference?: string | null
          transaction_type: string
          unit_cost?: number | null
        }
        Update: {
          created_at?: string
          id?: string
          inventory_item_id?: string
          notes?: string | null
          performed_by?: string | null
          quantity?: number
          reference?: string | null
          transaction_type?: string
          unit_cost?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "inventory_transactions_inventory_item_id_fkey"
            columns: ["inventory_item_id"]
            isOneToOne: false
            referencedRelation: "inventory_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      launch_readiness_checks: {
        Row: {
          category: string
          created_at: string
          dashboard_url: string | null
          description: string
          evidence: string | null
          id: string
          sort_order: number
          status: string
          title: string
          updated_at: string
          updated_by: string | null
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          category: string
          created_at?: string
          dashboard_url?: string | null
          description: string
          evidence?: string | null
          id: string
          sort_order?: number
          status?: string
          title: string
          updated_at?: string
          updated_by?: string | null
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          category?: string
          created_at?: string
          dashboard_url?: string | null
          description?: string
          evidence?: string | null
          id?: string
          sort_order?: number
          status?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "launch_readiness_checks_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "launch_readiness_checks_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_campaigns: {
        Row: {
          action_label: string | null
          action_url: string | null
          audience_type: string
          audience_user_id: string | null
          campaign_number: string
          channels: string[]
          created_at: string
          created_by: string
          id: string
          message: string
          product: string
          scheduled_for: string | null
          sent_at: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          action_label?: string | null
          action_url?: string | null
          audience_type?: string
          audience_user_id?: string | null
          campaign_number?: string
          channels?: string[]
          created_at?: string
          created_by: string
          id?: string
          message: string
          product?: string
          scheduled_for?: string | null
          sent_at?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          action_label?: string | null
          action_url?: string | null
          audience_type?: string
          audience_user_id?: string | null
          campaign_number?: string
          channels?: string[]
          created_at?: string
          created_by?: string
          id?: string
          message?: string
          product?: string
          scheduled_for?: string | null
          sent_at?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      notification_deliveries: {
        Row: {
          campaign_id: string
          channel: string
          created_at: string
          delivered_at: string | null
          failure_reason: string | null
          id: string
          read_at: string | null
          status: string
          user_id: string
        }
        Insert: {
          campaign_id: string
          channel: string
          created_at?: string
          delivered_at?: string | null
          failure_reason?: string | null
          id?: string
          read_at?: string | null
          status?: string
          user_id: string
        }
        Update: {
          campaign_id?: string
          channel?: string
          created_at?: string
          delivered_at?: string | null
          failure_reason?: string | null
          id?: string
          read_at?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_deliveries_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "notification_campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_templates: {
        Row: {
          created_at: string
          created_by: string | null
          default_channels: string[]
          id: string
          is_active: boolean
          message: string
          name: string
          product: string
          subject: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          default_channels?: string[]
          id?: string
          is_active?: boolean
          message: string
          name: string
          product?: string
          subject: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          default_channels?: string[]
          id?: string
          is_active?: boolean
          message?: string
          name?: string
          product?: string
          subject?: string
          updated_at?: string
        }
        Relationships: []
      }
      password_login_security: {
        Row: {
          failed_attempts: number
          last_failed_at: string | null
          locked_until: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          failed_attempts?: number
          last_failed_at?: string | null
          locked_until?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          failed_attempts?: number
          last_failed_at?: string | null
          locked_until?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      payment_admin_audit: {
        Row: {
          actor_id: string | null
          created_at: string
          details: Json
          id: string
          operation: string
          reason: string | null
          target_id: string | null
          target_type: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          details?: Json
          id?: string
          operation: string
          reason?: string | null
          target_id?: string | null
          target_type: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          details?: Json
          id?: string
          operation?: string
          reason?: string | null
          target_id?: string | null
          target_type?: string
        }
        Relationships: []
      }
      payment_fee_settings: {
        Row: {
          created_at: string
          customer_pays: boolean
          enabled: boolean
          fee_code: string
          fee_type: string
          fee_value: number
          id: string
          maximum_fee: number | null
          minimum_fee: number | null
          platform_code: string
          provider: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          customer_pays?: boolean
          enabled?: boolean
          fee_code: string
          fee_type?: string
          fee_value?: number
          id?: string
          maximum_fee?: number | null
          minimum_fee?: number | null
          platform_code: string
          provider: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          customer_pays?: boolean
          enabled?: boolean
          fee_code?: string
          fee_type?: string
          fee_value?: number
          id?: string
          maximum_fee?: number | null
          minimum_fee?: number | null
          platform_code?: string
          provider?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      payment_platform_settings: {
        Row: {
          direct_bank_transfer_enabled: boolean
          direct_checkout_enabled: boolean
          platform_code: string
          provider: string
          updated_at: string
          updated_by: string | null
          virtual_account_enabled: boolean
          wallet_funding_enabled: boolean
        }
        Insert: {
          direct_bank_transfer_enabled?: boolean
          direct_checkout_enabled?: boolean
          platform_code: string
          provider?: string
          updated_at?: string
          updated_by?: string | null
          virtual_account_enabled?: boolean
          wallet_funding_enabled?: boolean
        }
        Update: {
          direct_bank_transfer_enabled?: boolean
          direct_checkout_enabled?: boolean
          platform_code?: string
          provider?: string
          updated_at?: string
          updated_by?: string | null
          virtual_account_enabled?: boolean
          wallet_funding_enabled?: boolean
        }
        Relationships: []
      }
      payment_provider_banks: {
        Row: {
          bank_code: string
          bank_name: string
          created_at: string
          customer_enabled: boolean
          enabled: boolean
          id: string
          provider_id: string
          requires_identity: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          bank_code: string
          bank_name: string
          created_at?: string
          customer_enabled?: boolean
          enabled?: boolean
          id?: string
          provider_id: string
          requires_identity?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          bank_code?: string
          bank_name?: string
          created_at?: string
          customer_enabled?: boolean
          enabled?: boolean
          id?: string
          provider_id?: string
          requires_identity?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_provider_banks_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "payment_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_providers: {
        Row: {
          code: string
          created_at: string
          enabled: boolean
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          enabled?: boolean
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          enabled?: boolean
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      payment_transactions: {
        Row: {
          account_name: string | null
          amount: number
          bank: string | null
          created_at: string
          credited_at: string | null
          currency: string
          customer_fee: number
          fee_setting_id: string | null
          fee_snapshot: Json
          gross_amount: number | null
          id: string
          is_settled: boolean | null
          margin_amount: number | null
          method: string | null
          net_amount: number | null
          nuban: string | null
          platform_code: string
          provider: string
          provider_fee: number | null
          provider_payload: Json
          provider_reference: string | null
          schoolpro_payment_intent_id: string | null
          session_id: string | null
          status: string
          transaction_ref: string
          updated_at: string
          user_id: string | null
          verified_at: string | null
          virtual_account_id: string | null
        }
        Insert: {
          account_name?: string | null
          amount: number
          bank?: string | null
          created_at?: string
          credited_at?: string | null
          currency?: string
          customer_fee?: number
          fee_setting_id?: string | null
          fee_snapshot?: Json
          gross_amount?: number | null
          id?: string
          is_settled?: boolean | null
          margin_amount?: number | null
          method?: string | null
          net_amount?: number | null
          nuban?: string | null
          platform_code?: string
          provider: string
          provider_fee?: number | null
          provider_payload?: Json
          provider_reference?: string | null
          schoolpro_payment_intent_id?: string | null
          session_id?: string | null
          status?: string
          transaction_ref: string
          updated_at?: string
          user_id?: string | null
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Update: {
          account_name?: string | null
          amount?: number
          bank?: string | null
          created_at?: string
          credited_at?: string | null
          currency?: string
          customer_fee?: number
          fee_setting_id?: string | null
          fee_snapshot?: Json
          gross_amount?: number | null
          id?: string
          is_settled?: boolean | null
          margin_amount?: number | null
          method?: string | null
          net_amount?: number | null
          nuban?: string | null
          platform_code?: string
          provider?: string
          provider_fee?: number | null
          provider_payload?: Json
          provider_reference?: string | null
          schoolpro_payment_intent_id?: string | null
          session_id?: string | null
          status?: string
          transaction_ref?: string
          updated_at?: string
          user_id?: string | null
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_transactions_fee_setting_id_fkey"
            columns: ["fee_setting_id"]
            isOneToOne: false
            referencedRelation: "payment_fee_settings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_transactions_schoolpro_payment_intent_id_fkey"
            columns: ["schoolpro_payment_intent_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_payment_intents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_transactions_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_commercial_pricing: {
        Row: {
          created_at: string
          currency: string
          id: string
          is_active: boolean
          platform_code: string
          pricing_unit: string
          service_code: string
          service_name: string
          starting_price: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          currency?: string
          id?: string
          is_active?: boolean
          platform_code: string
          pricing_unit?: string
          service_code: string
          service_name: string
          starting_price: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          currency?: string
          id?: string
          is_active?: boolean
          platform_code?: string
          pricing_unit?: string
          service_code?: string
          service_name?: string
          starting_price?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      platform_feature_content: {
        Row: {
          audience: string
          badge_text: string | null
          created_at: string
          created_by: string | null
          cta_label: string | null
          cta_link: string | null
          description: string | null
          feature_key: string
          help_text: string | null
          icon_key: string | null
          id: string
          is_enabled: boolean
          is_visible: boolean
          module_key: string
          platform_key: string
          settings: Json
          sort_order: number
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          audience?: string
          badge_text?: string | null
          created_at?: string
          created_by?: string | null
          cta_label?: string | null
          cta_link?: string | null
          description?: string | null
          feature_key: string
          help_text?: string | null
          icon_key?: string | null
          id?: string
          is_enabled?: boolean
          is_visible?: boolean
          module_key: string
          platform_key: string
          settings?: Json
          sort_order?: number
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          audience?: string
          badge_text?: string | null
          created_at?: string
          created_by?: string | null
          cta_label?: string | null
          cta_link?: string | null
          description?: string | null
          feature_key?: string
          help_text?: string | null
          icon_key?: string | null
          id?: string
          is_enabled?: boolean
          is_visible?: boolean
          module_key?: string
          platform_key?: string
          settings?: Json
          sort_order?: number
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      platform_integrations: {
        Row: {
          base_url: string | null
          config: Json
          created_at: string
          id: string
          integration_type: string
          is_enabled: boolean
          last_verified_at: string | null
          mode: string
          product: string
          provider_key: string
          provider_name: string
          secret_ref: string | null
          updated_at: string
        }
        Insert: {
          base_url?: string | null
          config?: Json
          created_at?: string
          id?: string
          integration_type: string
          is_enabled?: boolean
          last_verified_at?: string | null
          mode?: string
          product: string
          provider_key: string
          provider_name: string
          secret_ref?: string | null
          updated_at?: string
        }
        Update: {
          base_url?: string | null
          config?: Json
          created_at?: string
          id?: string
          integration_type?: string
          is_enabled?: boolean
          last_verified_at?: string | null
          mode?: string
          product?: string
          provider_key?: string
          provider_name?: string
          secret_ref?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      print_artworks: {
        Row: {
          created_at: string
          file_path: string
          id: string
          order_id: string
          status: string
          title: string
          user_id: string
          version: number
        }
        Insert: {
          created_at?: string
          file_path: string
          id?: string
          order_id: string
          status?: string
          title: string
          user_id: string
          version?: number
        }
        Update: {
          created_at?: string
          file_path?: string
          id?: string
          order_id?: string
          status?: string
          title?: string
          user_id?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "print_artworks_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string
          id: number
          metadata: Json
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type: string
          id?: never
          metadata?: Json
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string
          id?: never
          metadata?: Json
        }
        Relationships: []
      }
      print_deliveries: {
        Row: {
          address: string | null
          created_at: string
          delivered_at: string | null
          id: string
          method: string
          order_id: string
          recipient_name: string | null
          status: string
          tracking_reference: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          created_at?: string
          delivered_at?: string | null
          id?: string
          method?: string
          order_id: string
          recipient_name?: string | null
          status?: string
          tracking_reference?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          created_at?: string
          delivered_at?: string | null
          id?: string
          method?: string
          order_id?: string
          recipient_name?: string | null
          status?: string
          tracking_reference?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_deliveries_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_inventory: {
        Row: {
          id: string
          item_name: string
          quantity: number
          reorder_level: number
          sku: string | null
          supplier: string | null
          unit: string
          unit_cost: number
          updated_at: string
        }
        Insert: {
          id?: string
          item_name: string
          quantity?: number
          reorder_level?: number
          sku?: string | null
          supplier?: string | null
          unit?: string
          unit_cost?: number
          updated_at?: string
        }
        Update: {
          id?: string
          item_name?: string
          quantity?: number
          reorder_level?: number
          sku?: string | null
          supplier?: string | null
          unit?: string
          unit_cost?: number
          updated_at?: string
        }
        Relationships: []
      }
      print_invoices: {
        Row: {
          amount: number
          amount_paid: number
          cancelled_from_status: string | null
          created_at: string
          currency: string
          due_at: string | null
          id: string
          invoice_number: string
          order_id: string
          replaces_invoice_id: string | null
          service_description: string | null
          service_name: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id: string
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          amount_paid?: number
          cancelled_from_status?: string | null
          created_at?: string
          currency?: string
          due_at?: string | null
          id?: string
          invoice_number?: string
          order_id?: string
          replaces_invoice_id?: string | null
          service_description?: string | null
          service_name?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_invoices_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_invoices_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "print_invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      print_jobs: {
        Row: {
          assigned_to: string | null
          completed_at: string | null
          created_at: string
          id: string
          internal_notes: string | null
          order_id: string
          progress: number
          stage: string
          started_at: string | null
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          id?: string
          internal_notes?: string | null
          order_id: string
          progress?: number
          stage?: string
          started_at?: string | null
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          completed_at?: string | null
          created_at?: string
          id?: string
          internal_notes?: string | null
          order_id?: string
          progress?: number
          stage?: string
          started_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_jobs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_notifications: {
        Row: {
          body: string
          created_at: string
          id: string
          kind: string
          order_id: string | null
          read_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          id?: string
          kind?: string
          order_id?: string | null
          read_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          id?: string
          kind?: string
          order_id?: string | null
          read_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_notifications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_order_items: {
        Row: {
          description: string
          id: string
          options: Json
          order_id: string
          product_id: string | null
          quantity: number
          total: number
          unit_price: number
        }
        Insert: {
          description: string
          id?: string
          options?: Json
          order_id: string
          product_id?: string | null
          quantity?: number
          total?: number
          unit_price?: number
        }
        Update: {
          description?: string
          id?: string
          options?: Json
          order_id?: string
          product_id?: string | null
          quantity?: number
          total?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "print_order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "print_products"
            referencedColumns: ["id"]
          },
        ]
      }
      print_orders: {
        Row: {
          created_at: string
          delivery_address: string | null
          due_at: string | null
          fulfillment: string
          id: string
          order_number: string
          priority: string
          quote_id: string | null
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          delivery_address?: string | null
          due_at?: string | null
          fulfillment?: string
          id?: string
          order_number?: string
          priority?: string
          quote_id?: string | null
          status?: string
          title: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          delivery_address?: string | null
          due_at?: string | null
          fulfillment?: string
          id?: string
          order_number?: string
          priority?: string
          quote_id?: string | null
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_orders_quote_id_fkey"
            columns: ["quote_id"]
            isOneToOne: false
            referencedRelation: "print_quotes"
            referencedColumns: ["id"]
          },
        ]
      }
      print_payment_intents: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          order_id: string
          paid_at: string | null
          reference: string
          status: string
          transaction_ref: string | null
          updated_at: string
          user_id: string
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          order_id: string
          paid_at?: string | null
          reference: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id: string
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          order_id?: string
          paid_at?: string | null
          reference?: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          user_id?: string
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "print_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "print_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_payment_intents_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      print_payments: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          invoice_id: string
          paid_at: string
          payment_intent_id: string | null
          provider: string
          provider_reference: string
          status: string
          transaction_ref: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id: string
          paid_at: string
          payment_intent_id?: string | null
          provider?: string
          provider_reference: string
          status?: string
          transaction_ref: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          invoice_id?: string
          paid_at?: string
          payment_intent_id?: string | null
          provider?: string
          provider_reference?: string
          status?: string
          transaction_ref?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "print_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_payments_payment_intent_id_fkey"
            columns: ["payment_intent_id"]
            isOneToOne: true
            referencedRelation: "print_payment_intents"
            referencedColumns: ["id"]
          },
        ]
      }
      print_products: {
        Row: {
          active: boolean
          base_price: number
          category: string
          created_at: string
          description: string | null
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          base_price?: number
          category: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          base_price?: number
          category?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      print_proofs: {
        Row: {
          approved_at: string | null
          artwork_id: string | null
          created_at: string
          customer_notes: string | null
          file_path: string
          id: string
          order_id: string
          status: string
          updated_at: string
          version: number
        }
        Insert: {
          approved_at?: string | null
          artwork_id?: string | null
          created_at?: string
          customer_notes?: string | null
          file_path: string
          id?: string
          order_id: string
          status?: string
          updated_at?: string
          version?: number
        }
        Update: {
          approved_at?: string | null
          artwork_id?: string | null
          created_at?: string
          customer_notes?: string | null
          file_path?: string
          id?: string
          order_id?: string
          status?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "print_proofs_artwork_id_fkey"
            columns: ["artwork_id"]
            isOneToOne: false
            referencedRelation: "print_artworks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_proofs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_qc_checks: {
        Row: {
          checked_by: string | null
          checklist: Json
          created_at: string
          defect_notes: string | null
          id: string
          job_id: string
          reprint_required: boolean
          status: string
        }
        Insert: {
          checked_by?: string | null
          checklist?: Json
          created_at?: string
          defect_notes?: string | null
          id?: string
          job_id: string
          reprint_required?: boolean
          status?: string
        }
        Update: {
          checked_by?: string | null
          checklist?: Json
          created_at?: string
          defect_notes?: string | null
          id?: string
          job_id?: string
          reprint_required?: boolean
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_qc_checks_job_id_fkey"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "print_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      print_quotes: {
        Row: {
          created_at: string
          delivery_fee: number
          discount: number
          id: string
          quote_number: string
          specifications: Json
          status: string
          subtotal: number
          tax: number
          title: string
          total: number
          updated_at: string
          user_id: string
          valid_until: string | null
        }
        Insert: {
          created_at?: string
          delivery_fee?: number
          discount?: number
          id?: string
          quote_number?: string
          specifications?: Json
          status?: string
          subtotal?: number
          tax?: number
          title: string
          total?: number
          updated_at?: string
          user_id: string
          valid_until?: string | null
        }
        Update: {
          created_at?: string
          delivery_fee?: number
          discount?: number
          id?: string
          quote_number?: string
          specifications?: Json
          status?: string
          subtotal?: number
          tax?: number
          title?: string
          total?: number
          updated_at?: string
          user_id?: string
          valid_until?: string | null
        }
        Relationships: []
      }
      print_stock_movements: {
        Row: {
          created_at: string
          id: string
          inventory_id: string
          job_id: string | null
          movement: string
          notes: string | null
          quantity: number
        }
        Insert: {
          created_at?: string
          id?: string
          inventory_id: string
          job_id?: string | null
          movement: string
          notes?: string | null
          quantity: number
        }
        Update: {
          created_at?: string
          id?: string
          inventory_id?: string
          job_id?: string | null
          movement?: string
          notes?: string | null
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "print_stock_movements_inventory_id_fkey"
            columns: ["inventory_id"]
            isOneToOne: false
            referencedRelation: "print_inventory"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "print_stock_movements_job_id_fkey"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "print_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      print_support_tickets: {
        Row: {
          created_at: string
          id: string
          message: string
          order_id: string | null
          status: string
          subject: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message: string
          order_id?: string | null
          status?: string
          subject: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string
          order_id?: string | null
          status?: string
          subject?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "print_support_tickets_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "print_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      print_team_members: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          role_title: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          role_title: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          role_title?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          created_at: string
          email: string
          first_name: string | null
          id: string
          last_name: string | null
          middle_name: string | null
          newsletter_opt_in: boolean
          phone: string | null
          requested_service: string | null
          role: Database["public"]["Enums"]["user_role"]
          sex: string | null
          status: Database["public"]["Enums"]["account_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          email: string
          first_name?: string | null
          id: string
          last_name?: string | null
          middle_name?: string | null
          newsletter_opt_in?: boolean
          phone?: string | null
          requested_service?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          sex?: string | null
          status?: Database["public"]["Enums"]["account_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string
          first_name?: string | null
          id?: string
          last_name?: string | null
          middle_name?: string | null
          newsletter_opt_in?: boolean
          phone?: string | null
          requested_service?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          sex?: string | null
          status?: Database["public"]["Enums"]["account_status"]
          updated_at?: string
        }
        Relationships: []
      }
      qa_acceptance_runs: {
        Row: {
          cleaned_at: string | null
          created_at: string
          id: string
          payload: Json
          platform_code: string
          result: Json
          run_code: string
          scenario: string
          status: string
          updated_at: string
        }
        Insert: {
          cleaned_at?: string | null
          created_at?: string
          id?: string
          payload?: Json
          platform_code: string
          result?: Json
          run_code?: string
          scenario?: string
          status?: string
          updated_at?: string
        }
        Update: {
          cleaned_at?: string | null
          created_at?: string
          id?: string
          payload?: Json
          platform_code?: string
          result?: Json
          run_code?: string
          scenario?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      recovery_drills: {
        Row: {
          completed_at: string | null
          created_at: string
          created_by: string
          drill_number: number
          drill_type: string
          evidence: string | null
          id: string
          scheduled_at: string
          scope: string
          status: string
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          created_by: string
          drill_number?: never
          drill_type: string
          evidence?: string | null
          id?: string
          scheduled_at: string
          scope: string
          status?: string
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          created_by?: string
          drill_number?: never
          drill_type?: string
          evidence?: string | null
          id?: string
          scheduled_at?: string
          scope?: string
          status?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "recovery_drills_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recovery_drills_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_academic_documents: {
        Row: {
          created_at: string
          document_type: string
          id: string
          issued_at: string | null
          issued_by: string | null
          metadata: Json
          school_id: string
          serial_number: string
          session: string | null
          student_id: string
          title: string
        }
        Insert: {
          created_at?: string
          document_type: string
          id?: string
          issued_at?: string | null
          issued_by?: string | null
          metadata?: Json
          school_id: string
          serial_number?: string
          session?: string | null
          student_id: string
          title: string
        }
        Update: {
          created_at?: string
          document_type?: string
          id?: string
          issued_at?: string | null
          issued_by?: string | null
          metadata?: Json
          school_id?: string
          serial_number?: string
          session?: string | null
          student_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_academic_documents_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_academic_documents_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_access_invitations: {
        Row: {
          accepted_at: string | null
          created_by: string
          email: string
          expires_at: string
          id: string
          relationship: string
          role: string
          school_id: string
          student_ids: string[]
          token_hash: string
        }
        Insert: {
          accepted_at?: string | null
          created_by: string
          email: string
          expires_at?: string
          id?: string
          relationship?: string
          role: string
          school_id: string
          student_ids?: string[]
          token_hash: string
        }
        Update: {
          accepted_at?: string | null
          created_by?: string
          email?: string
          expires_at?: string
          id?: string
          relationship?: string
          role?: string
          school_id?: string
          student_ids?: string[]
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_access_invitations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_access_invitations_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_account_challenges: {
        Row: {
          expires_at: string
          token_hash: string
          user_id: string
        }
        Insert: {
          expires_at?: string
          token_hash: string
          user_id: string
        }
        Update: {
          expires_at?: string
          token_hash?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_account_challenges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_initial_credentials"
            referencedColumns: ["user_id"]
          },
        ]
      }
      schoolpro_admission_acceptances: {
        Row: {
          accepted_at: string
          accepted_by_email: string | null
          accepted_by_name: string
          application_id: string
          id: string
          notes: string | null
          offer_id: string | null
          terms_accepted: boolean
        }
        Insert: {
          accepted_at?: string
          accepted_by_email?: string | null
          accepted_by_name: string
          application_id: string
          id?: string
          notes?: string | null
          offer_id?: string | null
          terms_accepted?: boolean
        }
        Update: {
          accepted_at?: string
          accepted_by_email?: string | null
          accepted_by_name?: string
          application_id?: string
          id?: string
          notes?: string | null
          offer_id?: string | null
          terms_accepted?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_admission_acceptances_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_admissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_admission_acceptances_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_admission_offers"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_admission_documents: {
        Row: {
          application_id: string
          created_at: string
          document_type: string
          file_name: string | null
          file_size: number | null
          file_url: string
          id: string
          mime_type: string | null
          storage_path: string | null
          verification_notes: string | null
          verified: boolean
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          application_id: string
          created_at?: string
          document_type: string
          file_name?: string | null
          file_size?: number | null
          file_url: string
          id?: string
          mime_type?: string | null
          storage_path?: string | null
          verification_notes?: string | null
          verified?: boolean
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          application_id?: string
          created_at?: string
          document_type?: string
          file_name?: string | null
          file_size?: number | null
          file_url?: string
          id?: string
          mime_type?: string | null
          storage_path?: string | null
          verification_notes?: string | null
          verified?: boolean
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_admission_documents_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_admissions"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_admission_events: {
        Row: {
          application_id: string
          created_at: string
          event_type: string
          id: string
          location: string | null
          notes: string | null
          scheduled_at: string | null
          status: string
        }
        Insert: {
          application_id: string
          created_at?: string
          event_type: string
          id?: string
          location?: string | null
          notes?: string | null
          scheduled_at?: string | null
          status?: string
        }
        Update: {
          application_id?: string
          created_at?: string
          event_type?: string
          id?: string
          location?: string | null
          notes?: string | null
          scheduled_at?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_admission_events_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_admissions"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_admission_offers: {
        Row: {
          acceptance_instructions: string | null
          accepted_at: string | null
          application_id: string
          expires_at: string | null
          id: string
          issued_at: string
          letter_body: string | null
          offer_number: string
          offered_class: string | null
          public_token: string
          status: string
        }
        Insert: {
          acceptance_instructions?: string | null
          accepted_at?: string | null
          application_id: string
          expires_at?: string | null
          id?: string
          issued_at?: string
          letter_body?: string | null
          offer_number: string
          offered_class?: string | null
          public_token?: string
          status?: string
        }
        Update: {
          acceptance_instructions?: string | null
          accepted_at?: string | null
          application_id?: string
          expires_at?: string | null
          id?: string
          issued_at?: string
          letter_body?: string | null
          offer_number?: string
          offered_class?: string | null
          public_token?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_admission_offers_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_admissions"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_admissions: {
        Row: {
          acceptance_fee_status: string
          accepted_at: string | null
          admitted_student_id: string | null
          applicant_name: string
          application_number: string | null
          class_applied: string | null
          created_at: string
          date_of_birth: string | null
          enrolled_at: string | null
          enrollment_status: string
          entrance_score: number | null
          entrance_test_id: string | null
          first_name: string | null
          gender: string | null
          guardian_contact: string | null
          guardian_email: string | null
          guardian_name: string | null
          id: string
          last_name: string | null
          notes: string | null
          previous_school: string | null
          public_token: string
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          status: string
          submitted_at: string | null
        }
        Insert: {
          acceptance_fee_status?: string
          accepted_at?: string | null
          admitted_student_id?: string | null
          applicant_name: string
          application_number?: string | null
          class_applied?: string | null
          created_at?: string
          date_of_birth?: string | null
          enrolled_at?: string | null
          enrollment_status?: string
          entrance_score?: number | null
          entrance_test_id?: string | null
          first_name?: string | null
          gender?: string | null
          guardian_contact?: string | null
          guardian_email?: string | null
          guardian_name?: string | null
          id?: string
          last_name?: string | null
          notes?: string | null
          previous_school?: string | null
          public_token?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          status?: string
          submitted_at?: string | null
        }
        Update: {
          acceptance_fee_status?: string
          accepted_at?: string | null
          admitted_student_id?: string | null
          applicant_name?: string
          application_number?: string | null
          class_applied?: string | null
          created_at?: string
          date_of_birth?: string | null
          enrolled_at?: string | null
          enrollment_status?: string
          entrance_score?: number | null
          entrance_test_id?: string | null
          first_name?: string | null
          gender?: string | null
          guardian_contact?: string | null
          guardian_email?: string | null
          guardian_name?: string | null
          id?: string
          last_name?: string | null
          notes?: string | null
          previous_school?: string | null
          public_token?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          status?: string
          submitted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_admissions_admitted_student_id_fkey"
            columns: ["admitted_student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_admissions_entrance_test_id_fkey"
            columns: ["entrance_test_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_tests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_admissions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_announcements: {
        Row: {
          audience: string
          body: string
          created_at: string
          created_by: string | null
          id: string
          published: boolean
          published_at: string | null
          school_id: string
          session: string | null
          title: string
        }
        Insert: {
          audience?: string
          body: string
          created_at?: string
          created_by?: string | null
          id?: string
          published?: boolean
          published_at?: string | null
          school_id: string
          session?: string | null
          title: string
        }
        Update: {
          audience?: string
          body?: string
          created_at?: string
          created_by?: string | null
          id?: string
          published?: boolean
          published_at?: string | null
          school_id?: string
          session?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_announcements_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_assessment_schemes: {
        Row: {
          components: Json
          created_at: string
          id: string
          is_default: boolean
          name: string
          school_id: string
          school_level: string
          updated_at: string
        }
        Insert: {
          components: Json
          created_at?: string
          id?: string
          is_default?: boolean
          name: string
          school_id: string
          school_level?: string
          updated_at?: string
        }
        Update: {
          components?: Json
          created_at?: string
          id?: string
          is_default?: boolean
          name?: string
          school_id?: string
          school_level?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_assessment_schemes_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_assignment_submissions: {
        Row: {
          assignment_id: string
          feedback: string | null
          file_url: string | null
          graded_at: string | null
          graded_by: string | null
          id: string
          score: number | null
          status: string
          student_id: string
          submission_text: string | null
          submitted_at: string
        }
        Insert: {
          assignment_id: string
          feedback?: string | null
          file_url?: string | null
          graded_at?: string | null
          graded_by?: string | null
          id?: string
          score?: number | null
          status?: string
          student_id: string
          submission_text?: string | null
          submitted_at?: string
        }
        Update: {
          assignment_id?: string
          feedback?: string | null
          file_url?: string | null
          graded_at?: string | null
          graded_by?: string | null
          id?: string
          score?: number | null
          status?: string
          student_id?: string
          submission_text?: string | null
          submitted_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_assignment_submissions_assignment_id_fkey"
            columns: ["assignment_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_assignment_submissions_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_assignments: {
        Row: {
          class_id: string
          created_at: string
          created_by: string | null
          due_at: string | null
          id: string
          instructions: string | null
          max_score: number
          school_id: string
          session: string
          subject_id: string
          title: string
        }
        Insert: {
          class_id: string
          created_at?: string
          created_by?: string | null
          due_at?: string | null
          id?: string
          instructions?: string | null
          max_score?: number
          school_id: string
          session: string
          subject_id: string
          title: string
        }
        Update: {
          class_id?: string
          created_at?: string
          created_by?: string | null
          due_at?: string | null
          id?: string
          instructions?: string | null
          max_score?: number
          school_id?: string
          session?: string
          subject_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_assignments_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_assignments_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_assignments_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_attendance: {
        Row: {
          attendance_date: string
          class_id: string
          created_at: string
          id: string
          marked_by: string
          notes: string | null
          school_id: string
          session: string | null
          status: Database["public"]["Enums"]["schoolpro_attendance_status"]
          student_id: string
          term: string | null
          updated_at: string
        }
        Insert: {
          attendance_date?: string
          class_id: string
          created_at?: string
          id?: string
          marked_by?: string
          notes?: string | null
          school_id: string
          session?: string | null
          status?: Database["public"]["Enums"]["schoolpro_attendance_status"]
          student_id: string
          term?: string | null
          updated_at?: string
        }
        Update: {
          attendance_date?: string
          class_id?: string
          created_at?: string
          id?: string
          marked_by?: string
          notes?: string | null
          school_id?: string
          session?: string | null
          status?: Database["public"]["Enums"]["schoolpro_attendance_status"]
          student_id?: string
          term?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_attendance_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_attendance_marked_by_fkey"
            columns: ["marked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_attendance_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_attendance_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          entity_id: string | null
          entity_type: string | null
          id: number
          metadata: Json
          school_id: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string | null
          id?: number
          metadata?: Json
          school_id?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          entity_id?: string | null
          entity_type?: string | null
          id?: number
          metadata?: Json
          school_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_audit_logs_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_bank_accounts: {
        Row: {
          account_name: string
          account_number: string
          active: boolean
          bank_name: string
          created_at: string
          created_by: string | null
          id: string
          is_primary: boolean
          school_id: string
          updated_at: string
        }
        Insert: {
          account_name: string
          account_number: string
          active?: boolean
          bank_name: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_primary?: boolean
          school_id: string
          updated_at?: string
        }
        Update: {
          account_name?: string
          account_number?: string
          active?: boolean
          bank_name?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_primary?: boolean
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_bank_accounts_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_board_members: {
        Row: {
          appointed_at: string
          appointed_by: string
          member_id: string
          previous_role: Database["public"]["Enums"]["school_member_role"]
          school_id: string
          title: string
        }
        Insert: {
          appointed_at?: string
          appointed_by: string
          member_id: string
          previous_role: Database["public"]["Enums"]["school_member_role"]
          school_id: string
          title: string
        }
        Update: {
          appointed_at?: string
          appointed_by?: string
          member_id?: string
          previous_role?: Database["public"]["Enums"]["school_member_role"]
          school_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_board_members_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_board_members_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_branding: {
        Row: {
          custom_domain: string | null
          display_name: string | null
          footer_text: string | null
          hero_message: string | null
          id: string
          logo_url: string | null
          portal_slug: string | null
          primary_color: string | null
          school_id: string
          secondary_color: string | null
          updated_at: string
          white_label: boolean
        }
        Insert: {
          custom_domain?: string | null
          display_name?: string | null
          footer_text?: string | null
          hero_message?: string | null
          id?: string
          logo_url?: string | null
          portal_slug?: string | null
          primary_color?: string | null
          school_id: string
          secondary_color?: string | null
          updated_at?: string
          white_label?: boolean
        }
        Update: {
          custom_domain?: string | null
          display_name?: string | null
          footer_text?: string | null
          hero_message?: string | null
          id?: string
          logo_url?: string | null
          portal_slug?: string | null
          primary_color?: string | null
          school_id?: string
          secondary_color?: string | null
          updated_at?: string
          white_label?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_branding_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_calendar_events: {
        Row: {
          class_id: string | null
          created_at: string
          details: string | null
          end_date: string | null
          event_date: string
          event_type: string | null
          id: string
          school_id: string
          session: string | null
          title: string
        }
        Insert: {
          class_id?: string | null
          created_at?: string
          details?: string | null
          end_date?: string | null
          event_date: string
          event_type?: string | null
          id?: string
          school_id: string
          session?: string | null
          title: string
        }
        Update: {
          class_id?: string | null
          created_at?: string
          details?: string | null
          end_date?: string | null
          event_date?: string
          event_type?: string | null
          id?: string
          school_id?: string
          session?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_calendar_events_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_calendar_events_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_candidate_cbt_answers: {
        Row: {
          answer: string | null
          attempt_id: string
          feedback: string | null
          id: string
          is_correct: boolean | null
          marked_at: string | null
          marked_by: string | null
          marks_awarded: number
          question_id: string
        }
        Insert: {
          answer?: string | null
          attempt_id: string
          feedback?: string | null
          id?: string
          is_correct?: boolean | null
          marked_at?: string | null
          marked_by?: string | null
          marks_awarded?: number
          question_id: string
        }
        Update: {
          answer?: string | null
          attempt_id?: string
          feedback?: string | null
          id?: string
          is_correct?: boolean | null
          marked_at?: string | null
          marked_by?: string | null
          marks_awarded?: number
          question_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_candidate_cbt_answers_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_candidate_cbt_attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_candidate_cbt_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_question_bank"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_candidate_cbt_attempts: {
        Row: {
          access_token: string
          application_id: string
          duration_minutes: number | null
          expires_at: string | null
          id: string
          last_saved_at: string | null
          score: number | null
          started_at: string
          status: string
          submitted_at: string | null
          test_id: string
        }
        Insert: {
          access_token?: string
          application_id: string
          duration_minutes?: number | null
          expires_at?: string | null
          id?: string
          last_saved_at?: string | null
          score?: number | null
          started_at?: string
          status?: string
          submitted_at?: string | null
          test_id: string
        }
        Update: {
          access_token?: string
          application_id?: string
          duration_minutes?: number | null
          expires_at?: string | null
          id?: string
          last_saved_at?: string | null
          score?: number | null
          started_at?: string
          status?: string
          submitted_at?: string | null
          test_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_candidate_cbt_attempts_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_admissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_candidate_cbt_attempts_test_id_fkey"
            columns: ["test_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_tests"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_cbt_answers: {
        Row: {
          answer: string | null
          attempt_id: string
          feedback: string | null
          id: string
          is_correct: boolean | null
          marked_at: string | null
          marked_by: string | null
          marks_awarded: number
          question_id: string
        }
        Insert: {
          answer?: string | null
          attempt_id: string
          feedback?: string | null
          id?: string
          is_correct?: boolean | null
          marked_at?: string | null
          marked_by?: string | null
          marks_awarded?: number
          question_id: string
        }
        Update: {
          answer?: string | null
          attempt_id?: string
          feedback?: string | null
          id?: string
          is_correct?: boolean | null
          marked_at?: string | null
          marked_by?: string | null
          marks_awarded?: number
          question_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_cbt_answers_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_question_bank"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_cbt_attempts: {
        Row: {
          attempt_no: number
          expires_at: string | null
          id: string
          score: number | null
          started_at: string
          status: string
          student_id: string
          submitted_at: string | null
          test_id: string
        }
        Insert: {
          attempt_no?: number
          expires_at?: string | null
          id?: string
          score?: number | null
          started_at?: string
          status?: string
          student_id: string
          submitted_at?: string | null
          test_id: string
        }
        Update: {
          attempt_no?: number
          expires_at?: string | null
          id?: string
          score?: number | null
          started_at?: string
          status?: string
          student_id?: string
          submitted_at?: string | null
          test_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_cbt_attempts_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_attempts_test_id_fkey"
            columns: ["test_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_tests"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_cbt_eligibility: {
        Row: {
          assigned_by: string | null
          class_id: string | null
          created_at: string
          eligible: boolean
          id: string
          school_id: string
          student_id: string | null
          test_id: string
        }
        Insert: {
          assigned_by?: string | null
          class_id?: string | null
          created_at?: string
          eligible?: boolean
          id?: string
          school_id: string
          student_id?: string | null
          test_id: string
        }
        Update: {
          assigned_by?: string | null
          class_id?: string | null
          created_at?: string
          eligible?: boolean
          id?: string
          school_id?: string
          student_id?: string | null
          test_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_cbt_eligibility_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_eligibility_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_eligibility_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_eligibility_test_id_fkey"
            columns: ["test_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_tests"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_cbt_test_questions: {
        Row: {
          id: string
          position: number
          question_id: string
          test_id: string
        }
        Insert: {
          id?: string
          position?: number
          question_id: string
          test_id: string
        }
        Update: {
          id?: string
          position?: number
          question_id?: string
          test_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_cbt_test_questions_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_question_bank"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_test_questions_test_id_fkey"
            columns: ["test_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_cbt_tests"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_cbt_tests: {
        Row: {
          attempts_allowed: number
          class_id: string | null
          closes_at: string | null
          created_at: string
          created_by: string | null
          duration_minutes: number
          id: string
          instructions: string | null
          opens_at: string | null
          randomize_options: boolean
          randomize_questions: boolean
          school_id: string
          status: string
          subject_id: string | null
          test_type: string
          title: string
          total_marks: number
        }
        Insert: {
          attempts_allowed?: number
          class_id?: string | null
          closes_at?: string | null
          created_at?: string
          created_by?: string | null
          duration_minutes?: number
          id?: string
          instructions?: string | null
          opens_at?: string | null
          randomize_options?: boolean
          randomize_questions?: boolean
          school_id: string
          status?: string
          subject_id?: string | null
          test_type?: string
          title: string
          total_marks?: number
        }
        Update: {
          attempts_allowed?: number
          class_id?: string | null
          closes_at?: string | null
          created_at?: string
          created_by?: string | null
          duration_minutes?: number
          id?: string
          instructions?: string | null
          opens_at?: string | null
          randomize_options?: boolean
          randomize_questions?: boolean
          school_id?: string
          status?: string
          subject_id?: string | null
          test_type?: string
          title?: string
          total_marks?: number
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_cbt_tests_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_tests_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_cbt_tests_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_charge_categories: {
        Row: {
          active: boolean
          code: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          name: string
          school_id: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          code: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name: string
          school_id: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          code?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name?: string
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_charge_categories_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_class_result_submissions: {
        Row: {
          class_id: string
          id: string
          school_id: string
          score_fingerprint: string
          session: string
          submitted_at: string
          submitted_by: string
          term: string
        }
        Insert: {
          class_id: string
          id?: string
          school_id: string
          score_fingerprint: string
          session: string
          submitted_at?: string
          submitted_by: string
          term: string
        }
        Update: {
          class_id?: string
          id?: string
          school_id?: string
          score_fingerprint?: string
          session?: string
          submitted_at?: string
          submitted_by?: string
          term?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_class_result_submissions_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_class_result_submissions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_classes: {
        Row: {
          arm: string
          capacity: number
          created_at: string
          form_teacher_id: string | null
          id: string
          level: string
          name: string
          school_id: string
          updated_at: string
        }
        Insert: {
          arm?: string
          capacity?: number
          created_at?: string
          form_teacher_id?: string | null
          id?: string
          level: string
          name: string
          school_id: string
          updated_at?: string
        }
        Update: {
          arm?: string
          capacity?: number
          created_at?: string
          form_teacher_id?: string | null
          id?: string
          level?: string
          name?: string
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_classes_form_teacher_id_fkey"
            columns: ["form_teacher_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_classes_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_custom_requests: {
        Row: {
          about_text: string | null
          approved_at: string | null
          contact_name: string
          created_at: string
          currency: string
          desired_domain: string | null
          email: string
          existing_domain: string | null
          id: string
          invoice_reference: string | null
          logo_url: string | null
          motto: string | null
          notes: string | null
          package_interest: string
          payment_status: string
          phone: string | null
          primary_color: string | null
          provisioned_at: string | null
          provisioning_notes: string | null
          quote_accepted_at: string | null
          quote_expires_at: string | null
          quote_notes: string | null
          quoted_amount: number | null
          requested_modules: string[]
          requested_pages: string[]
          requester_user_id: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string | null
          school_name: string
          secondary_color: string | null
          status: string
          updated_at: string
        }
        Insert: {
          about_text?: string | null
          approved_at?: string | null
          contact_name: string
          created_at?: string
          currency?: string
          desired_domain?: string | null
          email: string
          existing_domain?: string | null
          id?: string
          invoice_reference?: string | null
          logo_url?: string | null
          motto?: string | null
          notes?: string | null
          package_interest?: string
          payment_status?: string
          phone?: string | null
          primary_color?: string | null
          provisioned_at?: string | null
          provisioning_notes?: string | null
          quote_accepted_at?: string | null
          quote_expires_at?: string | null
          quote_notes?: string | null
          quoted_amount?: number | null
          requested_modules?: string[]
          requested_pages?: string[]
          requester_user_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name: string
          secondary_color?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          about_text?: string | null
          approved_at?: string | null
          contact_name?: string
          created_at?: string
          currency?: string
          desired_domain?: string | null
          email?: string
          existing_domain?: string | null
          id?: string
          invoice_reference?: string | null
          logo_url?: string | null
          motto?: string | null
          notes?: string | null
          package_interest?: string
          payment_status?: string
          phone?: string | null
          primary_color?: string | null
          provisioned_at?: string | null
          provisioning_notes?: string | null
          quote_accepted_at?: string | null
          quote_expires_at?: string | null
          quote_notes?: string | null
          quoted_amount?: number | null
          requested_modules?: string[]
          requested_pages?: string[]
          requester_user_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name?: string
          secondary_color?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_custom_requests_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_demo_requests: {
        Row: {
          activated_at: string | null
          calendar_path: string | null
          contact_name: string
          created_at: string
          email: string
          exam_end: string | null
          exam_start: string | null
          free_access_ends_at: string | null
          id: string
          letter_path: string | null
          meeting_format: string | null
          notes: string | null
          phone: string | null
          preferred_date: string | null
          preferred_time: string | null
          review_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string | null
          school_name: string
          status: string
          term_end: string | null
          term_start: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          activated_at?: string | null
          calendar_path?: string | null
          contact_name: string
          created_at?: string
          email: string
          exam_end?: string | null
          exam_start?: string | null
          free_access_ends_at?: string | null
          id?: string
          letter_path?: string | null
          meeting_format?: string | null
          notes?: string | null
          phone?: string | null
          preferred_date?: string | null
          preferred_time?: string | null
          review_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name: string
          status?: string
          term_end?: string | null
          term_start?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          activated_at?: string | null
          calendar_path?: string | null
          contact_name?: string
          created_at?: string
          email?: string
          exam_end?: string | null
          exam_start?: string | null
          free_access_ends_at?: string | null
          id?: string
          letter_path?: string | null
          meeting_format?: string | null
          notes?: string | null
          phone?: string | null
          preferred_date?: string | null
          preferred_time?: string | null
          review_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name?: string
          status?: string
          term_end?: string | null
          term_start?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_demo_requests_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_demo_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_discipline_records: {
        Row: {
          action_taken: string | null
          created_at: string
          created_by: string | null
          id: string
          incident: string
          school_id: string
          session: string | null
          status: string
          student_id: string | null
          term: string | null
        }
        Insert: {
          action_taken?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          incident: string
          school_id: string
          session?: string | null
          status?: string
          student_id?: string | null
          term?: string | null
        }
        Update: {
          action_taken?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          incident?: string
          school_id?: string
          session?: string | null
          status?: string
          student_id?: string | null
          term?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_discipline_records_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_discipline_records_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_document_issue_events: {
        Row: {
          actor_id: string | null
          created_at: string
          event_type: string
          id: string
          issue_id: string
          reason: string | null
          school_id: string
          snapshot: Json
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          event_type: string
          id?: string
          issue_id: string
          reason?: string | null
          school_id: string
          snapshot: Json
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          event_type?: string
          id?: string
          issue_id?: string
          reason?: string | null
          school_id?: string
          snapshot?: Json
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_document_issue_events_issue_id_fkey"
            columns: ["issue_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_document_issues"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_document_issue_events_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_document_issues: {
        Row: {
          created_at: string
          document_type: string
          id: string
          issued_at: string | null
          issued_by: string | null
          output_storage_path: string | null
          payload: Json
          school_id: string
          serial_number: string
          status: string
          student_id: string | null
          template_id: string | null
          title: string
        }
        Insert: {
          created_at?: string
          document_type: string
          id?: string
          issued_at?: string | null
          issued_by?: string | null
          output_storage_path?: string | null
          payload?: Json
          school_id: string
          serial_number?: string
          status?: string
          student_id?: string | null
          template_id?: string | null
          title: string
        }
        Update: {
          created_at?: string
          document_type?: string
          id?: string
          issued_at?: string | null
          issued_by?: string | null
          output_storage_path?: string | null
          payload?: Json
          school_id?: string
          serial_number?: string
          status?: string
          student_id?: string | null
          template_id?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_document_issues_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_document_issues_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_document_issues_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_document_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_document_templates: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          document_type: string
          field_mappings: Json
          id: string
          is_active: boolean
          is_default: boolean
          mime_type: string
          name: string
          original_filename: string
          page_count: number | null
          school_id: string
          settings: Json
          source_format: string
          storage_path: string
          updated_at: string
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          document_type: string
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          mime_type: string
          name: string
          original_filename: string
          page_count?: number | null
          school_id: string
          settings?: Json
          source_format: string
          storage_path: string
          updated_at?: string
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          document_type?: string
          field_mappings?: Json
          id?: string
          is_active?: boolean
          is_default?: boolean
          mime_type?: string
          name?: string
          original_filename?: string
          page_count?: number | null
          school_id?: string
          settings?: Json
          source_format?: string
          storage_path?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_document_templates_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_email_queue: {
        Row: {
          attempts: number
          created_at: string
          error: string | null
          id: string
          last_attempt_at: string | null
          payload: Json
          provider_message_id: string | null
          recipient_email: string
          recipient_name: string | null
          scheduled_at: string
          school_id: string | null
          sent_at: string | null
          status: string
          subject: string
          template_key: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          error?: string | null
          id?: string
          last_attempt_at?: string | null
          payload?: Json
          provider_message_id?: string | null
          recipient_email: string
          recipient_name?: string | null
          scheduled_at?: string
          school_id?: string | null
          sent_at?: string | null
          status?: string
          subject: string
          template_key: string
        }
        Update: {
          attempts?: number
          created_at?: string
          error?: string | null
          id?: string
          last_attempt_at?: string | null
          payload?: Json
          provider_message_id?: string | null
          recipient_email?: string
          recipient_name?: string | null
          scheduled_at?: string
          school_id?: string | null
          sent_at?: string | null
          status?: string
          subject?: string
          template_key?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_email_queue_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_enrollment_history: {
        Row: {
          arm: string
          class_id: string
          class_name: string
          created_at: string
          graduation_year: number | null
          promotion_id: string | null
          school_id: string
          section: string
          session: string
          status: string
          student_id: string
        }
        Insert: {
          arm?: string
          class_id: string
          class_name: string
          created_at?: string
          graduation_year?: number | null
          promotion_id?: string | null
          school_id: string
          section: string
          session: string
          status: string
          student_id: string
        }
        Update: {
          arm?: string
          class_id?: string
          class_name?: string
          created_at?: string
          graduation_year?: number | null
          promotion_id?: string | null
          school_id?: string
          section?: string
          session?: string
          status?: string
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_enrollment_history_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_enrollment_history_promotion_id_fkey"
            columns: ["promotion_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_promotions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_enrollment_history_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_enrollment_history_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_feature_overrides: {
        Row: {
          enabled: boolean
          feature: string
          id: string
          reason: string | null
          school_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          enabled: boolean
          feature: string
          id?: string
          reason?: string | null
          school_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          enabled?: boolean
          feature?: string
          id?: string
          reason?: string | null
          school_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_feature_overrides_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_bank_accounts: {
        Row: {
          account_name: string | null
          account_number: string | null
          bank_name: string | null
          is_active: boolean
          receiving_account_id: string | null
          school_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          account_name?: string | null
          account_number?: string | null
          bank_name?: string | null
          is_active?: boolean
          receiving_account_id?: string | null
          school_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          account_name?: string | null
          account_number?: string | null
          bank_name?: string | null
          is_active?: boolean
          receiving_account_id?: string | null
          school_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_bank_accounts_receiving_account_id_fkey"
            columns: ["receiving_account_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_bank_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_bank_accounts_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_exceptions: {
        Row: {
          discount: number
          exception_type: string
          id: string
          notes: string | null
          partial_waiver: number
          scholarship: number
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at: string
          updated_by: string
          value: number
          value_type: string
          waived: boolean
        }
        Insert: {
          discount?: number
          exception_type?: string
          id?: string
          notes?: string | null
          partial_waiver?: number
          scholarship?: number
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at?: string
          updated_by: string
          value?: number
          value_type?: string
          waived?: boolean
        }
        Update: {
          discount?: number
          exception_type?: string
          id?: string
          notes?: string | null
          partial_waiver?: number
          scholarship?: number
          school_id?: string
          session?: string
          student_id?: string
          term?: string
          updated_at?: string
          updated_by?: string
          value?: number
          value_type?: string
          waived?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_exceptions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_exceptions_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_items: {
        Row: {
          amount: number
          category: string
          created_at: string
          fee_structure_id: string
          id: string
          is_optional: boolean
          label: string
          sort_order: number
        }
        Insert: {
          amount: number
          category?: string
          created_at?: string
          fee_structure_id: string
          id?: string
          is_optional?: boolean
          label: string
          sort_order?: number
        }
        Update: {
          amount?: number
          category?: string
          created_at?: string
          fee_structure_id?: string
          id?: string
          is_optional?: boolean
          label?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_items_fee_structure_id_fkey"
            columns: ["fee_structure_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_fee_structures"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_payments: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          method: string
          notes: string | null
          paid_at: string
          recorded_by: string
          reference: string
          school_id: string
          student_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          method: string
          notes?: string | null
          paid_at?: string
          recorded_by: string
          reference: string
          school_id: string
          student_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          method?: string
          notes?: string | null
          paid_at?: string
          recorded_by?: string
          reference?: string
          school_id?: string
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_payments_recorded_by_fkey"
            columns: ["recorded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_payments_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_payments_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_records: {
        Row: {
          amount_due: number
          amount_paid: number
          created_at: string
          id: string
          paid_at: string | null
          payment_method: string | null
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Insert: {
          amount_due: number
          amount_paid?: number
          created_at?: string
          id?: string
          paid_at?: string | null
          payment_method?: string | null
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Update: {
          amount_due?: number
          amount_paid?: number
          created_at?: string
          id?: string
          paid_at?: string | null
          payment_method?: string | null
          school_id?: string
          session?: string
          student_id?: string
          term?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_records_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_records_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_fee_structures: {
        Row: {
          amount: number
          class_name: string | null
          created_at: string
          created_by: string
          due_date: string | null
          id: string
          is_active: boolean
          name: string
          school_id: string
          session: string
          term: string
          updated_at: string
        }
        Insert: {
          amount: number
          class_name?: string | null
          created_at?: string
          created_by: string
          due_date?: string | null
          id?: string
          is_active?: boolean
          name: string
          school_id: string
          session: string
          term: string
          updated_at?: string
        }
        Update: {
          amount?: number
          class_name?: string | null
          created_at?: string
          created_by?: string
          due_date?: string | null
          id?: string
          is_active?: boolean
          name?: string
          school_id?: string
          session?: string
          term?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_fee_structures_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_fee_structures_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_finance_settings: {
        Row: {
          allowed_outstanding: number
          block_results_for_attendance: boolean
          block_results_when_owing: boolean
          minimum_attendance_percent: number
          school_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          allowed_outstanding?: number
          block_results_for_attendance?: boolean
          block_results_when_owing?: boolean
          minimum_attendance_percent?: number
          school_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          allowed_outstanding?: number
          block_results_for_attendance?: boolean
          block_results_when_owing?: boolean
          minimum_attendance_percent?: number
          school_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_finance_settings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_finance_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_generated_result_outputs: {
        Row: {
          format: string
          generated_at: string
          generated_by: string | null
          id: string
          school_id: string
          session: string
          storage_path: string
          student_id: string
          term: string
        }
        Insert: {
          format: string
          generated_at?: string
          generated_by?: string | null
          id?: string
          school_id: string
          session: string
          storage_path: string
          student_id: string
          term: string
        }
        Update: {
          format?: string
          generated_at?: string
          generated_by?: string | null
          id?: string
          school_id?: string
          session?: string
          storage_path?: string
          student_id?: string
          term?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_generated_result_outputs_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_generated_result_outputs_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_grade_scale: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          label: string
          max_score: number
          min_score: number
          overall_remark: string | null
          position: number
          remark: string | null
          school_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          label: string
          max_score: number
          min_score: number
          overall_remark?: string | null
          position?: number
          remark?: string | null
          school_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          label?: string
          max_score?: number
          min_score?: number
          overall_remark?: string | null
          position?: number
          remark?: string | null
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_grade_scale_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_guardian_links: {
        Row: {
          created_at: string
          guardian_user_id: string
          id: string
          linked_by: string
          relationship: string
          school_id: string
          status: string
          student_id: string
        }
        Insert: {
          created_at?: string
          guardian_user_id: string
          id?: string
          linked_by: string
          relationship?: string
          school_id: string
          status?: string
          student_id: string
        }
        Update: {
          created_at?: string
          guardian_user_id?: string
          id?: string
          linked_by?: string
          relationship?: string
          school_id?: string
          status?: string
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_guardian_links_guardian_user_id_fkey"
            columns: ["guardian_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_guardian_links_linked_by_fkey"
            columns: ["linked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_guardian_links_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_guardian_links_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_health_records: {
        Row: {
          assessment: string | null
          complaint: string
          created_at: string
          disposition: string | null
          follow_up_date: string | null
          follow_up_notes: string | null
          id: string
          recorded_at: string
          recorded_by: string | null
          school_id: string
          session: string | null
          status: string
          student_id: string
          term: string | null
          treatment: string | null
        }
        Insert: {
          assessment?: string | null
          complaint: string
          created_at?: string
          disposition?: string | null
          follow_up_date?: string | null
          follow_up_notes?: string | null
          id?: string
          recorded_at?: string
          recorded_by?: string | null
          school_id: string
          session?: string | null
          status?: string
          student_id: string
          term?: string | null
          treatment?: string | null
        }
        Update: {
          assessment?: string | null
          complaint?: string
          created_at?: string
          disposition?: string | null
          follow_up_date?: string | null
          follow_up_notes?: string | null
          id?: string
          recorded_at?: string
          recorded_by?: string | null
          school_id?: string
          session?: string | null
          status?: string
          student_id?: string
          term?: string | null
          treatment?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_health_records_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_health_records_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_hostel_allocations: {
        Row: {
          active: boolean
          id: string
          room_id: string
          school_id: string
          session: string
          student_id: string
        }
        Insert: {
          active?: boolean
          id?: string
          room_id: string
          school_id: string
          session: string
          student_id: string
        }
        Update: {
          active?: boolean
          id?: string
          room_id?: string
          school_id?: string
          session?: string
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_hostel_allocations_room_id_fkey"
            columns: ["room_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_hostel_rooms"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_hostel_allocations_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_hostel_allocations_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_hostel_rooms: {
        Row: {
          capacity: number
          created_at: string
          fee: number
          hostel_name: string
          id: string
          occupied: number
          room: string
          school_id: string
        }
        Insert: {
          capacity?: number
          created_at?: string
          fee?: number
          hostel_name: string
          id?: string
          occupied?: number
          room: string
          school_id: string
        }
        Update: {
          capacity?: number
          created_at?: string
          fee?: number
          hostel_name?: string
          id?: string
          occupied?: number
          room?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_hostel_rooms_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_initial_credentials: {
        Row: {
          consumed_at: string | null
          expires_at: string
          school_id: string
          surname_hash: string
          user_id: string
        }
        Insert: {
          consumed_at?: string | null
          expires_at?: string
          school_id: string
          surname_hash: string
          user_id: string
        }
        Update: {
          consumed_at?: string | null
          expires_at?: string
          school_id?: string
          surname_hash?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_initial_credentials_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_initial_credentials_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_inventory_assets: {
        Row: {
          category: string | null
          condition: string
          created_at: string
          id: string
          location: string | null
          name: string
          quantity: number
          school_id: string
        }
        Insert: {
          category?: string | null
          condition?: string
          created_at?: string
          id?: string
          location?: string | null
          name: string
          quantity?: number
          school_id: string
        }
        Update: {
          category?: string | null
          condition?: string
          created_at?: string
          id?: string
          location?: string | null
          name?: string
          quantity?: number
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_inventory_assets_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_invoice_templates: {
        Row: {
          created_at: string
          created_by: string
          id: string
          invoice_scope: string
          is_default: boolean
          layout: Json
          name: string
          school_id: string
          source_format: string
          storage_path: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          invoice_scope?: string
          is_default?: boolean
          layout?: Json
          name: string
          school_id: string
          source_format?: string
          storage_path?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          invoice_scope?: string
          is_default?: boolean
          layout?: Json
          name?: string
          school_id?: string
          source_format?: string
          storage_path?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_invoice_templates_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_invoices: {
        Row: {
          amount_due: number
          amount_paid: number
          charge_category_id: string | null
          charge_type: string
          created_at: string
          created_by: string
          discount: number
          due_date: string | null
          fee_structure_id: string | null
          gross_amount: number
          id: string
          notes: string | null
          result_hold: boolean
          scholarship: number
          school_id: string
          session: string
          status: Database["public"]["Enums"]["schoolpro_invoice_status"]
          student_id: string
          term: string
          title: string
          updated_at: string
          waiver_amount: number
        }
        Insert: {
          amount_due: number
          amount_paid?: number
          charge_category_id?: string | null
          charge_type?: string
          created_at?: string
          created_by: string
          discount?: number
          due_date?: string | null
          fee_structure_id?: string | null
          gross_amount?: number
          id?: string
          notes?: string | null
          result_hold?: boolean
          scholarship?: number
          school_id: string
          session: string
          status?: Database["public"]["Enums"]["schoolpro_invoice_status"]
          student_id: string
          term: string
          title: string
          updated_at?: string
          waiver_amount?: number
        }
        Update: {
          amount_due?: number
          amount_paid?: number
          charge_category_id?: string | null
          charge_type?: string
          created_at?: string
          created_by?: string
          discount?: number
          due_date?: string | null
          fee_structure_id?: string | null
          gross_amount?: number
          id?: string
          notes?: string | null
          result_hold?: boolean
          scholarship?: number
          school_id?: string
          session?: string
          status?: Database["public"]["Enums"]["schoolpro_invoice_status"]
          student_id?: string
          term?: string
          title?: string
          updated_at?: string
          waiver_amount?: number
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_invoices_charge_category_id_fkey"
            columns: ["charge_category_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_charge_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_invoices_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_invoices_fee_structure_id_fkey"
            columns: ["fee_structure_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_fee_structures"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_invoices_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_invoices_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_leadership_settings: {
        Row: {
          owner_title: string
          school_id: string
        }
        Insert: {
          owner_title?: string
          school_id: string
        }
        Update: {
          owner_title?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_leadership_settings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_leave_requests: {
        Row: {
          created_at: string
          end_date: string
          id: string
          leave_type: string
          member_id: string | null
          reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          session: string | null
          start_date: string
          status: string
        }
        Insert: {
          created_at?: string
          end_date: string
          id?: string
          leave_type: string
          member_id?: string | null
          reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          session?: string | null
          start_date: string
          status?: string
        }
        Update: {
          created_at?: string
          end_date?: string
          id?: string
          leave_type?: string
          member_id?: string | null
          reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          session?: string | null
          start_date?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_leave_requests_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_leave_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_leave_requests_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_lesson_notes: {
        Row: {
          class_id: string | null
          content: string | null
          created_at: string
          created_by: string | null
          duration_minutes: number | null
          id: string
          lesson_date: string | null
          plan: Json
          review_comment: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          session: string | null
          status: string
          subject_id: string | null
          term: string | null
          title: string
          updated_at: string
          week: number | null
        }
        Insert: {
          class_id?: string | null
          content?: string | null
          created_at?: string
          created_by?: string | null
          duration_minutes?: number | null
          id?: string
          lesson_date?: string | null
          plan?: Json
          review_comment?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          session?: string | null
          status?: string
          subject_id?: string | null
          term?: string | null
          title: string
          updated_at?: string
          week?: number | null
        }
        Update: {
          class_id?: string | null
          content?: string | null
          created_at?: string
          created_by?: string | null
          duration_minutes?: number | null
          id?: string
          lesson_date?: string | null
          plan?: Json
          review_comment?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          session?: string | null
          status?: string
          subject_id?: string | null
          term?: string | null
          title?: string
          updated_at?: string
          week?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_lesson_notes_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_lesson_notes_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_lesson_notes_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_library_books: {
        Row: {
          author: string | null
          available_copies: number
          copies: number
          created_at: string
          id: string
          isbn: string | null
          school_id: string
          title: string
        }
        Insert: {
          author?: string | null
          available_copies?: number
          copies?: number
          created_at?: string
          id?: string
          isbn?: string | null
          school_id: string
          title: string
        }
        Update: {
          author?: string | null
          available_copies?: number
          copies?: number
          created_at?: string
          id?: string
          isbn?: string | null
          school_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_library_books_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_library_loans: {
        Row: {
          book_id: string
          borrowed_at: string
          due_at: string | null
          fine: number
          id: string
          member_id: string | null
          returned_at: string | null
          school_id: string
          session: string | null
          status: string
          student_id: string | null
          term: string | null
        }
        Insert: {
          book_id: string
          borrowed_at?: string
          due_at?: string | null
          fine?: number
          id?: string
          member_id?: string | null
          returned_at?: string | null
          school_id: string
          session?: string | null
          status?: string
          student_id?: string | null
          term?: string | null
        }
        Update: {
          book_id?: string
          borrowed_at?: string
          due_at?: string | null
          fine?: number
          id?: string
          member_id?: string | null
          returned_at?: string | null
          school_id?: string
          session?: string | null
          status?: string
          student_id?: string | null
          term?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_library_loans_book_id_fkey"
            columns: ["book_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_library_books"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_library_loans_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_library_loans_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_library_loans_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_login_attempts: {
        Row: {
          attempts: number
          key: string
          started_at: string
        }
        Insert: {
          attempts?: number
          key: string
          started_at?: string
        }
        Update: {
          attempts?: number
          key?: string
          started_at?: string
        }
        Relationships: []
      }
      schoolpro_member_permissions: {
        Row: {
          allowed: boolean
          id: string
          member_id: string
          permission: string
          school_id: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          allowed?: boolean
          id?: string
          member_id: string
          permission: string
          school_id: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          allowed?: boolean
          id?: string
          member_id?: string
          permission?: string
          school_id?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_member_permissions_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_member_permissions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_members: {
        Row: {
          created_at: string
          id: string
          position_title: string | null
          role: Database["public"]["Enums"]["school_member_role"]
          school_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          position_title?: string | null
          role: Database["public"]["Enums"]["school_member_role"]
          school_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          position_title?: string | null
          role?: Database["public"]["Enums"]["school_member_role"]
          school_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_members_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_module_records: {
        Row: {
          category: string | null
          created_at: string
          created_by: string | null
          details: string | null
          due_date: string | null
          id: string
          module: string
          school_id: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          created_by?: string | null
          details?: string | null
          due_date?: string | null
          id?: string
          module: string
          school_id: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          category?: string | null
          created_at?: string
          created_by?: string | null
          details?: string | null
          due_date?: string | null
          id?: string
          module?: string
          school_id?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_module_records_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_notifications: {
        Row: {
          created_at: string
          href: string | null
          id: string
          kind: string
          message: string
          read_at: string | null
          school_id: string | null
          title: string
          user_id: string
        }
        Insert: {
          created_at?: string
          href?: string | null
          id?: string
          kind?: string
          message: string
          read_at?: string | null
          school_id?: string | null
          title: string
          user_id: string
        }
        Update: {
          created_at?: string
          href?: string | null
          id?: string
          kind?: string
          message?: string
          read_at?: string | null
          school_id?: string | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_notifications_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_onboarding_requests: {
        Row: {
          branding: Json
          contact_name: string
          created_at: string
          email: string
          id: string
          modules: Json
          phone: string | null
          plan_key: string | null
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string | null
          school_name: string
          status: string
          student_count: number | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          branding?: Json
          contact_name: string
          created_at?: string
          email: string
          id?: string
          modules?: Json
          phone?: string | null
          plan_key?: string | null
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name: string
          status?: string
          student_count?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          branding?: Json
          contact_name?: string
          created_at?: string
          email?: string
          id?: string
          modules?: Json
          phone?: string | null
          plan_key?: string | null
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string | null
          school_name?: string
          status?: string
          student_count?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_onboarding_requests_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_onboarding_requests_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_onboarding_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_payment_allocations: {
        Row: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          payment_id: string | null
          school_id: string
          student_id: string
          submission_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          invoice_id: string
          payment_id?: string | null
          school_id: string
          student_id: string
          submission_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          invoice_id?: string
          payment_id?: string | null
          school_id?: string
          student_id?: string
          submission_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_payment_allocations_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_allocations_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_fee_payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_allocations_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_allocations_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_allocations_submission_id_fkey"
            columns: ["submission_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_payment_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_payment_intents: {
        Row: {
          amount: number
          checkout_url: string | null
          created_at: string
          credited_at: string | null
          currency: string
          gateway: string
          gateway_payload: Json
          gateway_transaction_id: string | null
          id: string
          invoice_id: string
          payer_user_id: string
          provider_reference: string | null
          reference: string
          school_id: string
          status: string
          student_id: string
          updated_at: string
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          checkout_url?: string | null
          created_at?: string
          credited_at?: string | null
          currency?: string
          gateway?: string
          gateway_payload?: Json
          gateway_transaction_id?: string | null
          id?: string
          invoice_id: string
          payer_user_id: string
          provider_reference?: string | null
          reference: string
          school_id: string
          status?: string
          student_id: string
          updated_at?: string
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          checkout_url?: string | null
          created_at?: string
          credited_at?: string | null
          currency?: string
          gateway?: string
          gateway_payload?: Json
          gateway_transaction_id?: string | null
          id?: string
          invoice_id?: string
          payer_user_id?: string
          provider_reference?: string | null
          reference?: string
          school_id?: string
          status?: string
          student_id?: string
          updated_at?: string
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_payment_intents_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_intents_payer_user_id_fkey"
            columns: ["payer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_intents_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_intents_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_payment_proofs: {
        Row: {
          amount: number
          bank_account_id: string | null
          bank_reference: string | null
          created_at: string
          id: string
          invoice_id: string
          payer_name: string | null
          payment_date: string
          payment_id: string | null
          receipt_mime: string | null
          receipt_path: string
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          status: string
          student_id: string
          submitted_by: string
          updated_at: string
        }
        Insert: {
          amount: number
          bank_account_id?: string | null
          bank_reference?: string | null
          created_at?: string
          id?: string
          invoice_id: string
          payer_name?: string | null
          payment_date: string
          payment_id?: string | null
          receipt_mime?: string | null
          receipt_path: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          status?: string
          student_id: string
          submitted_by: string
          updated_at?: string
        }
        Update: {
          amount?: number
          bank_account_id?: string | null
          bank_reference?: string | null
          created_at?: string
          id?: string
          invoice_id?: string
          payer_name?: string | null
          payment_date?: string
          payment_id?: string | null
          receipt_mime?: string | null
          receipt_path?: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          status?: string
          student_id?: string
          submitted_by?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_payment_proofs_bank_account_id_fkey"
            columns: ["bank_account_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_bank_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_proofs_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_proofs_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_fee_payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_proofs_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_proofs_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_payment_submissions: {
        Row: {
          bank_account_id: string | null
          bank_reference: string | null
          created_at: string
          id: string
          payer_name: string | null
          payment_date: string
          receipt_mime: string | null
          receipt_path: string
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          status: string
          submitted_by: string
          total_amount: number
          updated_at: string
        }
        Insert: {
          bank_account_id?: string | null
          bank_reference?: string | null
          created_at?: string
          id?: string
          payer_name?: string | null
          payment_date: string
          receipt_mime?: string | null
          receipt_path: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          status?: string
          submitted_by: string
          total_amount: number
          updated_at?: string
        }
        Update: {
          bank_account_id?: string | null
          bank_reference?: string | null
          created_at?: string
          id?: string
          payer_name?: string | null
          payment_date?: string
          receipt_mime?: string | null
          receipt_path?: string
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          status?: string
          submitted_by?: string
          total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_payment_submissions_bank_account_id_fkey"
            columns: ["bank_account_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_bank_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payment_submissions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_payroll_records: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          created_at: string
          deductions: number
          gross: number
          id: string
          member_id: string | null
          net: number | null
          paid_at: string | null
          payment_reference: string | null
          period: string
          school_id: string
          session: string | null
          status: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          deductions?: number
          gross?: number
          id?: string
          member_id?: string | null
          net?: number | null
          paid_at?: string | null
          payment_reference?: string | null
          period: string
          school_id: string
          session?: string | null
          status?: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          deductions?: number
          gross?: number
          id?: string
          member_id?: string | null
          net?: number | null
          paid_at?: string | null
          payment_reference?: string | null
          period?: string
          school_id?: string
          session?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_payroll_records_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payroll_records_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_payroll_records_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_plan_catalog: {
        Row: {
          display_name: string
          features: Json
          id: string
          is_active: boolean
          per_student_price: number
          term_price: number
          tier: string
          updated_at: string
        }
        Insert: {
          display_name: string
          features?: Json
          id?: string
          is_active?: boolean
          per_student_price?: number
          term_price?: number
          tier: string
          updated_at?: string
        }
        Update: {
          display_name?: string
          features?: Json
          id?: string
          is_active?: boolean
          per_student_price?: number
          term_price?: number
          tier?: string
          updated_at?: string
        }
        Relationships: []
      }
      schoolpro_portal_invites: {
        Row: {
          accepted_at: string | null
          created_at: string
          email: string
          expires_at: string
          id: string
          invite_type: string
          school_id: string
          status: string
          student_id: string | null
          token: string
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          email: string
          expires_at?: string
          id?: string
          invite_type: string
          school_id: string
          status?: string
          student_id?: string | null
          token?: string
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          email?: string
          expires_at?: string
          id?: string
          invite_type?: string
          school_id?: string
          status?: string
          student_id?: string | null
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_portal_invites_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_portal_invites_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_promotions: {
        Row: {
          applied_at: string | null
          applied_by: string | null
          created_at: string
          decided_by: string | null
          decision: string
          from_class: string | null
          from_class_id: string | null
          id: string
          reason: string | null
          school_id: string
          session: string
          status: string
          student_id: string
          to_class: string | null
          to_class_id: string | null
        }
        Insert: {
          applied_at?: string | null
          applied_by?: string | null
          created_at?: string
          decided_by?: string | null
          decision: string
          from_class?: string | null
          from_class_id?: string | null
          id?: string
          reason?: string | null
          school_id: string
          session: string
          status?: string
          student_id: string
          to_class?: string | null
          to_class_id?: string | null
        }
        Update: {
          applied_at?: string | null
          applied_by?: string | null
          created_at?: string
          decided_by?: string | null
          decision?: string
          from_class?: string | null
          from_class_id?: string | null
          id?: string
          reason?: string | null
          school_id?: string
          session?: string
          status?: string
          student_id?: string
          to_class?: string | null
          to_class_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_promotions_from_class_id_fkey"
            columns: ["from_class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_promotions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_promotions_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_promotions_to_class_id_fkey"
            columns: ["to_class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_question_bank: {
        Row: {
          class_id: string | null
          correct_answer: string | null
          created_at: string
          created_by: string | null
          explanation: string | null
          id: string
          marks: number
          options: Json
          question_text: string
          question_type: string
          school_id: string
          subject_id: string | null
        }
        Insert: {
          class_id?: string | null
          correct_answer?: string | null
          created_at?: string
          created_by?: string | null
          explanation?: string | null
          id?: string
          marks?: number
          options?: Json
          question_text: string
          question_type?: string
          school_id: string
          subject_id?: string | null
        }
        Update: {
          class_id?: string | null
          correct_answer?: string | null
          created_at?: string
          created_by?: string | null
          explanation?: string | null
          id?: string
          marks?: number
          options?: Json
          question_text?: string
          question_type?: string
          school_id?: string
          subject_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_question_bank_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_question_bank_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_question_bank_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_access_events: {
        Row: {
          allowed: boolean
          changed_by: string
          created_at: string
          id: string
          reason: string
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Insert: {
          allowed: boolean
          changed_by: string
          created_at?: string
          id?: string
          reason: string
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Update: {
          allowed?: boolean
          changed_by?: string
          created_at?: string
          id?: string
          reason?: string
          school_id?: string
          session?: string
          student_id?: string
          term?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_access_events_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_access_events_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_access_events_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_access_overrides: {
        Row: {
          allowed: boolean
          id: string
          reason: string
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at: string
          updated_by: string
        }
        Insert: {
          allowed: boolean
          id?: string
          reason: string
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at?: string
          updated_by: string
        }
        Update: {
          allowed?: boolean
          id?: string
          reason?: string
          school_id?: string
          session?: string
          student_id?: string
          term?: string
          updated_at?: string
          updated_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_access_overrides_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_access_overrides_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_access_overrides_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_access_pins: {
        Row: {
          created_at: string
          created_by: string | null
          expires_at: string | null
          id: string
          is_active: boolean
          last_used_at: string | null
          pin_hash: string
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          last_used_at?: string | null
          pin_hash: string
          school_id: string
          session: string
          student_id: string
          term: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          last_used_at?: string | null
          pin_hash?: string
          school_id?: string
          session?: string
          student_id?: string
          term?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_access_pins_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_access_pins_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_approvals: {
        Row: {
          id: string
          notes: string | null
          result_id: string
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          status: string
        }
        Insert: {
          id?: string
          notes?: string | null
          result_id: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          status?: string
        }
        Update: {
          id?: string
          notes?: string | null
          result_id?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_approvals_result_id_fkey"
            columns: ["result_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_results"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_approvals_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_correction_requests: {
        Row: {
          component_key: string | null
          created_at: string
          id: string
          proposed_score: number | null
          reason: string
          requested_by: string
          result_id: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          school_id: string
          status: string
        }
        Insert: {
          component_key?: string | null
          created_at?: string
          id?: string
          proposed_score?: number | null
          reason: string
          requested_by?: string
          result_id: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id: string
          status?: string
        }
        Update: {
          component_key?: string | null
          created_at?: string
          id?: string
          proposed_score?: number | null
          reason?: string
          requested_by?: string
          result_id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          school_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_correction_requests_result_id_fkey"
            columns: ["result_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_results"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_corrections: {
        Row: {
          id: string
          previous_snapshot: Json
          reason: string
          reopened_at: string
          reopened_by: string
          result_id: string
          school_id: string
        }
        Insert: {
          id?: string
          previous_snapshot: Json
          reason: string
          reopened_at?: string
          reopened_by: string
          result_id: string
          school_id: string
        }
        Update: {
          id?: string
          previous_snapshot?: Json
          reason?: string
          reopened_at?: string
          reopened_by?: string
          result_id?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_corrections_result_id_fkey"
            columns: ["result_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_results"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_corrections_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_domain_definitions: {
        Row: {
          created_at: string
          domain_type: string
          id: string
          is_active: boolean
          name: string
          position: number
          school_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          domain_type: string
          id?: string
          is_active?: boolean
          name: string
          position?: number
          school_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          domain_type?: string
          id?: string
          is_active?: boolean
          name?: string
          position?: number
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_domain_definitions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_domain_ratings: {
        Row: {
          created_at: string
          definition_id: string
          id: string
          rated_by: string | null
          rating: number
          rating_label: string | null
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          definition_id: string
          id?: string
          rated_by?: string | null
          rating: number
          rating_label?: string | null
          school_id: string
          session: string
          student_id: string
          term: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          definition_id?: string
          id?: string
          rated_by?: string | null
          rating?: number
          rating_label?: string | null
          school_id?: string
          session?: string
          student_id?: string
          term?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_domain_ratings_definition_id_fkey"
            columns: ["definition_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_result_domain_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_domain_ratings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_domain_ratings_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_events: {
        Row: {
          actor_id: string | null
          created_at: string
          event_type: string
          id: string
          result_id: string
          school_id: string
          snapshot: Json
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          event_type: string
          id?: string
          result_id: string
          school_id: string
          snapshot: Json
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          event_type?: string
          id?: string
          result_id?: string
          school_id?: string
          snapshot?: Json
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_events_result_id_fkey"
            columns: ["result_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_results"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_events_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_rating_scale: {
        Row: {
          created_at: string
          description: string
          id: string
          position: number
          rating: number
          school_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          position?: number
          rating: number
          school_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          position?: number
          rating?: number
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_rating_scale_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_templates: {
        Row: {
          columns: Json
          component_columns: Json
          created_at: string
          custom_fields: Json
          field_cells: Json
          id: string
          logo_cell: string
          logo_height: number
          logo_storage_path: string | null
          logo_width: number
          name: string
          photo_cell: string | null
          photo_height: number | null
          photo_width: number | null
          principal_signature_cell: string | null
          qr_cell: string | null
          qr_size: number | null
          school_id: string
          sheet_name: string
          signature_height: number | null
          signature_width: number | null
          start_row: number
          storage_path: string
          teacher_signature_cell: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          columns?: Json
          component_columns?: Json
          created_at?: string
          custom_fields?: Json
          field_cells?: Json
          id?: string
          logo_cell?: string
          logo_height?: number
          logo_storage_path?: string | null
          logo_width?: number
          name: string
          photo_cell?: string | null
          photo_height?: number | null
          photo_width?: number | null
          principal_signature_cell?: string | null
          qr_cell?: string | null
          qr_size?: number | null
          school_id: string
          sheet_name?: string
          signature_height?: number | null
          signature_width?: number | null
          start_row?: number
          storage_path: string
          teacher_signature_cell?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          columns?: Json
          component_columns?: Json
          created_at?: string
          custom_fields?: Json
          field_cells?: Json
          id?: string
          logo_cell?: string
          logo_height?: number
          logo_storage_path?: string | null
          logo_width?: number
          name?: string
          photo_cell?: string | null
          photo_height?: number | null
          photo_width?: number | null
          principal_signature_cell?: string | null
          qr_cell?: string | null
          qr_size?: number | null
          school_id?: string
          sheet_name?: string
          signature_height?: number | null
          signature_width?: number | null
          start_row?: number
          storage_path?: string
          teacher_signature_cell?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_templates_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_templates_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_term_settings: {
        Row: {
          class_days: number | null
          created_at: string
          form_master_remark_template: string | null
          form_teacher_signature_path: string | null
          id: string
          next_term_begins: string | null
          principal_name: string | null
          principal_remark_template: string | null
          principal_signature_path: string | null
          school_id: string
          session: string
          term: string
          term_end_date: string | null
          term_start_date: string | null
          updated_at: string
          updated_by: string | null
          verification_base_url: string | null
        }
        Insert: {
          class_days?: number | null
          created_at?: string
          form_master_remark_template?: string | null
          form_teacher_signature_path?: string | null
          id?: string
          next_term_begins?: string | null
          principal_name?: string | null
          principal_remark_template?: string | null
          principal_signature_path?: string | null
          school_id: string
          session: string
          term: string
          term_end_date?: string | null
          term_start_date?: string | null
          updated_at?: string
          updated_by?: string | null
          verification_base_url?: string | null
        }
        Update: {
          class_days?: number | null
          created_at?: string
          form_master_remark_template?: string | null
          form_teacher_signature_path?: string | null
          id?: string
          next_term_begins?: string | null
          principal_name?: string | null
          principal_remark_template?: string | null
          principal_signature_path?: string | null
          school_id?: string
          session?: string
          term?: string
          term_end_date?: string | null
          term_start_date?: string | null
          updated_at?: string
          updated_by?: string | null
          verification_base_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_term_settings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_result_verifications: {
        Row: {
          id: string
          issued_at: string
          issued_by: string | null
          revoked_at: string | null
          school_id: string
          session: string
          snapshot: Json
          status: string
          student_id: string
          term: string
          verification_code: string
        }
        Insert: {
          id?: string
          issued_at?: string
          issued_by?: string | null
          revoked_at?: string | null
          school_id: string
          session: string
          snapshot?: Json
          status?: string
          student_id: string
          term: string
          verification_code?: string
        }
        Update: {
          id?: string
          issued_at?: string
          issued_by?: string | null
          revoked_at?: string | null
          school_id?: string
          session?: string
          snapshot?: Json
          status?: string
          student_id?: string
          term?: string
          verification_code?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_result_verifications_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_result_verifications_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_results: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          assessment_scheme_id: string | null
          assessment_scores: Json
          ca_score: number
          created_at: string
          exam_score: number
          head_teacher_comment: string | null
          id: string
          locked: boolean
          published_at: string | null
          school_id: string
          session: string
          status: Database["public"]["Enums"]["schoolpro_result_status"]
          student_id: string
          subject_id: string
          teacher_comment: string | null
          term: string
          total_score: number | null
          updated_at: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          assessment_scheme_id?: string | null
          assessment_scores?: Json
          ca_score?: number
          created_at?: string
          exam_score?: number
          head_teacher_comment?: string | null
          id?: string
          locked?: boolean
          published_at?: string | null
          school_id: string
          session: string
          status?: Database["public"]["Enums"]["schoolpro_result_status"]
          student_id: string
          subject_id: string
          teacher_comment?: string | null
          term: string
          total_score?: number | null
          updated_at?: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          assessment_scheme_id?: string | null
          assessment_scores?: Json
          ca_score?: number
          created_at?: string
          exam_score?: number
          head_teacher_comment?: string | null
          id?: string
          locked?: boolean
          published_at?: string | null
          school_id?: string
          session?: string
          status?: Database["public"]["Enums"]["schoolpro_result_status"]
          student_id?: string
          subject_id?: string
          teacher_comment?: string | null
          term?: string
          total_score?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_results_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_results_assessment_scheme_id_fkey"
            columns: ["assessment_scheme_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_assessment_schemes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_results_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_results_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_results_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_schools: {
        Row: {
          address: string | null
          code: string
          created_at: string
          id: string
          name: string
          owner_id: string
          plan: string
          status: Database["public"]["Enums"]["school_status"]
          updated_at: string
        }
        Insert: {
          address?: string | null
          code: string
          created_at?: string
          id?: string
          name: string
          owner_id: string
          plan?: string
          status?: Database["public"]["Enums"]["school_status"]
          updated_at?: string
        }
        Update: {
          address?: string | null
          code?: string
          created_at?: string
          id?: string
          name?: string
          owner_id?: string
          plan?: string
          status?: Database["public"]["Enums"]["school_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_schools_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_site_content: {
        Row: {
          body: string | null
          id: string
          image_url: string | null
          is_published: boolean
          metadata: Json
          page_key: string
          school_id: string
          section_key: string
          sort_order: number
          title: string | null
          updated_at: string
        }
        Insert: {
          body?: string | null
          id?: string
          image_url?: string | null
          is_published?: boolean
          metadata?: Json
          page_key: string
          school_id: string
          section_key: string
          sort_order?: number
          title?: string | null
          updated_at?: string
        }
        Update: {
          body?: string | null
          id?: string
          image_url?: string | null
          is_published?: boolean
          metadata?: Json
          page_key?: string
          school_id?: string
          section_key?: string
          sort_order?: number
          title?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_site_content_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_site_gallery: {
        Row: {
          caption: string | null
          created_at: string
          id: string
          image_url: string
          is_published: boolean
          school_id: string
          title: string | null
        }
        Insert: {
          caption?: string | null
          created_at?: string
          id?: string
          image_url: string
          is_published?: boolean
          school_id: string
          title?: string | null
        }
        Update: {
          caption?: string | null
          created_at?: string
          id?: string
          image_url?: string
          is_published?: boolean
          school_id?: string
          title?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_site_gallery_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_site_news: {
        Row: {
          body: string | null
          cover_image_url: string | null
          created_at: string
          excerpt: string | null
          id: string
          is_published: boolean
          published_at: string | null
          school_id: string
          slug: string
          title: string
        }
        Insert: {
          body?: string | null
          cover_image_url?: string | null
          created_at?: string
          excerpt?: string | null
          id?: string
          is_published?: boolean
          published_at?: string | null
          school_id: string
          slug: string
          title: string
        }
        Update: {
          body?: string | null
          cover_image_url?: string | null
          created_at?: string
          excerpt?: string | null
          id?: string
          is_published?: boolean
          published_at?: string | null
          school_id?: string
          slug?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_site_news_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_site_settings: {
        Row: {
          address: string | null
          admissions_open: boolean
          custom_domain: string | null
          hero_text: string | null
          hero_title: string | null
          is_published: boolean
          logo_url: string | null
          motto: string | null
          phone: string | null
          portal_enabled: boolean
          primary_color: string | null
          result_checker_enabled: boolean
          school_email: string | null
          school_id: string
          secondary_color: string | null
          site_slug: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          admissions_open?: boolean
          custom_domain?: string | null
          hero_text?: string | null
          hero_title?: string | null
          is_published?: boolean
          logo_url?: string | null
          motto?: string | null
          phone?: string | null
          portal_enabled?: boolean
          primary_color?: string | null
          result_checker_enabled?: boolean
          school_email?: string | null
          school_id: string
          secondary_color?: string | null
          site_slug?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          admissions_open?: boolean
          custom_domain?: string | null
          hero_text?: string | null
          hero_title?: string | null
          is_published?: boolean
          logo_url?: string | null
          motto?: string | null
          phone?: string | null
          portal_enabled?: boolean
          primary_color?: string | null
          result_checker_enabled?: boolean
          school_email?: string | null
          school_id?: string
          secondary_color?: string | null
          site_slug?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_site_settings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_student_activation_challenges: {
        Row: {
          expires_at: string
          student_id: string
          token_hash: string
        }
        Insert: {
          expires_at?: string
          student_id: string
          token_hash: string
        }
        Update: {
          expires_at?: string
          student_id?: string
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_student_activation_challenges_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_student_transport: {
        Row: {
          active: boolean
          id: string
          pickup_point: string | null
          route_id: string
          school_id: string
          session: string | null
          student_id: string
          term: string | null
        }
        Insert: {
          active?: boolean
          id?: string
          pickup_point?: string | null
          route_id: string
          school_id: string
          session?: string | null
          student_id: string
          term?: string | null
        }
        Update: {
          active?: boolean
          id?: string
          pickup_point?: string | null
          route_id?: string
          school_id?: string
          session?: string | null
          student_id?: string
          term?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_student_transport_route_id_fkey"
            columns: ["route_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_transport_routes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_student_transport_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_student_transport_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_students: {
        Row: {
          admission_number: string
          admission_type: string
          class_id: string | null
          class_name: string
          created_at: string
          date_of_birth: string | null
          enrollment_session: string | null
          first_name: string
          gender: string | null
          guardian_email: string | null
          guardian_name: string | null
          guardian_phone: string | null
          id: string
          last_name: string
          photo_storage_path: string | null
          previous_school: string | null
          school_id: string
          status: string
          transfer_destination: string | null
          transfer_reason: string | null
          transferred_out_at: string | null
          user_id: string | null
        }
        Insert: {
          admission_number: string
          admission_type?: string
          class_id?: string | null
          class_name: string
          created_at?: string
          date_of_birth?: string | null
          enrollment_session?: string | null
          first_name: string
          gender?: string | null
          guardian_email?: string | null
          guardian_name?: string | null
          guardian_phone?: string | null
          id?: string
          last_name: string
          photo_storage_path?: string | null
          previous_school?: string | null
          school_id: string
          status?: string
          transfer_destination?: string | null
          transfer_reason?: string | null
          transferred_out_at?: string | null
          user_id?: string | null
        }
        Update: {
          admission_number?: string
          admission_type?: string
          class_id?: string | null
          class_name?: string
          created_at?: string
          date_of_birth?: string | null
          enrollment_session?: string | null
          first_name?: string
          gender?: string | null
          guardian_email?: string | null
          guardian_name?: string | null
          guardian_phone?: string | null
          id?: string
          last_name?: string
          photo_storage_path?: string | null
          previous_school?: string | null
          school_id?: string
          status?: string
          transfer_destination?: string | null
          transfer_reason?: string | null
          transferred_out_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_students_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_students_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_subject_assignments: {
        Row: {
          class_id: string
          created_at: string
          id: string
          school_id: string
          session: string
          subject_id: string
          teacher_member_id: string | null
          updated_at: string
        }
        Insert: {
          class_id: string
          created_at?: string
          id?: string
          school_id: string
          session: string
          subject_id: string
          teacher_member_id?: string | null
          updated_at?: string
        }
        Update: {
          class_id?: string
          created_at?: string
          id?: string
          school_id?: string
          session?: string
          subject_id?: string
          teacher_member_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_subject_assignments_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subject_assignments_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subject_assignments_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subject_assignments_teacher_member_id_fkey"
            columns: ["teacher_member_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_members"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_subjects: {
        Row: {
          class_name: string
          code: string
          created_at: string
          id: string
          name: string
          school_id: string
        }
        Insert: {
          class_name: string
          code: string
          created_at?: string
          id?: string
          name: string
          school_id: string
        }
        Update: {
          class_name?: string
          code?: string
          created_at?: string
          id?: string
          name?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_subjects_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_subscription_catalog: {
        Row: {
          active: boolean
          annual_price: number | null
          code: string
          features: Json
          id: string
          monthly_price: number | null
          name: string
          termly_price: number | null
          updated_at: string
        }
        Insert: {
          active?: boolean
          annual_price?: number | null
          code: string
          features?: Json
          id?: string
          monthly_price?: number | null
          name: string
          termly_price?: number | null
          updated_at?: string
        }
        Update: {
          active?: boolean
          annual_price?: number | null
          code?: string
          features?: Json
          id?: string
          monthly_price?: number | null
          name?: string
          termly_price?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      schoolpro_subscription_intents: {
        Row: {
          amount: number
          billing_cycle: string
          catalog_id: string
          created_at: string
          demo_request_id: string | null
          id: string
          invoice_kind: string
          paid_at: string | null
          payer_user_id: string
          payment_method: string
          reference: string
          replaces_invoice_id: string | null
          school_id: string
          status: string
          transaction_ref: string | null
          updated_at: string
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          billing_cycle: string
          catalog_id: string
          created_at?: string
          demo_request_id?: string | null
          id?: string
          invoice_kind?: string
          paid_at?: string | null
          payer_user_id: string
          payment_method?: string
          reference: string
          replaces_invoice_id?: string | null
          school_id: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          billing_cycle?: string
          catalog_id?: string
          created_at?: string
          demo_request_id?: string | null
          id?: string
          invoice_kind?: string
          paid_at?: string | null
          payer_user_id?: string
          payment_method?: string
          reference?: string
          replaces_invoice_id?: string | null
          school_id?: string
          status?: string
          transaction_ref?: string | null
          updated_at?: string
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_subscription_intents_catalog_id_fkey"
            columns: ["catalog_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subscription_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_intents_demo_request_id_fkey"
            columns: ["demo_request_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_demo_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_intents_replaces_invoice_id_fkey"
            columns: ["replaces_invoice_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_subscription_intents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_intents_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_intents_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_subscription_payments: {
        Row: {
          amount: number
          created_at: string
          credited_at: string | null
          id: string
          payer_user_id: string
          provider: string
          provider_payload: Json
          reference: string
          school_id: string
          status: string
          subscription_id: string | null
          transaction_ref: string | null
          updated_at: string
          verified_at: string | null
          virtual_account_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          credited_at?: string | null
          id?: string
          payer_user_id: string
          provider?: string
          provider_payload?: Json
          reference: string
          school_id: string
          status?: string
          subscription_id?: string | null
          transaction_ref?: string | null
          updated_at?: string
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          credited_at?: string | null
          id?: string
          payer_user_id?: string
          provider?: string
          provider_payload?: Json
          reference?: string
          school_id?: string
          status?: string
          subscription_id?: string | null
          transaction_ref?: string | null
          updated_at?: string
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_subscription_payments_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_payments_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subscriptions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_subscription_payments_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_subscription_plans: {
        Row: {
          active: boolean
          billing_period: string
          code: string
          created_at: string
          features: Json
          name: string
          price: number
          updated_at: string
        }
        Insert: {
          active?: boolean
          billing_period: string
          code: string
          created_at?: string
          features?: Json
          name: string
          price: number
          updated_at?: string
        }
        Update: {
          active?: boolean
          billing_period?: string
          code?: string
          created_at?: string
          features?: Json
          name?: string
          price?: number
          updated_at?: string
        }
        Relationships: []
      }
      schoolpro_subscriptions: {
        Row: {
          amount: number
          billing_cycle: string
          customization_level: string
          id: string
          managed_by_ihlink: boolean
          renews_at: string | null
          school_id: string
          starts_at: string
          status: string
          tier: string
          updated_at: string
        }
        Insert: {
          amount?: number
          billing_cycle?: string
          customization_level?: string
          id?: string
          managed_by_ihlink?: boolean
          renews_at?: string | null
          school_id: string
          starts_at?: string
          status?: string
          tier?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          billing_cycle?: string
          customization_level?: string
          id?: string
          managed_by_ihlink?: boolean
          renews_at?: string | null
          school_id?: string
          starts_at?: string
          status?: string
          tier?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_subscriptions_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_timetable_entries: {
        Row: {
          class_id: string | null
          created_at: string
          created_by: string | null
          ends_at: string
          id: string
          room: string | null
          school_id: string
          session: string | null
          starts_at: string
          subject_id: string | null
          weekday: number
        }
        Insert: {
          class_id?: string | null
          created_at?: string
          created_by?: string | null
          ends_at: string
          id?: string
          room?: string | null
          school_id: string
          session?: string | null
          starts_at: string
          subject_id?: string | null
          weekday: number
        }
        Update: {
          class_id?: string | null
          created_at?: string
          created_by?: string | null
          ends_at?: string
          id?: string
          room?: string | null
          school_id?: string
          session?: string | null
          starts_at?: string
          subject_id?: string | null
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_timetable_entries_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_timetable_entries_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_timetable_entries_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_transcript_issues: {
        Row: {
          id: string
          issued_at: string
          issued_by: string
          revoked_at: string | null
          revoked_by: string | null
          school_id: string
          serial_number: string
          snapshot: Json
          student_id: string
        }
        Insert: {
          id?: string
          issued_at?: string
          issued_by: string
          revoked_at?: string | null
          revoked_by?: string | null
          school_id: string
          serial_number: string
          snapshot: Json
          student_id: string
        }
        Update: {
          id?: string
          issued_at?: string
          issued_by?: string
          revoked_at?: string | null
          revoked_by?: string | null
          school_id?: string
          serial_number?: string
          snapshot?: Json
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_transcript_issues_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schoolpro_transcript_issues_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_students"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_transcript_settings: {
        Row: {
          officers: Json
          school_id: string
          updated_at: string
        }
        Insert: {
          officers?: Json
          school_id: string
          updated_at?: string
        }
        Update: {
          officers?: Json
          school_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_transcript_settings_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: true
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schoolpro_transport_routes: {
        Row: {
          active: boolean
          created_at: string
          driver_name: string | null
          driver_phone: string | null
          fee: number
          id: string
          name: string
          school_id: string
          vehicle: string | null
        }
        Insert: {
          active?: boolean
          created_at?: string
          driver_name?: string | null
          driver_phone?: string | null
          fee?: number
          id?: string
          name: string
          school_id: string
          vehicle?: string | null
        }
        Update: {
          active?: boolean
          created_at?: string
          driver_name?: string | null
          driver_phone?: string | null
          fee?: number
          id?: string
          name?: string
          school_id?: string
          vehicle?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "schoolpro_transport_routes_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schoolpro_schools"
            referencedColumns: ["id"]
          },
        ]
      }
      security_controls: {
        Row: {
          category: string
          control_key: string
          created_at: string
          dashboard_url: string | null
          description: string
          guidance: string | null
          id: string
          status: string
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          category: string
          control_key: string
          created_at?: string
          dashboard_url?: string | null
          description: string
          guidance?: string | null
          id?: string
          status?: string
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          category?: string
          control_key?: string
          created_at?: string
          dashboard_url?: string | null
          description?: string
          guidance?: string | null
          id?: string
          status?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      security_events: {
        Row: {
          actor_id: string | null
          created_at: string
          description: string | null
          event_number: string
          event_type: string
          id: string
          ip_address: unknown
          metadata: Json
          product: string
          reviewed_at: string | null
          reviewed_by: string | null
          severity: string
          source: string
          status: string
          target_user_id: string | null
          title: string
          updated_at: string
          user_agent: string | null
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          description?: string | null
          event_number?: string
          event_type: string
          id?: string
          ip_address?: unknown
          metadata?: Json
          product?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          severity?: string
          source?: string
          status?: string
          target_user_id?: string | null
          title: string
          updated_at?: string
          user_agent?: string | null
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          description?: string | null
          event_number?: string
          event_type?: string
          id?: string
          ip_address?: unknown
          metadata?: Json
          product?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          severity?: string
          source?: string
          status?: string
          target_user_id?: string | null
          title?: string
          updated_at?: string
          user_agent?: string | null
        }
        Relationships: []
      }
      security_incidents: {
        Row: {
          assigned_to: string | null
          created_at: string
          created_by: string
          event_id: string | null
          id: string
          incident_number: string
          product: string
          resolution: string | null
          resolved_at: string | null
          severity: string
          status: string
          summary: string
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          created_at?: string
          created_by: string
          event_id?: string | null
          id?: string
          incident_number?: string
          product?: string
          resolution?: string | null
          resolved_at?: string | null
          severity?: string
          status?: string
          summary: string
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          created_at?: string
          created_by?: string
          event_id?: string | null
          id?: string
          incident_number?: string
          product?: string
          resolution?: string | null
          resolved_at?: string | null
          severity?: string
          status?: string
          summary?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "security_incidents_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "security_events"
            referencedColumns: ["id"]
          },
        ]
      }
      service_catalog: {
        Row: {
          base_price: number | null
          business_unit_id: string
          code: string
          created_at: string
          currency: string
          description: string | null
          id: string
          name: string
          pricing_unit: string | null
          source_id: string | null
          source_table: string | null
          status: string
          updated_at: string
        }
        Insert: {
          base_price?: number | null
          business_unit_id: string
          code: string
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          name: string
          pricing_unit?: string | null
          source_id?: string | null
          source_table?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          base_price?: number | null
          business_unit_id?: string
          code?: string
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          name?: string
          pricing_unit?: string | null
          source_id?: string | null
          source_table?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_catalog_business_unit_id_fkey"
            columns: ["business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
        ]
      }
      service_invoice_changes: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          invoice_id: string
          new_amount: number
          new_description: string
          new_service_name: string
          original_status: string
          platform_code: string
          reason: string
          responded_at: string | null
          status: string
          user_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          invoice_id: string
          new_amount: number
          new_description: string
          new_service_name: string
          original_status: string
          platform_code: string
          reason: string
          responded_at?: string | null
          status?: string
          user_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          invoice_id?: string
          new_amount?: number
          new_description?: string
          new_service_name?: string
          original_status?: string
          platform_code?: string
          reason?: string
          responded_at?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_invoice_changes_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "service_invoice_changes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      site_content_blocks: {
        Row: {
          background_image_url: string | null
          body: string | null
          content_settings: Json
          created_at: string
          created_by: string | null
          cta_label: string | null
          cta_link: string | null
          eyebrow: string | null
          id: string
          image_url: string | null
          is_visible: boolean
          layout: string
          page_key: string
          page_path: string
          secondary_cta_label: string | null
          secondary_cta_link: string | null
          section_key: string
          sort_order: number
          subtitle: string | null
          theme: string
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          background_image_url?: string | null
          body?: string | null
          content_settings?: Json
          created_at?: string
          created_by?: string | null
          cta_label?: string | null
          cta_link?: string | null
          eyebrow?: string | null
          id?: string
          image_url?: string | null
          is_visible?: boolean
          layout?: string
          page_key: string
          page_path?: string
          secondary_cta_label?: string | null
          secondary_cta_link?: string | null
          section_key: string
          sort_order?: number
          subtitle?: string | null
          theme?: string
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          background_image_url?: string | null
          body?: string | null
          content_settings?: Json
          created_at?: string
          created_by?: string | null
          cta_label?: string | null
          cta_link?: string | null
          eyebrow?: string | null
          id?: string
          image_url?: string | null
          is_visible?: boolean
          layout?: string
          page_key?: string
          page_path?: string
          secondary_cta_label?: string | null
          secondary_cta_link?: string | null
          section_key?: string
          sort_order?: number
          subtitle?: string | null
          theme?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "site_content_blocks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "site_content_blocks_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      site_navigation_items: {
        Row: {
          created_at: string
          created_by: string | null
          href: string
          id: string
          is_visible: boolean
          label: string
          location: string
          open_new_tab: boolean
          parent_id: string | null
          platform_key: string
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          href: string
          id?: string
          is_visible?: boolean
          label: string
          location?: string
          open_new_tab?: boolean
          parent_id?: string | null
          platform_key: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          href?: string
          id?: string
          is_visible?: boolean
          label?: string
          location?: string
          open_new_tab?: boolean
          parent_id?: string | null
          platform_key?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "site_navigation_items_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "site_navigation_items"
            referencedColumns: ["id"]
          },
        ]
      }
      site_section_templates: {
        Row: {
          category: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name: string
          platform_key: string | null
          section_payload: Json
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          category?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name: string
          platform_key?: string | null
          section_payload?: Json
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          category?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name?: string
          platform_key?: string | null
          section_payload?: Json
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      suppliers: {
        Row: {
          address: string | null
          contact_name: string | null
          created_at: string
          email: string | null
          id: string
          name: string
          phone: string | null
          status: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          contact_name?: string | null
          created_at?: string
          email?: string | null
          id?: string
          name: string
          phone?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          contact_name?: string | null
          created_at?: string
          email?: string | null
          id?: string
          name?: string
          phone?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      support_ticket_messages: {
        Row: {
          created_at: string
          id: string
          is_internal: boolean
          message: string
          sender_id: string
          ticket_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_internal?: boolean
          message: string
          sender_id: string
          ticket_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_internal?: boolean
          message?: string
          sender_id?: string
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_ticket_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          assigned_to: string | null
          category: string
          created_at: string
          id: string
          message: string
          priority: string
          product: string
          resolution: string | null
          resolved_at: string | null
          status: string
          subject: string
          ticket_number: string
          updated_at: string
          user_id: string
        }
        Insert: {
          assigned_to?: string | null
          category?: string
          created_at?: string
          id?: string
          message: string
          priority?: string
          product: string
          resolution?: string | null
          resolved_at?: string | null
          status?: string
          subject: string
          ticket_number?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          assigned_to?: string | null
          category?: string
          created_at?: string
          id?: string
          message?: string
          priority?: string
          product?: string
          resolution?: string | null
          resolved_at?: string | null
          status?: string
          subject?: string
          ticket_number?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      virtual_accounts: {
        Row: {
          account_name: string | null
          account_number: string | null
          bank_id: string | null
          bank_name: string | null
          created_at: string
          id: string
          is_customer_visible: boolean
          merchant_reference: string
          platform_code: string | null
          provider: string
          provider_reference: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_name?: string | null
          account_number?: string | null
          bank_id?: string | null
          bank_name?: string | null
          created_at?: string
          id?: string
          is_customer_visible?: boolean
          merchant_reference: string
          platform_code?: string | null
          provider: string
          provider_reference?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_name?: string | null
          account_number?: string | null
          bank_id?: string | null
          bank_name?: string | null
          created_at?: string
          id?: string
          is_customer_visible?: boolean
          merchant_reference?: string
          platform_code?: string | null
          provider?: string
          provider_reference?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      wallet_ledger: {
        Row: {
          amount: number
          balance_after: number | null
          balance_before: number | null
          created_at: string
          description: string | null
          direction: string | null
          entry_type: string
          external_reference: string | null
          id: string
          internal_reference: string | null
          metadata: Json
          platform_code: string
          provider: string | null
          reference: string
          transaction_id: string | null
          transaction_type: string | null
          user_id: string
        }
        Insert: {
          amount: number
          balance_after?: number | null
          balance_before?: number | null
          created_at?: string
          description?: string | null
          direction?: string | null
          entry_type: string
          external_reference?: string | null
          id?: string
          internal_reference?: string | null
          metadata?: Json
          platform_code?: string
          provider?: string | null
          reference: string
          transaction_id?: string | null
          transaction_type?: string | null
          user_id: string
        }
        Update: {
          amount?: number
          balance_after?: number | null
          balance_before?: number | null
          created_at?: string
          description?: string | null
          direction?: string | null
          entry_type?: string
          external_reference?: string | null
          id?: string
          internal_reference?: string | null
          metadata?: Json
          platform_code?: string
          provider?: string | null
          reference?: string
          transaction_id?: string | null
          transaction_type?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "wallet_ledger_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "datasub_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      webhook_events: {
        Row: {
          error_message: string | null
          event_reference: string | null
          event_type: string | null
          id: string
          payload: Json
          processed_at: string | null
          provider: string
          received_at: string
          signature_valid: boolean
          status: string
          transaction_ref: string | null
        }
        Insert: {
          error_message?: string | null
          event_reference?: string | null
          event_type?: string | null
          id?: string
          payload?: Json
          processed_at?: string | null
          provider: string
          received_at?: string
          signature_valid?: boolean
          status?: string
          transaction_ref?: string | null
        }
        Update: {
          error_message?: string | null
          event_reference?: string | null
          event_type?: string | null
          id?: string
          payload?: Json
          processed_at?: string | null
          provider?: string
          received_at?: string
          signature_valid?: boolean
          status?: string
          transaction_ref?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      customer_payment_transactions: {
        Row: {
          account_name: string | null
          amount: number | null
          bank: string | null
          created_at: string | null
          credited_at: string | null
          currency: string | null
          id: string | null
          is_settled: boolean | null
          method: string | null
          nuban: string | null
          platform_code: string | null
          provider: string | null
          provider_reference: string | null
          session_id: string | null
          status: string | null
          transaction_ref: string | null
          updated_at: string | null
          user_id: string | null
          verified_at: string | null
          virtual_account_id: string | null
        }
        Insert: {
          account_name?: string | null
          amount?: never
          bank?: string | null
          created_at?: string | null
          credited_at?: string | null
          currency?: string | null
          id?: string | null
          is_settled?: boolean | null
          method?: string | null
          nuban?: string | null
          platform_code?: string | null
          provider?: string | null
          provider_reference?: string | null
          session_id?: string | null
          status?: string | null
          transaction_ref?: string | null
          updated_at?: string | null
          user_id?: string | null
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Update: {
          account_name?: string | null
          amount?: never
          bank?: string | null
          created_at?: string | null
          credited_at?: string | null
          currency?: string | null
          id?: string | null
          is_settled?: boolean | null
          method?: string | null
          nuban?: string | null
          platform_code?: string | null
          provider?: string | null
          provider_reference?: string | null
          session_id?: string | null
          status?: string | null
          transaction_ref?: string | null
          updated_at?: string | null
          user_id?: string | null
          verified_at?: string | null
          virtual_account_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_transactions_virtual_account_id_fkey"
            columns: ["virtual_account_id"]
            isOneToOne: false
            referencedRelation: "virtual_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      datasub_admin_catalogue: {
        Row: {
          api_price: number | null
          base_provider_cost: number | null
          created_at: string | null
          customer_enabled: boolean | null
          id: string | null
          ihlink_plan_id: string | null
          markup_policy: Json | null
          name: string | null
          network: string | null
          plan_type: string | null
          provider_available: boolean | null
          reseller_price: number | null
          route_count: number | null
          service_type: string | null
          smart_earner_price: number | null
          spec_key: string | null
          top_seller_price: number | null
          updated_at: string | null
          validity: string | null
        }
        Relationships: []
      }
      datasub_customer_catalogue: {
        Row: {
          api_price: number | null
          base_provider_cost: number | null
          customer_enabled: boolean | null
          id: string | null
          ihlink_plan_id: string | null
          name: string | null
          network: string | null
          plan_type: string | null
          provider_available: boolean | null
          reseller_price: number | null
          route_count: number | null
          service_type: string | null
          smart_earner_price: number | null
          top_seller_price: number | null
          validity: string | null
        }
        Relationships: []
      }
      ihlink_direct_transfer_submissions: {
        Row: {
          admin_note: string | null
          amount: number | null
          bank_account_id: string | null
          created_at: string | null
          customer_reference: string | null
          id: string | null
          invoice_id: string | null
          platform: string | null
          proof_storage_path: string | null
          reviewed_at: string | null
          sender_bank: string | null
          sender_name: string | null
          source_reference: string | null
          status: string | null
          transferred_at: string | null
          updated_at: string | null
          user_id: string | null
          verified_by: string | null
        }
        Insert: {
          admin_note?: string | null
          amount?: number | null
          bank_account_id?: string | null
          created_at?: string | null
          customer_reference?: string | null
          id?: string | null
          invoice_id?: string | null
          platform?: string | null
          proof_storage_path?: string | null
          reviewed_at?: string | null
          sender_bank?: string | null
          sender_name?: string | null
          source_reference?: string | null
          status?: string | null
          transferred_at?: string | null
          updated_at?: string | null
          user_id?: string | null
          verified_by?: string | null
        }
        Update: {
          admin_note?: string | null
          amount?: number | null
          bank_account_id?: string | null
          created_at?: string | null
          customer_reference?: string | null
          id?: string | null
          invoice_id?: string | null
          platform?: string | null
          proof_storage_path?: string | null
          reviewed_at?: string | null
          sender_bank?: string | null
          sender_name?: string | null
          source_reference?: string | null
          status?: string | null
          transferred_at?: string | null
          updated_at?: string | null
          user_id?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "direct_transfer_submissions_bank_account_id_fkey"
            columns: ["bank_account_id"]
            isOneToOne: false
            referencedRelation: "ihlink_bank_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      wallets: {
        Row: {
          balance: number | null
          currency: string | null
          referral_balance: number | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          balance?: number | null
          currency?: string | null
          referral_balance?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          balance?: number | null
          currency?: string | null
          referral_balance?: number | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "datasub_wallets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      accept_schoolpro_admission_offer: {
        Args: {
          p_email: string
          p_name: string
          p_notes?: string
          p_token: string
        }
        Returns: Json
      }
      activate_schoolpro_demo:
        | { Args: { p_request: string; p_school: string }; Returns: Json }
        | {
            Args: {
              p_days: number
              p_reason: string
              p_school: string
              p_tier: string
            }
            Returns: Json
          }
      adjust_schoolpro_inventory: {
        Args: {
          p_asset: string
          p_condition?: string
          p_delta: number
          p_location?: string
        }
        Returns: number
      }
      admin_delete_school_communication: {
        Args: { p_expected: Json; p_id: string; p_table: string }
        Returns: string
      }
      admin_edit_operational_record: {
        Args: {
          p_changes: Json
          p_expected: Json
          p_id: string
          p_table: string
        }
        Returns: Json
      }
      admin_request_customer_deletion: {
        Args: { p_reason?: string; p_user: string }
        Returns: {
          anonymised: boolean
          approved_at: string | null
          cancelled_at: string | null
          completed_at: string | null
          finalised_by: string | null
          id: string
          reason: string | null
          requested_at: string
          resolution_note: string | null
          resolved_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "account_deletion_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_set_linked_service_price: {
        Args: { p_expected: number; p_id: string; p_price: number }
        Returns: string
      }
      admit_schoolpro_applicant: {
        Args: { p_application: string }
        Returns: string
      }
      allocate_schoolpro_hostel: {
        Args: { p_room: string; p_session: string; p_student: string }
        Returns: string
      }
      apply_academy_course: { Args: { target_course: string }; Returns: string }
      apply_schoolpro_promotion: {
        Args: { p_promotion: string }
        Returns: undefined
      }
      approve_datasub_referral_reward: {
        Args: { p_reason: string; p_referred: string; p_transaction: string }
        Returns: Json
      }
      approve_host_domain_for_payment: {
        Args: { p_order: string }
        Returns: Json
      }
      assign_schoolpro_entrance_cbt: {
        Args: { p_application: string; p_test: string }
        Returns: Json
      }
      assign_schoolpro_transport:
        | {
            Args: { p_pickup: string; p_route: string; p_student: string }
            Returns: string
          }
        | {
            Args: {
              p_pickup: string
              p_route: string
              p_session: string
              p_student: string
            }
            Returns: string
          }
      borrow_schoolpro_library_book:
        | {
            Args: {
              p_book: string
              p_due?: string
              p_member?: string
              p_student?: string
            }
            Returns: string
          }
        | {
            Args: {
              p_book: string
              p_due: string
              p_member: string
              p_session: string
              p_student: string
            }
            Returns: string
          }
      cancel_account_deletion: {
        Args: never
        Returns: {
          anonymised: boolean
          approved_at: string | null
          cancelled_at: string | null
          completed_at: string | null
          finalised_by: string | null
          id: string
          reason: string | null
          requested_at: string
          resolution_note: string | null
          resolved_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "account_deletion_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      check_schoolpro_result_pin: {
        Args: {
          p_admission: string
          p_pin: string
          p_session: string
          p_term: string
        }
        Returns: Json
      }
      claim_datasub_api_callbacks: { Args: never; Returns: Json }
      claim_datasub_pin_recovery: { Args: { p_user: string }; Returns: boolean }
      claim_ihlink_emails: { Args: { p_school_id?: string }; Returns: Json }
      claim_schoolpro_onboarding: { Args: never; Returns: number }
      complete_account_deletion_records: {
        Args: { p_actor: string; p_request: string }
        Returns: Json
      }
      complete_host_provisioning: {
        Args: {
          p_control_panel_url?: string
          p_nameservers?: Json
          p_order: string
          p_provider_reference: string
        }
        Returns: Json
      }
      configure_datasub_api_webhook: { Args: { p_url: string }; Returns: Json }
      configure_datasub_referrals: {
        Args: {
          p_enabled: boolean
          p_minimum: number
          p_reason: string
          p_reward: number
        }
        Returns: undefined
      }
      consult_is_staff: { Args: never; Returns: boolean }
      consume_datasub_api_request: {
        Args: { p_user_id: string }
        Returns: boolean
      }
      control_center_activate_schoolpro: {
        Args: { p_reason?: string; p_school: string; p_tier?: string }
        Returns: Json
      }
      convert_consult_request: { Args: { p_request: string }; Returns: string }
      create_business_payment_intent: {
        Args: { p_invoice: string; p_user: string; p_virtual_account: string }
        Returns: {
          amount: number
          created_at: string
          id: string
          invoice_id: string
          order_id: string
          paid_at: string | null
          reference: string
          status: string
          transaction_ref: string | null
          unit_code: string
          updated_at: string
          user_id: string
          virtual_account_id: string
        }
        SetofOptions: {
          from: "*"
          to: "business_payment_intents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_datasub_api_credential: {
        Args: { p_label: string; p_mode?: string }
        Returns: Json
      }
      create_datasub_api_purchase: {
        Args: {
          p_credential_id: string
          p_product_code: string
          p_recipient: string
          p_reference: string
          p_user_id: string
        }
        Returns: Json
      }
      create_host_order: {
        Args: {
          p_cycle?: number
          p_domain?: string
          p_domain_price?: string
          p_notes?: string
          p_order_type: string
          p_plan?: string
        }
        Returns: Json
      }
      create_host_renewal_order: { Args: { p_service: string }; Returns: Json }
      create_schoolpro_fee_bundle: {
        Args: {
          p_classes: string[]
          p_due: string
          p_items: Json
          p_name: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: Json
      }
      create_schoolpro_portal_invite: {
        Args: { p_email: string; p_student: string; p_type: string }
        Returns: string
      }
      create_schoolpro_progression: {
        Args: {
          p_decision: string
          p_reason?: string
          p_session: string
          p_student: string
          p_to_class?: string
        }
        Returns: string
      }
      create_schoolpro_result_pin: {
        Args: {
          target_session: string
          target_student: string
          target_term: string
        }
        Returns: string
      }
      create_schoolpro_workspace: {
        Args: { p_request: string; p_tier?: string }
        Returns: Json
      }
      credit_verified_payment: {
        Args: {
          p_amount: number
          p_payload?: Json
          p_platform: string
          p_provider: string
          p_transaction_ref: string
          p_user: string
        }
        Returns: Json
      }
      datasub_admin_bulk_market_adjust: {
        Args: {
          p_mode?: string
          p_network?: string
          p_plan_type?: string
          p_reason?: string
          p_service?: string
          p_tier?: string
          p_value?: number
        }
        Returns: number
      }
      datasub_admin_update_market_price: {
        Args: {
          p_api: number
          p_offering: string
          p_reason?: string
          p_reseller: number
          p_smart: number
          p_top: number
        }
        Returns: undefined
      }
      datasub_admin_update_upstream_route: {
        Args: {
          p_active: boolean
          p_cost: number
          p_reason?: string
          p_upstream: string
        }
        Returns: undefined
      }
      datasub_claim_referral: { Args: { p_code: string }; Returns: boolean }
      datasub_has_transaction_pin: { Args: never; Returns: boolean }
      datasub_referral_code: { Args: never; Returns: string }
      datasub_transfer_recipient: {
        Args: { p_account: string; p_bank: string }
        Returns: Json
      }
      datasub_transfer_wallet: {
        Args: {
          p_account_id: string
          p_amount: number
          p_pin: string
          p_request_id: string
        }
        Returns: Json
      }
      delete_schoolpro_draft_result: {
        Args: { p_reason?: string; p_result: string }
        Returns: undefined
      }
      disable_datasub_api_webhook: {
        Args: { p_webhook_id: string }
        Returns: undefined
      }
      edit_schoolpro_fee_bundle: {
        Args: {
          p_due: string
          p_items: Json
          p_name: string
          p_structure: string
        }
        Returns: Json
      }
      edit_schoolpro_fee_invoice: {
        Args: {
          p_amount: number
          p_due: string
          p_invoice: string
          p_notes: string
          p_title: string
        }
        Returns: string
      }
      ensure_schoolpro_default_assessment_scheme: {
        Args: { p_school: string }
        Returns: string
      }
      ensure_schoolpro_standard_assessment_schemes: {
        Args: { p_school: string }
        Returns: Json
      }
      finalize_business_billstack_payment: {
        Args: { p_amount: number; p_intent: string; p_transaction_ref: string }
        Returns: Json
      }
      finalize_consult_billstack_payment: {
        Args: { p_amount: number; p_intent: string; p_transaction_ref: string }
        Returns: Json
      }
      finalize_datasub_transaction: {
        Args: {
          p_provider_reference?: string
          p_status: Database["public"]["Enums"]["datasub_transaction_status"]
          p_transaction_id: string
        }
        Returns: undefined
      }
      finalize_engineering_billstack_payment: {
        Args: { p_amount: number; p_intent: string; p_transaction_ref: string }
        Returns: Json
      }
      finalize_host_billstack_payment: {
        Args: {
          p_amount: number
          p_intent: string
          p_payload?: Json
          p_transaction_ref: string
        }
        Returns: Json
      }
      finalize_print_billstack_payment: {
        Args: { p_amount: number; p_intent: string; p_transaction_ref: string }
        Returns: undefined
      }
      finalize_schoolpro_billstack_transfer: {
        Args: {
          p_intent: string
          p_payload?: Json
          p_transaction_ref: string
          p_verified_amount: number
        }
        Returns: Json
      }
      finalize_schoolpro_document_issue: {
        Args: { p_issue: string; p_output_path: string }
        Returns: undefined
      }
      finalize_schoolpro_enrollment: {
        Args: { p_application: string }
        Returns: string
      }
      finalize_schoolpro_payment: {
        Args: {
          p_gateway_transaction_id: string
          p_payload?: Json
          p_reference: string
          p_status: string
          p_verified_amount: number
        }
        Returns: Json
      }
      finalize_schoolpro_subscription: {
        Args: { p_amount: number; p_intent: string; p_transaction_ref: string }
        Returns: Json
      }
      generate_schoolpro_class_invoices: {
        Args: { p_class?: string; p_structure: string }
        Returns: Json
      }
      get_candidate_cbt: { Args: { p_token: string }; Returns: Json }
      get_schoolpro_admission_offer: {
        Args: { p_token: string }
        Returns: Json
      }
      grade_academy_assignment_submission: {
        Args: { p_feedback?: string; p_score: number; p_submission_id: string }
        Returns: undefined
      }
      grade_schoolpro_assignment_submission: {
        Args: { p_feedback?: string; p_score: number; p_submission: string }
        Returns: Json
      }
      hook_password_login_security: { Args: { event: Json }; Returns: Json }
      host_can_provision: { Args: never; Returns: boolean }
      ihlink_worker_token: { Args: never; Returns: string }
      import_schoolpro_results: {
        Args: {
          p_rows: Json
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: Json
      }
      issue_business_invoice: {
        Args: { p_due_at?: string; p_order: string }
        Returns: string
      }
      issue_consult_quotation: {
        Args: {
          p_amount: number
          p_project_id: string
          p_scope_summary: string
          p_valid_until?: string
        }
        Returns: string
      }
      issue_engineering_proposal: {
        Args: {
          p_amount: number
          p_project: string
          p_scope: string
          p_title: string
          p_valid_until?: string
        }
        Returns: string
      }
      issue_schoolpro_admission_offer: {
        Args: {
          p_application: string
          p_expiry: string
          p_instructions: string
          p_letter: string
        }
        Returns: Json
      }
      issue_schoolpro_result_verification: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: string
      }
      link_schoolpro_guardian: {
        Args: {
          guardian_email: string
          guardian_relationship?: string
          target_student: string
        }
        Returns: string
      }
      link_schoolpro_student_account: {
        Args: { target_email: string; target_student: string }
        Returns: undefined
      }
      list_available_schoolpro_cbts: {
        Args: never
        Returns: {
          attempts_allowed: number
          attempts_used: number
          closes_at: string
          duration_minutes: number
          eligible: boolean
          id: string
          instructions: string
          opens_at: string
          title: string
          total_marks: number
        }[]
      }
      manage_consult_milestone: {
        Args: {
          p_action: string
          p_description?: string
          p_due?: string
          p_project: string
          p_record?: string
          p_title?: string
        }
        Returns: string
      }
      manage_host_order: {
        Args: { p_action: string; p_order: string }
        Returns: Json
      }
      manage_schoolpro_subscription_invoice: {
        Args: {
          p_action: string
          p_invoice: string
          p_reason: string
          p_version: string
        }
        Returns: Json
      }
      manage_service_invoice: {
        Args: {
          p_action: string
          p_amount?: number
          p_description?: string
          p_invoice: string
          p_name?: string
          p_platform: string
          p_reason: string
          p_version: string
        }
        Returns: Json
      }
      mark_candidate_cbt_theory: {
        Args: {
          p_attempt: string
          p_feedback?: string
          p_marks: number
          p_question: string
        }
        Returns: Json
      }
      mark_finance_refund_processed: {
        Args: { p_provider_reference: string; p_refund: string }
        Returns: Json
      }
      mark_host_notification_read: {
        Args: { p_notification: string }
        Returns: boolean
      }
      mark_schoolpro_cbt_theory: {
        Args: {
          p_attempt: string
          p_feedback?: string
          p_marks: number
          p_question: string
        }
        Returns: Json
      }
      mark_schoolpro_theory_answer: {
        Args: { p_answer: string; p_feedback?: string; p_marks: number }
        Returns: undefined
      }
      move_datasub_referral_earnings: { Args: never; Returns: number }
      my_payment_outcomes: {
        Args: { p_platform: string }
        Returns: {
          amount: number
          created_at: string
          credited_at: string
          is_settled: boolean
          provider_reference: string
          refund_number: string
          refund_reason: string
          refund_status: string
          status: string
          transaction_ref: string
        }[]
      }
      prepare_schoolpro_bank_subscription: {
        Args: { p_catalog: string; p_school: string }
        Returns: Json
      }
      prepare_schoolpro_subscription_payment: {
        Args: {
          p_account: string
          p_catalog: string
          p_school: string
          p_user: string
        }
        Returns: Json
      }
      prepare_service_invoice_payment: {
        Args: {
          p_account: string
          p_invoice: string
          p_platform: string
          p_user: string
        }
        Returns: Json
      }
      print_adjust_stock: {
        Args: {
          p_inventory: string
          p_job?: string
          p_movement: string
          p_notes: string
          p_quantity: number
        }
        Returns: string
      }
      print_admin: { Args: never; Returns: boolean }
      print_advance_job: {
        Args: { p_notes?: string; p_order: string; p_stage: string }
        Returns: string
      }
      print_dispatch_order: {
        Args: {
          p_order: string
          p_recipient: string
          p_status: string
          p_tracking?: string
        }
        Returns: string
      }
      print_invoice_accepted_quote: {
        Args: { p_due_at?: string; p_order: string }
        Returns: string
      }
      print_issue_artwork_proof: {
        Args: { p_artwork: string }
        Returns: string
      }
      print_issue_quote: {
        Args: {
          p_delivery: number
          p_discount: number
          p_order: string
          p_subtotal: number
          p_tax: number
          p_valid_until: string
        }
        Returns: string
      }
      print_record_qc: {
        Args: { p_job: string; p_notes: string; p_passed: boolean }
        Returns: string
      }
      process_datasub_provider_callback: {
        Args: {
          p_available_balance?: number
          p_external_event_id: string
          p_payload?: Json
          p_provider_code: string
          p_provider_reference?: string
          p_response_ms?: number
          p_status: string
          p_transaction_reference: string
        }
        Returns: Json
      }
      process_schoolpro_payroll: {
        Args: { p_record: string }
        Returns: undefined
      }
      publish_schoolpro_class_results: {
        Args: {
          p_class: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: number
      }
      publish_schoolpro_results: {
        Args: { p_school: string; p_session: string; p_term: string }
        Returns: number
      }
      publish_schoolpro_selected_results: {
        Args: {
          p_all?: boolean
          p_school: string
          p_session: string
          p_students?: string[]
          p_term: string
        }
        Returns: number
      }
      qa_cleanup_acceptance_run: { Args: { p_run: string }; Returns: boolean }
      qa_create_acceptance_run: {
        Args: { p_payload?: Json; p_platform: string; p_scenario?: string }
        Returns: {
          cleaned_at: string | null
          created_at: string
          id: string
          payload: Json
          platform_code: string
          result: Json
          run_code: string
          scenario: string
          status: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "qa_acceptance_runs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      qa_mark_acceptance_run: {
        Args: { p_result?: Json; p_run: string; p_status: string }
        Returns: {
          cleaned_at: string | null
          created_at: string
          id: string
          payload: Json
          platform_code: string
          result: Json
          run_code: string
          scenario: string
          status: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "qa_acceptance_runs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      queue_failed_fulfilment_refund: {
        Args: {
          p_amount: number
          p_customer: string
          p_product: string
          p_reason: string
          p_source_reference: string
        }
        Returns: string
      }
      queue_schoolpro_email: {
        Args: {
          p_email: string
          p_name: string
          p_payload?: Json
          p_school: string
          p_subject: string
          p_template: string
        }
        Returns: string
      }
      record_schoolpro_payment: {
        Args: {
          payment_amount: number
          payment_method: string
          payment_notes?: string
          payment_reference: string
          target_invoice: string
        }
        Returns: string
      }
      recover_datasub_transaction_pin: {
        Args: { p_pin: string; p_user: string }
        Returns: undefined
      }
      refund_datasub_wallet: {
        Args: {
          p_amount: number
          p_reference: string
          p_transaction: string
          p_user: string
        }
        Returns: boolean
      }
      register_consult_proposal: {
        Args: {
          p_mime_type: string
          p_original_filename: string
          p_project_id: string
          p_storage_path: string
          p_title: string
          p_valid_until: string
        }
        Returns: string
      }
      render_ihlink_template: {
        Args: { p_platform: string; p_type: string; p_values?: Json }
        Returns: {
          rendered_content: string
          storage_path: string
          template_id: string
          template_name: string
        }[]
      }
      reopen_schoolpro_result_for_correction: {
        Args: { p_reason: string; p_result: string }
        Returns: string
      }
      request_account_deletion: {
        Args: { p_reason?: string }
        Returns: {
          anonymised: boolean
          approved_at: string | null
          cancelled_at: string | null
          completed_at: string | null
          finalised_by: string | null
          id: string
          reason: string | null
          requested_at: string
          resolution_note: string | null
          resolved_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "account_deletion_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      request_schoolpro_workspace_demo: {
        Args: { p_request: string; p_tier?: string }
        Returns: Json
      }
      reserve_datasub_wallet: {
        Args: {
          p_amount: number
          p_reference: string
          p_transaction: string
          p_user: string
        }
        Returns: boolean
      }
      resolve_ihlink_email_template: {
        Args: { p_key: string; p_platform: string; p_values?: Json }
        Returns: {
          html_body: string
          subject: string
          template_id: string
          template_name: string
          text_body: string
        }[]
      }
      respond_business_quote: {
        Args: { p_quote: string; p_response: string }
        Returns: undefined
      }
      respond_consult_deliverable: {
        Args: { p_action: string; p_deliverable: string; p_feedback?: string }
        Returns: string
      }
      respond_consult_proposal: {
        Args: { p_action: string; p_proposal: string }
        Returns: Json
      }
      respond_consult_quotation: {
        Args: { p_action: string; p_quotation: string }
        Returns: Json
      }
      respond_engineering_proposal: {
        Args: { p_proposal: string; p_response: string }
        Returns: string
      }
      respond_print_proof: {
        Args: { p_notes?: string; p_proof: string; p_response: string }
        Returns: string
      }
      respond_service_invoice_change: {
        Args: { p_accept: boolean; p_change: string }
        Returns: Json
      }
      retry_ihlink_email: { Args: { p_id: string }; Returns: undefined }
      retry_schoolpro_email: { Args: { p_job: string }; Returns: undefined }
      return_schoolpro_library_book: {
        Args: { p_fine?: number; p_loan: string }
        Returns: undefined
      }
      review_account_deletion: {
        Args: { p_action: string; p_note?: string; p_request_id: string }
        Returns: {
          anonymised: boolean
          approved_at: string | null
          cancelled_at: string | null
          completed_at: string | null
          finalised_by: string | null
          id: string
          reason: string | null
          requested_at: string
          resolution_note: string | null
          resolved_at: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "account_deletion_requests"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      review_datasub_network_availability: {
        Args: {
          p_available: boolean
          p_evidence: string
          p_network: string
          p_provider: string
          p_service: string
        }
        Returns: Json
      }
      review_datasub_upgrade_request: {
        Args: { p_approve: boolean; p_request_id: string }
        Returns: undefined
      }
      review_datasub_wallet_funding: {
        Args: {
          decision: Database["public"]["Enums"]["wallet_funding_status"]
          request_id: string
        }
        Returns: undefined
      }
      review_direct_bank_transfer: {
        Args: { p_decision: string; p_note?: string; p_submission: string }
        Returns: Json
      }
      review_finance_refund: {
        Args: { p_decision: string; p_note?: string; p_refund: string }
        Returns: Json
      }
      review_schoolpro_leave: {
        Args: { p_request: string; p_status: string }
        Returns: undefined
      }
      review_schoolpro_onboarding: {
        Args: {
          p_action: string
          p_expected_status: string
          p_note?: string
          p_request: string
          p_tier?: string
        }
        Returns: Json
      }
      review_schoolpro_payment_proof: {
        Args: { p_decision: string; p_note?: string; p_proof: string }
        Returns: Json
      }
      review_schoolpro_payment_submission: {
        Args: { p_decision: string; p_note?: string; p_submission: string }
        Returns: Json
      }
      review_schoolpro_result: {
        Args: { p_notes?: string; p_result: string; p_status: string }
        Returns: undefined
      }
      revoke_datasub_api_credential: {
        Args: { p_credential_id: string }
        Returns: undefined
      }
      revoke_schoolpro_document_issue: {
        Args: { p_issue: string; p_reason: string }
        Returns: undefined
      }
      rotate_datasub_provider_token: {
        Args: { p_provider_code: string }
        Returns: Json
      }
      save_candidate_cbt_answer: {
        Args: { p_answer: string; p_question: string; p_token: string }
        Returns: undefined
      }
      save_schoolpro_cbt_answer: {
        Args: { p_answer: string; p_attempt: string; p_question: string }
        Returns: undefined
      }
      schedule_schoolpro_admission_event: {
        Args: {
          p_application: string
          p_at: string
          p_location: string
          p_notes: string
          p_type: string
        }
        Returns: string
      }
      schoolpro_academic_summary: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: {
          average_score: number
          class_population: number
          class_position: number
          grade: string
          remark: string
          subject_count: number
          total_score: number
        }[]
      }
      schoolpro_accept_access_invitation: {
        Args: { p_hash: string; p_user: string }
        Returns: boolean
      }
      schoolpro_allocate_hostel: {
        Args: {
          p_room: string
          p_school: string
          p_session: string
          p_student: string
        }
        Returns: string
      }
      schoolpro_broadsheet: {
        Args: {
          p_class: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: {
          admission_number: string
          average: number
          class_position: number
          student_id: string
          student_name: string
          subjects: number
          total: number
        }[]
      }
      schoolpro_bulk_academic_action: {
        Args: {
          p_action: string
          p_school: string
          p_session: string
          p_students?: string[]
        }
        Returns: Json
      }
      schoolpro_can_author_cbt: { Args: { p_school: string }; Returns: boolean }
      schoolpro_can_manage_cbt: { Args: { p_school: string }; Returns: boolean }
      schoolpro_can_release_result: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: boolean
      }
      schoolpro_can_view_result_output: {
        Args: { p_session: string; p_student_id: string; p_term: string }
        Returns: boolean
      }
      schoolpro_cbt_is_eligible: {
        Args: { p_student: string; p_test: string }
        Returns: boolean
      }
      schoolpro_class_broadsheet: {
        Args: {
          p_class: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: Json
      }
      schoolpro_class_review_sheet: {
        Args: {
          p_class: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: Json
      }
      schoolpro_class_staff_directory: {
        Args: { p_school: string }
        Returns: {
          id: string
          name: string
          role: string
          user_id: string
        }[]
      }
      schoolpro_consume_account_challenge: {
        Args: { p_hash: string; p_password: string; p_user: string }
        Returns: boolean
      }
      schoolpro_consume_student_challenge: {
        Args: { p_hash: string }
        Returns: string
      }
      schoolpro_coordinator_classes: {
        Args: { p_school: string }
        Returns: string[]
      }
      schoolpro_current_academic_period: {
        Args: { p_school: string }
        Returns: Json
      }
      schoolpro_family_result_periods: {
        Args: { p_student: string }
        Returns: {
          allowed: boolean
          reason: string
          session: string
          term: string
        }[]
      }
      schoolpro_finalize_testing_certificate: {
        Args: { p_issue: string; p_output_path: string }
        Returns: undefined
      }
      schoolpro_grade_for_score: {
        Args: { p_school: string; p_score: number }
        Returns: {
          grade: string
          remark: string
        }[]
      }
      schoolpro_initial_challenge: {
        Args: { p_hash: string; p_surname: string; p_user: string }
        Returns: boolean
      }
      schoolpro_issue_library_loan: {
        Args: {
          p_book: string
          p_due?: string
          p_member?: string
          p_school: string
          p_student?: string
        }
        Returns: string
      }
      schoolpro_issue_transcript: {
        Args: { p_student: string }
        Returns: string
      }
      schoolpro_join_school_code: {
        Args: { p_school_code: string; p_user: string }
        Returns: string
      }
      schoolpro_member_can_manage: {
        Args: { p_school: string }
        Returns: boolean
      }
      schoolpro_overall_grade: {
        Args: { p_session: string; p_student_id: string; p_term: string }
        Returns: {
          average_score: number
          grade: string
          remark: string
        }[]
      }
      schoolpro_printable_result: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: {
          approved_at: string | null
          approved_by: string | null
          assessment_scheme_id: string | null
          assessment_scores: Json
          ca_score: number
          created_at: string
          exam_score: number
          head_teacher_comment: string | null
          id: string
          locked: boolean
          published_at: string | null
          school_id: string
          session: string
          status: Database["public"]["Enums"]["schoolpro_result_status"]
          student_id: string
          subject_id: string
          teacher_comment: string | null
          term: string
          total_score: number | null
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "schoolpro_results"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      schoolpro_progression_summary: {
        Args: { p_session: string; p_student: string }
        Returns: {
          applied_at: string
          from_class: string
          graduated: boolean
          progression_session: string
          progression_status: string
          to_class: string
        }[]
      }
      schoolpro_record_offline_payment: {
        Args: {
          p_amount: number
          p_invoice: string
          p_method: string
          p_notes?: string
          p_reference: string
        }
        Returns: string
      }
      schoolpro_report_details: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: Json
      }
      schoolpro_result_access: {
        Args: {
          target_session: string
          target_student: string
          target_term: string
        }
        Returns: {
          allowed: boolean
          outstanding: number
          reason: string
        }[]
      }
      schoolpro_result_class_rank: {
        Args: { p_session: string; p_student_id: string; p_term: string }
        Returns: {
          average_score: number
          class_population: number
          class_position: number
          total_score: number
        }[]
      }
      schoolpro_result_comment: { Args: { p_score: number }; Returns: string }
      schoolpro_return_library_loan: {
        Args: { p_loan: string }
        Returns: undefined
      }
      schoolpro_review_result: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: {
          approved_at: string | null
          approved_by: string | null
          assessment_scheme_id: string | null
          assessment_scores: Json
          ca_score: number
          created_at: string
          exam_score: number
          head_teacher_comment: string | null
          id: string
          locked: boolean
          published_at: string | null
          school_id: string
          session: string
          status: Database["public"]["Enums"]["schoolpro_result_status"]
          student_id: string
          subject_id: string
          teacher_comment: string | null
          term: string
          total_score: number | null
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "schoolpro_results"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      schoolpro_revoke_transcript: {
        Args: { p_issue: string }
        Returns: undefined
      }
      schoolpro_save_academic_calendar: {
        Args: {
          p_end: string
          p_school: string
          p_session: string
          p_start: string
          p_term: string
        }
        Returns: undefined
      }
      schoolpro_send_school_notice: {
        Args: {
          p_audience?: string
          p_classes?: string[]
          p_message: string
          p_school: string
          p_students?: string[]
          p_title: string
        }
        Returns: number
      }
      schoolpro_set_board_role: {
        Args: { p_member: string; p_school: string; p_title: string }
        Returns: undefined
      }
      schoolpro_set_form_master: {
        Args: { p_class: string; p_member: string }
        Returns: undefined
      }
      schoolpro_set_initial_credential: {
        Args: { p_school: string; p_surname: string; p_user: string }
        Returns: undefined
      }
      schoolpro_set_result_access_exception: {
        Args: {
          p_allowed: boolean
          p_reason: string
          p_session: string
          p_student: string
          p_term: string
        }
        Returns: undefined
      }
      schoolpro_set_result_lock: {
        Args: {
          p_locked: boolean
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: number
      }
      schoolpro_student_transcripts: {
        Args: { p_student: string }
        Returns: Json
      }
      schoolpro_subject_statistics: {
        Args: { p_session: string; p_student: string; p_term: string }
        Returns: Json
      }
      schoolpro_submit_class_results: {
        Args: {
          p_class: string
          p_school: string
          p_session: string
          p_term: string
        }
        Returns: string
      }
      schoolpro_subscription_entitlements: {
        Args: { p_school: string }
        Returns: Json
      }
      schoolpro_take_login_attempt: {
        Args: { p_key: string; p_limit: number }
        Returns: boolean
      }
      schoolpro_transfer_ownership: {
        Args: { p_new_owner_id: string; p_school_id: string }
        Returns: Json
      }
      schoolpro_transfer_student_out: {
        Args: { p_destination: string; p_reason: string; p_student: string }
        Returns: undefined
      }
      schoolpro_user_permissions: {
        Args: { p_school: string }
        Returns: string[]
      }
      schoolpro_vacate_hostel: {
        Args: { p_allocation: string }
        Returns: undefined
      }
      schoolpro_verify_result_code: {
        Args: { p_code: string }
        Returns: {
          admission_number: string
          class_name: string
          issued_at: string
          school_name: string
          session: string
          snapshot: Json
          status: string
          student_name: string
          term: string
        }[]
      }
      set_datasub_provider_automatic_routing: {
        Args: {
          p_enabled: boolean
          p_minimum_balance?: number
          p_provider_id: string
        }
        Returns: Json
      }
      set_datasub_transaction_pin: {
        Args: { p_current_pin?: string; p_pin: string }
        Returns: undefined
      }
      set_ihlink_default_template: {
        Args: { p_template: string }
        Returns: undefined
      }
      set_payment_bank_policy: {
        Args: {
          p_bank_code: string
          p_customer_enabled: boolean
          p_enabled: boolean
          p_reason?: string
        }
        Returns: Json
      }
      set_payment_fee: {
        Args: {
          p_customer_pays?: boolean
          p_enabled?: boolean
          p_fee_code: string
          p_fee_type: string
          p_fee_value: number
          p_maximum?: number
          p_minimum?: number
          p_platform: string
          p_provider: string
          p_reason?: string
        }
        Returns: {
          created_at: string
          customer_pays: boolean
          enabled: boolean
          fee_code: string
          fee_type: string
          fee_value: number
          id: string
          maximum_fee: number | null
          minimum_fee: number | null
          platform_code: string
          provider: string
          updated_at: string
          updated_by: string | null
        }
        SetofOptions: {
          from: "*"
          to: "payment_fee_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_schoolpro_default_document_template: {
        Args: { p_template: string }
        Returns: undefined
      }
      start_schoolpro_cbt: { Args: { p_test: string }; Returns: Json }
      submit_academy_assignment: {
        Args: {
          p_assignment_id: string
          p_submission_text?: string
          p_submission_url?: string
        }
        Returns: string
      }
      submit_business_request: {
        Args: {
          catalog_service?: string
          request_quantity: number
          request_requirements: string
          request_specs?: Json
          request_title: string
          target_unit: string
        }
        Returns: string
      }
      submit_candidate_cbt: { Args: { p_token: string }; Returns: number }
      submit_consult_deliverable: {
        Args: {
          p_description: string
          p_file_url: string
          p_milestone?: string
          p_project: string
          p_title: string
        }
        Returns: string
      }
      submit_direct_bank_transfer: {
        Args: {
          p_amount: number
          p_customer_reference: string
          p_invoice: string
          p_platform: string
          p_proof_storage_path?: string
          p_sender_bank: string
          p_sender_name: string
          p_source_reference: string
          p_transferred_at?: string
        }
        Returns: string
      }
      submit_print_request: {
        Args: {
          p_address: string
          p_description: string
          p_fulfillment: string
          p_options?: Json
          p_product: string
          p_quantity: number
        }
        Returns: string
      }
      submit_schoolpro_application: {
        Args: {
          p_class: string
          p_dob: string
          p_email: string
          p_first: string
          p_gender: string
          p_guardian: string
          p_last: string
          p_phone: string
          p_previous?: string
          p_school: string
        }
        Returns: Json
      }
      submit_schoolpro_assignment: {
        Args: {
          p_assignment: string
          p_file_url?: string
          p_submission_text?: string
        }
        Returns: string
      }
      submit_schoolpro_cbt: { Args: { p_attempt: string }; Returns: Json }
      submit_schoolpro_payment: {
        Args: {
          p_allocations: Json
          p_bank_account: string
          p_bank_reference: string
          p_payer_name: string
          p_payment_date: string
          p_receipt_mime: string
          p_receipt_path: string
          p_school: string
          p_total: number
        }
        Returns: string
      }
      submit_schoolpro_term_demo: {
        Args: {
          p_calendar: string
          p_exam_end: string
          p_exam_start: string
          p_letter: string
          p_request: string
          p_term_end: string
          p_term_start: string
          p_tier: string
        }
        Returns: Json
      }
      submit_service_bank_transfer: {
        Args: {
          p_amount: number
          p_bank_account: string
          p_customer_reference: string
          p_invoice: string
          p_platform: string
          p_proof_storage_path: string
          p_sender_bank: string
          p_sender_name: string
          p_source_reference: string
          p_transferred_at: string
        }
        Returns: string
      }
      verify_datasub_transaction_pin: {
        Args: { p_pin: string; p_user: string }
        Returns: boolean
      }
      verify_schoolpro_admission_document: {
        Args: { p_document: string; p_notes?: string; p_verified: boolean }
        Returns: undefined
      }
      verify_schoolpro_document: {
        Args: { p_serial: string }
        Returns: {
          document_type: string
          issued_at: string
          school_name: string
          serial_number: string
          status: string
          student_name: string
          title: string
        }[]
      }
    }
    Enums: {
      account_status: "active" | "suspended" | "invited"
      datasub_transaction_status: "pending" | "success" | "failed" | "reversed"
      school_member_role:
        | "proprietor"
        | "administrator"
        | "teacher"
        | "accountant"
        | "vice_principal"
        | "head_teacher"
        | "bursar"
        | "registrar"
        | "admissions_officer"
        | "exam_officer"
        | "class_teacher"
        | "librarian"
        | "counsellor"
        | "nurse"
        | "hostel_manager"
        | "transport_manager"
        | "inventory_officer"
        | "hr_officer"
        | "receptionist"
        | "it_admin"
      school_status: "trial" | "active" | "suspended"
      schoolpro_attendance_status: "present" | "absent" | "late" | "excused"
      schoolpro_invoice_status: "unpaid" | "part_paid" | "paid" | "waived"
      schoolpro_result_status: "draft" | "approved" | "published"
      user_role:
        | "super_admin"
        | "platform_admin"
        | "support"
        | "finance"
        | "customer"
      wallet_funding_status: "pending" | "approved" | "rejected"
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
      account_status: ["active", "suspended", "invited"],
      datasub_transaction_status: ["pending", "success", "failed", "reversed"],
      school_member_role: [
        "proprietor",
        "administrator",
        "teacher",
        "accountant",
        "vice_principal",
        "head_teacher",
        "bursar",
        "registrar",
        "admissions_officer",
        "exam_officer",
        "class_teacher",
        "librarian",
        "counsellor",
        "nurse",
        "hostel_manager",
        "transport_manager",
        "inventory_officer",
        "hr_officer",
        "receptionist",
        "it_admin",
      ],
      school_status: ["trial", "active", "suspended"],
      schoolpro_attendance_status: ["present", "absent", "late", "excused"],
      schoolpro_invoice_status: ["unpaid", "part_paid", "paid", "waived"],
      schoolpro_result_status: ["draft", "approved", "published"],
      user_role: [
        "super_admin",
        "platform_admin",
        "support",
        "finance",
        "customer",
      ],
      wallet_funding_status: ["pending", "approved", "rejected"],
    },
  },
} as const
