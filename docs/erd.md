# SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD)

```mermaid
erDiagram
    STAFF ||--o{ STAFF : "manages (manager_id)"
    STAFF ||--o{ PROGRAM : "directs (manager_id)"
    
    PROGRAM ||--|{ SUBJECT : "contains"
    PROGRAM ||--o{ CLASS : "instantiates"
    
    SEMESTER ||--o{ CLASS : "schedules"
    
    STUDENT ||--o{ ENROLLMENT : "registers"
    CLASS ||--o{ ENROLLMENT : "admits"
    
    CLASS ||--o{ CLASS_SESSION : "has"
    SUBJECT ||--o{ CLASS_SESSION : "delivers"
    ROOM ||--o{ CLASS_SESSION : "hosts"
    INSTRUCTOR ||--o{ CLASS_SESSION : "teaches (main)"
    INSTRUCTOR ||--o{ CLASS_SESSION : "assists (ta)"
    
    STUDENT ||--o{ EXAM_RESULT : "takes"
    CLASS ||--o{ EXAM_RESULT : "records"
    SUBJECT ||--o{ EXAM_RESULT : "evaluated_in"

    STAFF {
        varchar staff_id PK
        varchar full_name
        int gender
        date date_of_birth
        varchar email UK
        varchar phone_number UK
        varchar position
        varchar manager_id FK
        varchar status
    }

    PROGRAM {
        varchar program_id PK
        varchar program_name
        text description
        varchar version
        varchar manager_id FK
        varchar status
    }

    SUBJECT {
        varchar subject_id PK
        varchar subject_name
        varchar program_id FK
        int total_hours
        int total_sessions
        varchar subject_type
    }

    SEMESTER {
        varchar semester_id PK
        varchar semester_name
        date start_date
        date end_date
        varchar status
    }

    CLASS {
        varchar class_id PK
        varchar class_name
        varchar program_id FK
        varchar semester_id FK
        int max_capacity
        varchar status
    }

    STUDENT {
        varchar student_id PK
        varchar full_name
        date date_of_birth
        varchar phone_number UK
        varchar email UK
        varchar status
    }

    INSTRUCTOR {
        varchar instructor_id PK
        varchar full_name
        varchar email UK
        varchar phone_number
        varchar specialization
        varchar contract_type
    }

    ROOM {
        varchar room_id PK
        varchar room_name
        varchar location
        int capacity
        varchar room_type
        varchar status
    }

    ENROLLMENT {
        varchar student_id PK, FK
        varchar class_id PK, FK
        timestamp enrollment_date
        numeric tuition_paid
        varchar status
    }

    CLASS_SESSION {
        bigint session_id PK
        varchar class_id FK
        varchar subject_id FK
        timestamp start_time
        timestamp end_time
        varchar room_id FK
        varchar main_instructor_id FK
        varchar teaching_assistant_id FK
        varchar session_type
        varchar status
    }

    EXAM_RESULT {
        varchar student_id PK, FK
        varchar class_id PK, FK
        varchar subject_id PK, FK
        int attempt_number PK
        numeric score
        date exam_date
        varchar evaluation
    }
```
