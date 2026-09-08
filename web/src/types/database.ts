// TypeScript Definitions for Database Entities & Stored Functions

export interface Staff {
  staff_id: string;
  full_name: string;
  gender: number; // 0: Female, 1: Male, 2: Other
  date_of_birth: string;
  email: string;
  phone_number: string;
  position: string;
  manager_id?: string | null;
  manager_name?: string | null;
  status: 'Active' | 'ON_LEAVE' | 'RESIGNED';
  is_deleted?: boolean;
}

export interface Program {
  program_id: string;
  program_name: string;
  description: string;
  version: string;
  manager_id: string;
  manager_name?: string;
  manager_email?: string;
  status: 'DRAFT' | 'ACTIVE' | 'CLOSED';
  subject_count?: number;
  is_deleted?: boolean;
}

export interface Subject {
  subject_id: string;
  subject_name: string;
  program_id: string;
  program_name?: string;
  total_hours: number;
  total_sessions: number;
  subject_type: 'CORE' | 'ELECTIVE';
  is_deleted?: boolean;
}

export interface Semester {
  semester_id: string;
  semester_name: string;
  start_date: string;
  end_date: string;
  status: 'UPCOMING' | 'ONGOING' | 'FINISHED';
}

export interface ClassEntity {
  class_id: string;
  class_name: string;
  program_id: string;
  program_name?: string;
  semester_id: string;
  semester_name?: string;
  max_capacity: number;
  current_enrolled?: number;
  remaining_slots?: number;
  status: 'OPEN' | 'FULL' | 'RUNNING' | 'CLOSED';
  is_deleted?: boolean;
}

export interface Student {
  student_id: string;
  full_name: string;
  date_of_birth: string;
  phone_number: string;
  email?: string;
  source?: string;
  status: 'ACTIVE' | 'RESERVED' | 'DROPPED';
  is_deleted?: boolean;
}

export interface Instructor {
  instructor_id: string;
  full_name: string;
  email: string;
  phone_number?: string;
  specialization?: string;
  degree?: string;
  contract_type: 'FULLTIME' | 'PARTTIME';
  is_deleted?: boolean;
}

export interface Room {
  room_id: string;
  room_name: string;
  location?: string;
  capacity: number;
  room_type: 'LAB' | 'STANDARD';
  status: 'READY' | 'MAINTENANCE';
  is_deleted?: boolean;
}

export interface ClassSession {
  session_id: number;
  class_id: string;
  class_name?: string;
  subject_id: string;
  subject_name?: string;
  start_time: string;
  end_time: string;
  room_id: string;
  room_name?: string;
  main_instructor_id: string;
  main_instructor_name?: string;
  teaching_assistant_id?: string | null;
  teaching_assistant_name?: string | null;
  session_type?: 'NORMAL' | 'MAKEUP' | 'EXAM';
  status: 'SCHEDULED' | 'COMPLETED' | 'CANCELED';
  is_deleted?: boolean;
}

export interface Enrollment {
  enrollment_id: number;
  student_id: string;
  student_name?: string;
  class_id: string;
  class_name?: string;
  enrolled_date: string;
  status: 'ENROLLED' | 'DROPPED' | 'COMPLETED';
}

export interface ExamResult {
  result_id: number;
  student_id: string;
  class_id: string;
  subject_id: string;
  attempt_number: number;
  score: number;
  exam_date: string;
  evaluation?: string;
  remarks?: string;
}

// Stored Function Results
export interface StudentTranscriptRow {
  student_id: string;
  student_name: string;
  class_id: string;
  class_name: string;
  subject_id: string;
  subject_name: string;
  attempt_number: number;
  score: number;
  exam_date: string;
  evaluation: string;
}

export interface IncompleteStudentRow {
  student_id: string;
  student_name: string;
  class_id: string;
  class_name: string;
  subject_id: string;
  subject_name: string;
  completion_status: string; // 'Chưa đạt (Thi rớt)' | 'Chưa hoàn thành (Chưa dự thi)'
  failed_exam_details: string; // Ví dụ: 'Lần 1: 4.0 điểm (Ngày 20/09/2026); Lần 2: 4.8 điểm (Ngày 27/09/2026)'
  failed_attempts_count: number;
}

export interface InstructorSalaryRow {
  instructor_id: string;
  full_name: string;
  contract_type: string;
  teaching_hours: number;
  ta_hours: number;
  total_salary: number;
}

export interface StaffSalaryRow {
  staff_id: string;
  full_name: string;
  staff_position: string;
  base_salary: number;
  subordinates_count: number;
  management_bonus: number;
  managed_students_count: number;
  program_management_pay: number;
  total_income: number;
}

export interface DashboardStats {
  totalStudents: number;
  totalPrograms: number;
  totalClasses: number;
  totalInstructors: number;
  enrollmentSummary: Array<{
    class_id: string;
    class_name: string;
    program_name: string;
    max_capacity: number;
    enrolled_count: number;
    completion_rate_pct: number;
    class_status: string;
  }>;
}
