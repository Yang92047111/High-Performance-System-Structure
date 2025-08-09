-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_messages_post_id ON messages(post_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Sample data for testing
INSERT INTO users (username, email, password_hash) VALUES 
('testuser', 'test@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('alice', 'alice@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

INSERT INTO posts (user_id, image_url, caption) VALUES 
((SELECT id FROM users WHERE username = 'testuser'), 'https://picsum.photos/800/600?random=1', 'Beautiful sunset! 🌅'),
((SELECT id FROM users WHERE username = 'alice'), 'https://picsum.photos/800/600?random=2', 'Coffee time ☕');

INSERT INTO messages (post_id, sender_id, message) VALUES 
((SELECT id FROM posts WHERE caption LIKE '%sunset%'), (SELECT id FROM users WHERE username = 'alice'), 'Amazing photo!'),
((SELECT id FROM posts WHERE caption LIKE '%Coffee%'), (SELECT id FROM users WHERE username = 'testuser'), 'Looks delicious!');