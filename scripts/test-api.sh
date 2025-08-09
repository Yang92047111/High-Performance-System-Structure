#!/bin/bash

API_BASE="http://localhost:8000/api/v1"

echo "🧪 Testing Social Media API"

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$API_BASE/../health" | jq '.'

echo -e "\n2. Testing user registration..."
curl -s -X POST "$API_BASE/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser123",
    "email": "test123@example.com",
    "password": "password123"
  }' | jq '.'

echo -e "\n3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test123@example.com",
    "password": "password123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'

echo -e "\n4. Testing post creation..."
curl -s -X POST "$API_BASE/posts" \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://picsum.photos/800/600?random=3",
    "caption": "Test post from API script! 🚀"
  }' | jq '.'

echo -e "\n5. Testing get all posts..."
POSTS_RESPONSE=$(curl -s "$API_BASE/posts")
echo "$POSTS_RESPONSE" | jq '.'

# Extract first post ID for message testing
POST_ID=$(echo "$POSTS_RESPONSE" | jq -r '.posts[0].id // empty')

if [ ! -z "$POST_ID" ]; then
  echo -e "\n6. Testing message creation on post $POST_ID..."
  curl -s -X POST "$API_BASE/posts/$POST_ID/messages" \
    -H "Content-Type: application/json" \
    -d '{
      "message": "Great post! 👍"
    }' | jq '.'

  echo -e "\n7. Testing get messages for post $POST_ID..."
  curl -s "$API_BASE/posts/$POST_ID/messages" | jq '.'
fi

echo -e "\n✅ API testing complete!"