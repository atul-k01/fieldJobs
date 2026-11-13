-- ============================================================================
-- FieldJobs Supabase Backend Schema & Seed Script
-- Compatible with Supabase PostgreSQL
-- ============================================================================

-- 1. Create Technicians Table
CREATE TABLE IF NOT EXISTS public.technicians (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Jobs Table
CREATE TABLE IF NOT EXISTS public.jobs (
    id TEXT PRIMARY KEY,
    assigned_to TEXT NOT NULL REFERENCES public.technicians(email) ON UPDATE CASCADE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL,
    scheduled_date DATE NOT NULL,
    time_window TEXT NOT NULL,
    appliance TEXT NOT NULL,
    problem_description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'assigned', -- 'assigned', 'travelling', 'on_site', 'completed', 'could_not_complete', 'cancelled'
    cannot_complete_reason TEXT,
    technician_notes TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_jobs_assigned_to ON public.jobs(assigned_to);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_date ON public.jobs(scheduled_date);

-- 3. Create Job Checklists Table
CREATE TABLE IF NOT EXISTS public.job_checklists (
    id TEXT PRIMARY KEY,
    job_id TEXT NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_checklists_job_id ON public.job_checklists(job_id);

-- 4. Enable Row Level Security (RLS) & Grant Access
ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_checklists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read-write for demo technicians" ON public.technicians FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for demo jobs" ON public.jobs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write for demo checklists" ON public.job_checklists FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- 5. Seed Demo Technicians
-- ============================================================================
INSERT INTO public.technicians (id, email, name)
VALUES 
    ('tech-001-alex', 'alex@fieldjobs.com', 'Alex Rivera'),
    ('tech-002-sarah', 'sarah@fieldjobs.com', 'Sarah Connor')
ON CONFLICT (id) DO UPDATE 
SET email = EXCLUDED.email, name = EXCLUDED.name;

-- ============================================================================
-- 6. Seed 200 Demo Jobs Spread across 14 days
-- ============================================================================
DO $$
DECLARE
    tech_emails TEXT[] := ARRAY['alex@fieldjobs.com', 'sarah@fieldjobs.com'];
    tech_email TEXT;
    day_offset INT;
    job_idx INT;
    job_id_counter INT := 1;
    curr_job_id TEXT;
    appliances TEXT[] := ARRAY[
        'Voltas 1.5 Ton 5-Star Inverter Split AC',
        'LG 340L Double Door Smart Inverter Refrigerator',
        'Samsung 7.5 Kg Fully-Automatic Front Load Washer',
        'IFB 6 Kg Senator Front Load Washing Machine',
        'Whirlpool 265L Frost-Free Double Door Refrigerator',
        'Havells 25L Storage Water Heater Geyser',
        'Bosch 14-Place Settings Dishwasher',
        'Godrej 190L Direct-Cool Single Door Refrigerator',
        'Panasonic 27L Convection Microwave Oven',
        'Daikin 1.8 Ton 3-Star Inverter Split AC'
    ];
    problems TEXT[] := ARRAY[
        'AC not cooling properly, outdoor fan motor tripping MCB',
        'Refrigerator bottom freezer leaking water, temperature fluctuating',
        'Washing machine drum vibrating loudly during high-speed spin cycle',
        'Microwave turntable rotating but heating element completely dead',
        'Dishwasher error code E24 drainage pump jammed with debris',
        'Geyser thermostat not auto-cutting, excessive steam buildup',
        'Refrigerator compressor clicking repeatedly every 2 minutes',
        'Washing machine water inlet solenoid valve stuck open, overflowing'
    ];
    customers TEXT[] := ARRAY[
        'Gurpreet Singh', 'Simran Kaur', 'Amit Sharma', 'Harpreet Sandhu',
        'Priya Sharma', 'Rohan Verma', 'Manpreet Kaur', 'Vikram Malhotra',
        'Neha Gupta', 'Rajesh Kumar', 'Jaspreet Singh', 'Anjali Mehra'
    ];
    streets TEXT[] := ARRAY[
        -- Chandigarh
        'House # 1204, Sector 35-B, Chandigarh',
        'SCO 42, Sector 17-C, Chandigarh',
        'House # 418, Sector 8-A, Chandigarh',
        'Flat 302, Sector 43-B, Chandigarh',
        'Booth 55, Sector 22-D, Chandigarh',
        'Modern Housing Complex, Mani Majra, Chandigarh',
        -- Mohali
        'House # 245, Phase 7, Mohali',
        'SCF 18, Phase 3B2, Mohali',
        'House # 1420, Sector 70, Mohali',
        'Flat 401, Homeland Heights, Sector 70, Mohali',
        'Plot 512, JLPL Industrial Area, Sector 82, Mohali',
        'Block C, Aerocity, Mohali',
        -- Panchkula
        'House # 514, Sector 20, Panchkula',
        'SCO 88, Sector 14, Panchkula',
        'House # 128, Sector 7, Panchkula',
        'House # 95, MDC Sector 4, Panchkula',
        'House # 732, Sector 21, Panchkula'
    ];
    windows TEXT[] := ARRAY['08:00 - 10:00 AM', '10:00 - 12:00 PM', '12:30 - 02:30 PM', '02:30 - 04:30 PM'];
BEGIN
    FOREACH tech_email IN ARRAY tech_emails LOOP
        -- Generate 100 jobs per technician: 2 overdue (day -1), 5 today (day 0), rest upcoming (day 1..12)
        FOR day_offset IN -1..12 LOOP
            FOR job_idx IN 1..CASE WHEN day_offset = -1 THEN 2 WHEN day_offset = 0 THEN 5 ELSE 7 END LOOP
            LOOP
                curr_job_id := 'job-' || LPAD(job_id_counter::text, 4, '0');
                
                INSERT INTO public.jobs (
                    id, assigned_to, customer_name, customer_phone, address,
                    scheduled_date, time_window, appliance, problem_description,
                    status, version, sync_status, updated_at
                ) VALUES (
                    curr_job_id,
                    tech_email,
                    customers[(job_id_counter % array_length(customers, 1)) + 1],
                    '+91 98140 ' || LPAD((10000 + job_id_counter)::text, 5, '0'),
                    streets[(job_id_counter % array_length(streets, 1)) + 1],
                    (CURRENT_DATE + (day_offset || ' days')::interval)::date,
                    windows[(job_idx % array_length(windows, 1)) + 1],
                    appliances[(job_id_counter % array_length(appliances, 1)) + 1],
                    problems[(job_id_counter % array_length(problems, 1)) + 1],
                    CASE WHEN day_offset = 0 AND job_idx = 1 THEN 'on_site'
                         WHEN day_offset = 0 AND job_idx = 2 THEN 'travelling'
                         ELSE 'assigned' END,
                    1,
                    'synced',
                    now()
                ) ON CONFLICT (id) DO NOTHING;

                -- Insert standard checklist items
                INSERT INTO public.job_checklists (id, job_id, title, is_completed, sort_order)
                VALUES 
                    (curr_job_id || '-chk-1', curr_job_id, 'Visual electrical and earth leakage inspection', false, 0),
                    (curr_job_id || '-chk-2', curr_job_id, 'Run diagnostic test cycle and inspect error logs', false, 1),
                    (curr_job_id || '-chk-3', curr_job_id, 'Test components and replace damaged parts', false, 2),
                    (curr_job_id || '-chk-4', curr_job_id, 'Verify functional test cycle with customer', false, 3)
                ON CONFLICT (id) DO NOTHING;

                job_id_counter := job_id_counter + 1;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- DEMO OFFICE CHANGES (Run these in SQL Editor during interview evaluation)
-- ============================================================================

-- SCENARIO A: Office cancels Job 1 while technician is working offline
-- UPDATE public.jobs 
-- SET status = 'cancelled', version = version + 1, updated_at = now() 
-- WHERE id = 'job-0001';

-- SCENARIO B: Office edits problem description & reschedules Job 2
-- UPDATE public.jobs 
-- SET problem_description = 'URGENT: Customer reports unit is overheating and sparking. Rescheduled to 03:00 PM.',
--     time_window = '03:00 - 05:00 PM',
--     version = version + 1, 
--     updated_at = now() 
-- WHERE id = 'job-0002';

-- SCENARIO C: Office reassigns Job 3 from Alex to Sarah
-- UPDATE public.jobs 
-- SET assigned_to = 'sarah@fieldjobs.com', version = version + 1, updated_at = now() 
-- WHERE id = 'job-0003';
