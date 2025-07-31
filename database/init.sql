CREATE TABLE chat_logs (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    chat_text TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO chat_logs (customer_name, chat_text) VALUES
('John Doe', 'Hi, I would like to schedule an appointment for this Friday at 2pm.'),
('Jane Smith', 'I need to reschedule my appointment to next Monday at 10am.'),
('Peter Jones', 'Can I book a meeting for tomorrow at 3pm?'),
('Mary Johnson', 'I want to confirm my appointment for Wednesday at 11am.'),
('David Williams', 'Is there any availability on Thursday afternoon?');
