import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 500 }, // Ramp up to 500 users
    { duration: '10m', target: 500 }, // Stay at 500 users
    { duration: '2m', target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95% of requests must complete below 200ms
    http_req_failed: ['rate<0.1'], // Error rate must be below 10%
    errors: ['rate<0.1'],
  },
};

const BASE_URL = 'http://localhost:8000';

// Test data
const users = [
  { username: 'loadtest1', email: 'loadtest1@example.com', password: 'password123' },
  { username: 'loadtest2', email: 'loadtest2@example.com', password: 'password123' },
  { username: 'loadtest3', email: 'loadtest3@example.com', password: 'password123' },
];

let authTokens = [];

export function setup() {
  console.log('Setting up test users...');
  
  // Register test users
  users.forEach((user, index) => {
    const registerResponse = http.post(`${BASE_URL}/api/v1/users/register`, JSON.stringify(user), {
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (registerResponse.status === 201 || registerResponse.status === 400) {
      // Login to get token
      const loginResponse = http.post(`${BASE_URL}/api/v1/users/login`, JSON.stringify({
        email: user.email,
        password: user.password
      }), {
        headers: { 'Content-Type': 'application/json' },
      });
      
      if (loginResponse.status === 200) {
        const loginData = JSON.parse(loginResponse.body);
        authTokens.push(loginData.token);
        console.log(`User ${index + 1} authenticated successfully`);
      }
    }
  });
  
  return { tokens: authTokens };
}

export default function(data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  
  // Test scenarios with different weights
  const scenario = Math.random();
  
  if (scenario < 0.4) {
    // 40% - Get posts (read-heavy workload)
    testGetPosts();
  } else if (scenario < 0.6) {
    // 20% - Get specific post with messages
    testGetPostWithMessages();
  } else if (scenario < 0.8) {
    // 20% - Create new post
    testCreatePost(token);
  } else {
    // 20% - Create message
    testCreateMessage(token);
  }
  
  sleep(1); // 1 second between requests
}

function testGetPosts() {
  const response = http.get(`${BASE_URL}/api/v1/posts`);
  
  const success = check(response, {
    'get posts status is 200': (r) => r.status === 200,
    'get posts response time < 500ms': (r) => r.timings.duration < 500,
    'get posts has data': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data.posts !== undefined;
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
}

function testGetPostWithMessages() {
  // First get posts to get a valid post ID
  const postsResponse = http.get(`${BASE_URL}/api/v1/posts`);
  
  if (postsResponse.status === 200) {
    try {
      const postsData = JSON.parse(postsResponse.body);
      if (postsData.posts && postsData.posts.length > 0) {
        const postId = postsData.posts[0].id;
        
        // Get specific post
        const postResponse = http.get(`${BASE_URL}/api/v1/posts/${postId}`);
        
        // Get messages for the post
        const messagesResponse = http.get(`${BASE_URL}/api/v1/posts/${postId}/messages`);
        
        const success = check(postResponse, {
          'get post status is 200': (r) => r.status === 200,
          'get post response time < 300ms': (r) => r.timings.duration < 300,
        }) && check(messagesResponse, {
          'get messages status is 200': (r) => r.status === 200,
          'get messages response time < 300ms': (r) => r.timings.duration < 300,
        });
        
        errorRate.add(!success);
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

function testCreatePost(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.floor(Math.random() * 1000)}`,
    caption: `Load test post created at ${new Date().toISOString()} 🚀`
  };
  
  const response = http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  });
  
  const success = check(response, {
    'create post status is 201': (r) => r.status === 201,
    'create post response time < 1000ms': (r) => r.timings.duration < 1000,
    'create post has id': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data.post && data.post.id;
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
}

function testCreateMessage(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  // First get a post to comment on
  const postsResponse = http.get(`${BASE_URL}/api/v1/posts`);
  
  if (postsResponse.status === 200) {
    try {
      const postsData = JSON.parse(postsResponse.body);
      if (postsData.posts && postsData.posts.length > 0) {
        const postId = postsData.posts[Math.floor(Math.random() * postsData.posts.length)].id;
        
        const messageData = {
          message: `Load test message at ${new Date().toISOString()} 💬`
        };
        
        const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/messages`, JSON.stringify(messageData), {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
        });
        
        const success = check(response, {
          'create message status is 201': (r) => r.status === 201,
          'create message response time < 800ms': (r) => r.timings.duration < 800,
        });
        
        errorRate.add(!success);
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

export function teardown(data) {
  console.log('Load test completed!');
  console.log(`Tested with ${data.tokens.length} authenticated users`);
}