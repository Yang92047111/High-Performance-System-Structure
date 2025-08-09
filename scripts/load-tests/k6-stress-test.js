import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const successfulRequests = new Counter('successful_requests');

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Warm up
    { duration: '2m', target: 100 },  // Normal load
    { duration: '2m', target: 300 },  // High load
    { duration: '3m', target: 500 },  // Stress load
    { duration: '3m', target: 800 },  // Heavy stress
    { duration: '5m', target: 1000 }, // Peak stress - 1000 concurrent users
    { duration: '3m', target: 1200 }, // Breaking point test
    { duration: '2m', target: 0 },    // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.2'],    // Error rate under 20% (more lenient for stress test)
    errors: ['rate<0.2'],
  },
};

const BASE_URL = 'http://localhost:8000';

export function setup() {
  console.log('🚀 Starting STRESS TEST - Testing system limits');
  
  // Create multiple test users for stress testing
  const users = [];
  const tokens = [];
  
  for (let i = 1; i <= 10; i++) {
    const user = {
      username: `stresstest${i}`,
      email: `stresstest${i}@example.com`,
      password: 'password123'
    };
    
    // Register user
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
        tokens.push(loginData.token);
      }
    }
  }
  
  console.log(`✅ Created ${tokens.length} test users for stress testing`);
  return { tokens };
}

export default function(data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  
  // Aggressive test scenarios
  const scenario = Math.random();
  
  if (scenario < 0.5) {
    // 50% - Rapid fire GET requests (cache stress test)
    rapidFireGetPosts();
  } else if (scenario < 0.7) {
    // 20% - Concurrent post creation
    stressCreatePost(token);
  } else if (scenario < 0.9) {
    // 20% - Message spam test
    stressCreateMessages(token);
  } else {
    // 10% - Mixed operations
    mixedOperations(token);
  }
  
  // Reduced sleep for higher load
  sleep(Math.random() * 0.5); // 0-500ms between requests
}

function rapidFireGetPosts() {
  // Make multiple rapid requests to test caching and rate limiting
  for (let i = 0; i < 3; i++) {
    const response = http.get(`${BASE_URL}/api/v1/posts`);
    
    const success = check(response, {
      [`rapid fire ${i+1} status ok`]: (r) => r.status === 200 || r.status === 429, // Accept rate limiting
      [`rapid fire ${i+1} response time`]: (r) => r.timings.duration < 1000,
    });
    
    if (success && response.status === 200) {
      successfulRequests.add(1);
    }
    
    errorRate.add(!success);
  }
}

function stressCreatePost(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.floor(Math.random() * 10000)}`,
    caption: `STRESS TEST: High load post ${__VU}-${__ITER} at ${Date.now()}`
  };
  
  const response = http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  });
  
  const success = check(response, {
    'stress create post status': (r) => r.status === 201 || r.status === 429, // Accept rate limiting
    'stress create post time': (r) => r.timings.duration < 2000,
  });
  
  if (success && response.status === 201) {
    successfulRequests.add(1);
  }
  
  errorRate.add(!success);
}

function stressCreateMessages(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  // Get posts first
  const postsResponse = http.get(`${BASE_URL}/api/v1/posts`);
  
  if (postsResponse.status === 200) {
    try {
      const postsData = JSON.parse(postsResponse.body);
      if (postsData.posts && postsData.posts.length > 0) {
        const postId = postsData.posts[Math.floor(Math.random() * postsData.posts.length)].id;
        
        // Create multiple messages rapidly
        for (let i = 0; i < 2; i++) {
          const messageData = {
            message: `STRESS MSG ${__VU}-${__ITER}-${i}: ${Date.now()}`
          };
          
          const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/messages`, JSON.stringify(messageData), {
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
          });
          
          const success = check(response, {
            [`stress message ${i+1} status`]: (r) => r.status === 201 || r.status === 429,
            [`stress message ${i+1} time`]: (r) => r.timings.duration < 1500,
          });
          
          if (success && response.status === 201) {
            successfulRequests.add(1);
          }
          
          errorRate.add(!success);
        }
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

function mixedOperations(token) {
  // Simulate real user behavior under stress
  const operations = [
    () => http.get(`${BASE_URL}/api/v1/posts`),
    () => http.get(`${BASE_URL}/health`),
    () => http.get(`${BASE_URL}/metrics`),
  ];
  
  operations.forEach((op, index) => {
    const response = op();
    const success = check(response, {
      [`mixed op ${index+1} status`]: (r) => r.status < 500, // Accept 4xx but not 5xx
    });
    
    if (success) {
      successfulRequests.add(1);
    }
    
    errorRate.add(!success);
  });
}

export function teardown(data) {
  console.log('🏁 STRESS TEST COMPLETED!');
  console.log(`📊 Test Summary:`);
  console.log(`   - Peak concurrent users: 1200`);
  console.log(`   - Test users created: ${data.tokens.length}`);
  console.log(`   - Check metrics for detailed results`);
}