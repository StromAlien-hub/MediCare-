   -- ============================================================
--  MediCare+ v2.0  Database Schema (PostgreSQL 14+)
--  Run: psql -U postgres -d medicare_db -f schema.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    phone         VARCHAR(15)  UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role          VARCHAR(20)  DEFAULT 'patient' CHECK (role IN ('patient','doctor','admin','paramedic')),
    avatar_url    TEXT,
    date_of_birth DATE,
    gender        VARCHAR(10),
    blood_group   VARCHAR(5),
    address       TEXT,
    city          VARCHAR(80),
    pincode       VARCHAR(10),
    is_verified   BOOLEAN DEFAULT FALSE,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- DOCTORS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS specializations (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS doctors (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
    specialization_id INT  REFERENCES specializations(id),
    license_number    VARCHAR(50) UNIQUE NOT NULL,
    experience_years  INT DEFAULT 0,
    consultation_fee  NUMERIC(8,2) NOT NULL,
    bio               TEXT,
    hospital_name     VARCHAR(150),
    hospital_address  TEXT,
    rating            NUMERIC(3,2) DEFAULT 0.00,
    total_reviews     INT DEFAULT 0,
    is_available      BOOLEAN DEFAULT TRUE,
    accepts_video     BOOLEAN DEFAULT TRUE,
    accepts_audio     BOOLEAN DEFAULT TRUE,
    accepts_clinic    BOOLEAN DEFAULT TRUE,
    created_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctor_slots (
    id                 SERIAL PRIMARY KEY,
    doctor_id          UUID REFERENCES doctors(id) ON DELETE CASCADE,
    day_of_week        INT CHECK (day_of_week BETWEEN 0 AND 6),
    start_time         TIME NOT NULL,
    end_time           TIME NOT NULL,
    slot_duration_mins INT DEFAULT 30
);

-- ─────────────────────────────────────────
-- APPOINTMENTS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS appointments (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id       UUID REFERENCES users(id),
    doctor_id        UUID REFERENCES doctors(id),
    appointment_date DATE NOT NULL,
    start_time       TIME NOT NULL,
    end_time         TIME NOT NULL,
    consult_type     VARCHAR(20) CHECK (consult_type IN ('video','audio','clinic')),
    status           VARCHAR(20) DEFAULT 'confirmed'
                     CHECK (status IN ('pending','confirmed','completed','cancelled','no_show')),
    symptoms         TEXT,
    notes            TEXT,
    fee_paid         NUMERIC(8,2),
    payment_status   VARCHAR(20) DEFAULT 'pending',
    created_at       TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- PRODUCTS / STORE
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_categories (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS products (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id  INT REFERENCES product_categories(id),
    name         VARCHAR(200) NOT NULL,
    brand        VARCHAR(100),
    description  TEXT,
    composition  TEXT,
    dosage_form  VARCHAR(50),
    strength     VARCHAR(50),
    pack_size    VARCHAR(50),
    price        NUMERIC(8,2) NOT NULL,
    mrp          NUMERIC(8,2),
    stock_qty    INT DEFAULT 100,
    requires_rx  BOOLEAN DEFAULT FALSE,
    is_otc       BOOLEAN DEFAULT TRUE,
    manufacturer VARCHAR(150),
    image_url    TEXT,
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS medicine_indications (
    id          SERIAL PRIMARY KEY,
    product_id  UUID REFERENCES products(id) ON DELETE CASCADE,
    disease     VARCHAR(200) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS medicine_side_effects (
    id          SERIAL PRIMARY KEY,
    product_id  UUID REFERENCES products(id) ON DELETE CASCADE,
    effect      VARCHAR(200) NOT NULL,
    severity    VARCHAR(20) CHECK (severity IN ('mild','moderate','severe'))
);

-- ─────────────────────────────────────────
-- ORDERS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID REFERENCES users(id),
    total_amount     NUMERIC(10,2) NOT NULL,
    discount         NUMERIC(8,2) DEFAULT 0,
    delivery_fee     NUMERIC(6,2) DEFAULT 0,
    status           VARCHAR(30) DEFAULT 'confirmed'
                     CHECK (status IN ('confirmed','packed','shipped','delivered','cancelled')),
    delivery_address TEXT,
    delivery_city    VARCHAR(80),
    delivery_pincode VARCHAR(10),
    payment_method   VARCHAR(30),
    payment_status   VARCHAR(20) DEFAULT 'pending',
    expected_delivery TIMESTAMP,
    delivered_at     TIMESTAMP,
    created_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id          SERIAL PRIMARY KEY,
    order_id    UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id  UUID REFERENCES products(id),
    quantity    INT NOT NULL,
    unit_price  NUMERIC(8,2) NOT NULL,
    total_price NUMERIC(8,2) NOT NULL
);

-- ─────────────────────────────────────────
-- AMBULANCE / EMERGENCY
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ambulances (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_number VARCHAR(20) UNIQUE NOT NULL,
    type           VARCHAR(30) DEFAULT 'advanced' CHECK (type IN ('basic','advanced','icu')),
    driver_name    VARCHAR(100),
    driver_phone   VARCHAR(15),
    paramedic_name VARCHAR(100),
    current_lat    NUMERIC(10,7) DEFAULT 17.6599,
    current_lng    NUMERIC(10,7) DEFAULT 75.9064,
    status         VARCHAR(20) DEFAULT 'available'
                   CHECK (status IN ('available','dispatched','en_route','at_hospital')),
    created_at     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_requests (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID REFERENCES users(id),
    patient_lat    NUMERIC(10,7) NOT NULL,
    patient_lng    NUMERIC(10,7) NOT NULL,
    patient_address TEXT,
    emergency_type VARCHAR(50),
    ambulance_id   UUID REFERENCES ambulances(id),
    status         VARCHAR(30) DEFAULT 'requested'
                   CHECK (status IN ('requested','dispatched','arrived','hospital_reached','closed')),
    eta_minutes    INT,
    notes          TEXT,
    requested_at   TIMESTAMP DEFAULT NOW(),
    arrived_at     TIMESTAMP,
    closed_at      TIMESTAMP
);

-- ─────────────────────────────────────────
-- HEALTH RECORDS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prescriptions (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID REFERENCES appointments(id),
    doctor_id      UUID REFERENCES doctors(id),
    patient_id     UUID REFERENCES users(id),
    diagnosis      TEXT,
    notes          TEXT,
    follow_up_date DATE,
    created_at     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS prescription_medicines (
    id              SERIAL PRIMARY KEY,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE CASCADE,
    product_id      UUID REFERENCES products(id),
    medicine_name   VARCHAR(200),
    dosage          VARCHAR(100),
    frequency       VARCHAR(100),
    duration        VARCHAR(50),
    instructions    TEXT
);

CREATE TABLE IF NOT EXISTS lab_reports (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES users(id),
    report_name VARCHAR(200),
    report_url  TEXT,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- AI CHAT
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID REFERENCES users(id),
    started_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id         SERIAL PRIMARY KEY,
    session_id UUID REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    role       VARCHAR(10) CHECK (role IN ('user','assistant')),
    content    TEXT NOT NULL,
    sent_at    TIMESTAMP DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- REVIEWS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id  UUID REFERENCES doctors(id),
    patient_id UUID REFERENCES users(id),
    rating     INT CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- PERFORMANCE INDEXES
-- ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appts_patient  ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appts_doctor   ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appts_date     ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_orders_user    ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_products_cat   ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_name  ON products(name);
CREATE INDEX IF NOT EXISTS idx_emergency_user ON emergency_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_session   ON ai_chat_messages(session_id);

-- ─────────────────────────────────────────
-- SEED DATA
-- ─────────────────────────────────────────
INSERT INTO specializations (name) VALUES
  ('General Physician'),('Cardiologist'),('Dermatologist'),
  ('Neurologist'),('Pediatrician'),('Orthopedic'),
  ('Gynecologist'),('Psychiatrist'),('ENT Specialist'),
  ('Ophthalmologist'),('Diabetologist'),('Pulmonologist')
ON CONFLICT DO NOTHING;

INSERT INTO product_categories (name, icon) VALUES
  ('Pain Relief','💊'),('Antibiotics','💉'),('Vitamins & Supplements','🌞'),
  ('Diabetes Care','🩸'),('Heart & BP','❤️'),('Medical Equipment','🩺'),
  ('Cold & Cough','🤧'),('Skin Care','🧴'),('Digestive Health','🫀'),
  ('Ayurvedic','🌿')
ON CONFLICT DO NOTHING;

-- Demo user (password = demo123)
INSERT INTO users (name,email,phone,password_hash,role,is_verified) VALUES
  ('Demo User','demo@medicare.com','9999999999',
   '$2a$12$yw3ROzA9oT7Ry4hTnFrQsO/p8RGsqopjjqjIq4TdS0zz8J.pF1tay',
   'patient', true)
ON CONFLICT DO NOTHING;

-- Sample ambulances near Solapur
INSERT INTO ambulances (vehicle_number, type, driver_name, driver_phone, paramedic_name, current_lat, current_lng) VALUES
  ('MH-13-AB-1234','advanced','Ramesh Kumar','9876500001','Dr. Kavita Rao', 17.6699, 75.9100),
  ('MH-13-CD-5678','basic',   'Suresh Patil','9876500002','Nurse Priya',    17.6500, 75.8900),
  ('MH-13-EF-9012','icu',     'Mahesh Jadhav','9876500003','Dr. Sanjay',    17.6800, 75.9300)
ON CONFLICT DO NOTHING;

-- Sample products
WITH cats AS (SELECT id, name FROM product_categories)
INSERT INTO products (name,brand,description,price,mrp,stock_qty,requires_rx,dosage_form,strength,pack_size,category_id,manufacturer) VALUES
  ('Paracetamol 500mg',   'Crocin',    'Fever, headache, body pain relief',              22,   28,  500, false,'tablet',  '500mg',    'Strip of 10', (SELECT id FROM cats WHERE name='Pain Relief'),            'GSK'),
  ('Ibuprofen 400mg',     'Brufen',    'Pain, fever, inflammation relief',               35,   44,  400, false,'tablet',  '400mg',    'Strip of 10', (SELECT id FROM cats WHERE name='Pain Relief'),            'Abbott'),
  ('Azithromycin 500mg',  'Zithromax', 'Bacterial respiratory & skin infections',        89,  110,  200, true, 'tablet',  '500mg',    'Strip of 3',  (SELECT id FROM cats WHERE name='Antibiotics'),            'Pfizer'),
  ('Amoxicillin 500mg',   'Mox',       'Broad-spectrum antibiotic',                      55,   68,  250, true, 'capsule', '500mg',    'Strip of 10', (SELECT id FROM cats WHERE name='Antibiotics'),            'Ranbaxy'),
  ('Vitamin D3 1000IU',   'HealthVit', 'Bone strength and immunity health',             349,  420,  150, false,'softgel', '1000 IU',  '60 caps',     (SELECT id FROM cats WHERE name='Vitamins & Supplements'),  'HealthVit'),
  ('Vitamin C 500mg',     'Limcee',    'Immunity booster, antioxidant',                  85,  100,  300, false,'tablet',  '500mg',    'Strip of 15', (SELECT id FROM cats WHERE name='Vitamins & Supplements'),  'Abbott'),
  ('Metformin 500mg',     'Glycomet',  'Type 2 diabetes blood sugar control',            45,   55,  300, true, 'tablet',  '500mg',    'Strip of 10', (SELECT id FROM cats WHERE name='Diabetes Care'),          'USV'),
  ('Glimepiride 2mg',     'Amaryl',    'Type 2 diabetes — stimulates insulin',           72,   88,  200, true, 'tablet',  '2mg',      'Strip of 10', (SELECT id FROM cats WHERE name='Diabetes Care'),          'Sanofi'),
  ('Amlodipine 5mg',      'Amlong',    'Hypertension and chest angina',                  38,   48,  250, true, 'tablet',  '5mg',      'Strip of 10', (SELECT id FROM cats WHERE name='Heart & BP'),             'Micro Labs'),
  ('Atorvastatin 10mg',   'Lipitor',   'Cholesterol management',                         55,   68,  200, true, 'tablet',  '10mg',     'Strip of 10', (SELECT id FROM cats WHERE name='Heart & BP'),             'Pfizer'),
  ('Digital BP Monitor',  'Omron',     'Automatic upper arm blood pressure monitor',   1299, 1599,   80, false,'device',  NULL,       '1 unit',      (SELECT id FROM cats WHERE name='Medical Equipment'),       'Omron'),
  ('Glucometer Kit',      'Accu-Chek', 'Blood sugar monitor with 25 test strips',       799,  999,   60, false,'device',  NULL,       '1 kit',       (SELECT id FROM cats WHERE name='Medical Equipment'),       'Roche'),
  ('Pulse Oximeter',      'Dr. Trust', 'SpO2 and heart rate fingertip monitor',          599,  799,  120, false,'device',  NULL,       '1 unit',      (SELECT id FROM cats WHERE name='Medical Equipment'),       'Dr. Trust'),
  ('Nebulizer Mesh',      'Omron',     'Portable mesh nebulizer for asthma therapy',   2499, 2999,   45, false,'device',  NULL,       '1 unit',      (SELECT id FROM cats WHERE name='Medical Equipment'),       'Omron'),
  ('Cetirizine 10mg',     'Alerid',    'Antihistamine for allergy and cold',              38,   50,  400, false,'tablet',  '10mg',     'Strip of 10', (SELECT id FROM cats WHERE name='Cold & Cough'),           'UCB'),
  ('Dextromethorphan 15mg','Alex',     'Dry cough suppressant syrup',                    82,  100,  180, false,'syrup',   '15mg/5ml', '100ml',       (SELECT id FROM cats WHERE name='Cold & Cough'),           'Glenmark'),
  ('Ashwagandha Extract', 'Himalaya',  'Stress relief and energy supplement',           299,  350,  200, false,'capsule', '300mg',    '60 caps',     (SELECT id FROM cats WHERE name='Ayurvedic'),               'Himalaya'),
  ('Triphala Churna',     'Patanjali', 'Digestive health and detox',                     85,  100,  300, false,'powder',  NULL,       '200g',        (SELECT id FROM cats WHERE name='Digestive Health'),        'Patanjali')
ON CONFLICT DO NOTHING;

-- Medicine → Disease indications
INSERT INTO medicine_indications (product_id, disease, description)
SELECT p.id, ind.disease, ind.desc FROM products p,
  (VALUES
    ('Paracetamol 500mg',  'Fever',     'Reduces body temperature effectively'),
    ('Paracetamol 500mg',  'Headache',  'Relieves mild to moderate headaches'),
    ('Paracetamol 500mg',  'Body Pain', 'Relieves muscle aches and pain'),
    ('Ibuprofen 400mg',    'Arthritis', 'Reduces joint inflammation and pain'),
    ('Ibuprofen 400mg',    'Fever',     'Also reduces fever along with pain'),
    ('Azithromycin 500mg', 'Pneumonia', 'Community-acquired pneumonia treatment'),
    ('Azithromycin 500mg', 'Typhoid',   'Used in typhoid treatment regimens'),
    ('Metformin 500mg',    'Type 2 Diabetes', 'First-line oral diabetes medication'),
    ('Glimepiride 2mg',    'Type 2 Diabetes', 'Sulfonylurea for diabetes management'),
    ('Amlodipine 5mg',     'Hypertension',    'Controls high blood pressure'),
    ('Amlodipine 5mg',     'Angina',          'Prevents chest pain episodes'),
    ('Atorvastatin 10mg',  'High Cholesterol','Reduces LDL cholesterol'),
    ('Cetirizine 10mg',    'Allergic Rhinitis','Relieves sneezing and runny nose'),
    ('Cetirizine 10mg',    'Urticaria',        'Treats skin hives and itching')
  ) AS ind(name, disease, desc)
WHERE p.name = ind.name
ON CONFLICT DO NOTHING;

COMMIT;
SELECT 'MediCare+ schema created successfully ✅' AS status;
