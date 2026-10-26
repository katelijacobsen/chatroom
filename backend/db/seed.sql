-- Dummy data for the chatroom project.
-- Run against the database that holds the chatrooms/users/messages tables (currently "katja").
-- Safe to run more than once: part 1 only adds what is missing, part 2 wipes and refills the data.

BEGIN;

-- ─── Part 1: complete the schema ────────────────────────────────────────────

-- username was created as timestamp; a name needs text. Unique so two people can't share one.
ALTER TABLE users ALTER COLUMN username TYPE varchar(50) USING username::text;
CREATE UNIQUE INDEX IF NOT EXISTS users_username_key ON users (username);

-- Let Postgres generate the uuid so inserts don't have to.
ALTER TABLE users ALTER COLUMN user_uuid SET DEFAULT gen_random_uuid();

-- A message belongs to one room and one sender.
ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS chatroom_id integer NOT NULL REFERENCES chatrooms (id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS user_id     integer NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS content     text    NOT NULL,
    ADD COLUMN IF NOT EXISTS created_at  timestamp NOT NULL DEFAULT now();

-- ─── Part 2: dummy data ─────────────────────────────────────────────────────

-- Empty all three tables and restart the id counters at 1.
TRUNCATE messages, chatrooms, users RESTART IDENTITY CASCADE;

INSERT INTO users (username) VALUES
    ('alice'),   -- id 1
    ('bob'),     -- id 2
    ('charlie'), -- id 3
    ('dana'),    -- id 4
    ('eve'),     -- id 5
    ('frank');   -- id 6

INSERT INTO chatrooms (chatroom_name) VALUES
    ('general'),     -- id 1
    ('random'),      -- id 2
    ('javascript'),  -- id 3
    ('weekend-plans'); -- id 4

INSERT INTO messages (chatroom_id, user_id, content, created_at) VALUES
    -- general
    (1, 1, 'Hi everyone, welcome to the chatroom!',                 now() - interval '3 days 2 hours'),
    (1, 2, 'Hey Alice, glad to be here.',                          now() - interval '3 days 1 hour 55 minutes'),
    (1, 3, 'Hello! Is this where we report bugs?',                 now() - interval '3 days 1 hour 40 minutes'),
    (1, 1, 'Use #javascript for code questions, this is for anything else.', now() - interval '3 days 1 hour 38 minutes'),
    (1, 4, 'Morning all ☀️',                                        now() - interval '1 day 6 hours'),
    (1, 6, 'Good morning Dana!',                                   now() - interval '1 day 5 hours 50 minutes'),
    (1, 5, 'Did anyone see the new release notes?',                now() - interval '2 hours'),
    (1, 2, 'Yes, the dark mode looks great.',                      now() - interval '1 hour 45 minutes'),

    -- random
    (2, 3, 'What is everyone listening to today?',                 now() - interval '2 days 4 hours'),
    (2, 5, 'Lo-fi beats, as always.',                              now() - interval '2 days 3 hours 58 minutes'),
    (2, 6, 'A podcast about the history of the internet.',         now() - interval '2 days 3 hours 30 minutes'),
    (2, 3, 'Send the link please!',                                now() - interval '2 days 3 hours 29 minutes'),
    (2, 4, 'Coffee or tea? Asking for science.',                   now() - interval '5 hours'),
    (2, 1, 'Tea. Always tea.',                                     now() - interval '4 hours 50 minutes'),

    -- javascript
    (3, 2, 'Why does my Express server exit right after starting?', now() - interval '1 day 3 hours'),
    (3, 1, 'You probably forgot app.listen().',                    now() - interval '1 day 2 hours 55 minutes'),
    (3, 2, 'That was it, thanks!',                                 now() - interval '1 day 2 hours 50 minutes'),
    (3, 4, 'What is the difference between == and ===?',           now() - interval '20 hours'),
    (3, 6, '=== also compares the type, so 1 === "1" is false.',   now() - interval '19 hours 45 minutes'),
    (3, 5, 'Anyone using Node''s built-in TypeScript support yet?', now() - interval '30 minutes'),
    (3, 3, 'Yes, node app.ts just works for small projects.',      now() - interval '25 minutes'),

    -- weekend-plans
    (4, 4, 'Hiking on Saturday, who is in?',                       now() - interval '6 hours'),
    (4, 5, 'Me! What time?',                                       now() - interval '5 hours 40 minutes'),
    (4, 4, '9am at the train station.',                            now() - interval '5 hours 30 minutes'),
    (4, 6, 'I will bring snacks 🍫',                               now() - interval '10 minutes');

-- Each room's last activity = its newest message.
UPDATE chatrooms c
SET "chatroom_lastMessageAt" = (SELECT max(m.created_at) FROM messages m WHERE m.chatroom_id = c.id);

COMMIT;
