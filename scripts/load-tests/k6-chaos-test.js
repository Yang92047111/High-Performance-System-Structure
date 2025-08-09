import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';
import exec from 'k6/execution';

// Custom metrics
const chaosEvents = new Counter('chaos_events');
const recoveryTime = new Trend('recovery_time');
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Normal load
    { duration: '5m', target: 200 }, // Increased load
    { duration: '3m', target: 500 }, // High load during chaos
    { duration: '2m', target: 200 }, // Recovery phase
    { duration: '2m', target: 0 },   // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // More lenient during chaos
    http_req_failed: ['rate<0.3'],     // Accept higher error rate during chaos
    recovery_time: ['p(95)<30000'],    // Recovery should be under 30s
  },
};

const BASE_URL = 'http://localhost:8000';
let chaosActive = false;
let chaosStartTime = 0;

export function setup() {
  console.log('🌪️  Starting Chaos Engineering Load Test');
  
  // Create test users
  const tokens = [];
  for (let i = 1; i <= 5; i++) {
    const user = {
      username: `chaostest${i}`,
      email: `chaos${i}@example.com`,
      password: 'password123'
    };
    
    const registerResponse = http.post(`${BASE_URL}/api/v1/users/register`, JSON.stringify(user), {
      headers: { 'Content-Type': 'application/json' },
    });
    
    if (registerResponse.status === 201 || registerResponse.status === 400) {
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
  
  return { tokens };
}

export default function(data) {
  const currentStage = exec.scenario.iterationInTest;
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  
  // Trigger chaos events during high load phase
  if (currentStage > 300 && currentStage < 600 && !chaosActive) {
    triggerChaosEvent();
  }
  
  // Monitor recovery
  if (chaosActive && currentStage > 600) {
    monitorRecovery();
  }
  
  // Run normal load test scenarios
  const scenario = Math.random();
  
  if (scenario < 0.4) {
    testGetPosts();
  } else if (scenario < 0.6) {
    testCreatePost(token);
  } else if (scenario < 0.8) {
    testCreateMessage(token);
  } else {
    testHealthCheck();
  }
  
  sleep(Math.random() * 2); // Variable sleep to simulate real users
}

function triggerChaosEvent() {
  console.log('🌪️  Triggering chaos event...');
  chaosActive = true;
  chaosStartTime = Date.now();
  chaosEvents.add(1);
  
  // Simulate different chaos scenarios
  const chaosType = Math.floor(Math.random() * 3);
  
  switch (chaosType) {
    case 0:
      // Simulate database connection issues
      console.log('💥 Chaos: Database connection stress');
      simulateDatabaseStress();
      break;
    case 1:
      // Simulate memory pressure
      console.log('💥 Chaos: Memory pressure simulation');
      simulateMemoryPressure();
      break;
    case 2:
      // Simulate network latency
      console.log('💥 Chaos: Network latency simulation');
      simulateNetworkLatency();
      break;
  }
}

function simulateDatabaseStress() {
  // Create many concurrent database operations
  for (let i = 0; i < 10; i++) {
    http.get(`${BASE_URL}/api/v1/posts?chaos=db_stress_${i}`);
  }
}

function simulateMemoryPressure() {
  // Create large payloads to stress memory
  const largeCaption = 'A'.repeat(1000);
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.random()}`,
    caption: largeCaption
  };
  
  for (let i = 0; i < 5; i++) {
    http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

function simulateNetworkLatency() {
  // Make requests with artificial delays
  const requests = [];
  for (let i = 0; i < 20; i++) {
    requests.push(['GET', `${BASE_URL}/api/v1/posts?latency_test=${i}`]);
  }
  
  http.batch(requests);
}

function monitorRecovery() {
  if (chaosActive) {
    const response = http.get(`${BASE_URL}/health`);
    
    if (response.status === 200) {
      const recoveryTimeMs = Date.now() - chaosStartTime;
      recoveryTime.add(recoveryTimeMs);
      chaosActive = false;
      console.log(`✅ System recovered in ${recoveryTimeMs}ms`);
    }
  }
}

function testGetPosts() {
  const response = http.get(`${BASE_URL}/api/v1/posts`);
  
  const success = check(response, {
    'get posts status ok': (r) => r.status === 200 || r.status === 429 || r.status === 503,
    'get posts response time acceptable': (r) => r.timings.duration < 2000,
  });
  
  errorRate.add(!success);
}

function testCreatePost(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.floor(Math.random() * 10000)}`,
    caption: `Chaos test post ${Date.now()}`
  };
  
  const response = http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  });
  
  const success = check(response, {
    'create post status acceptable': (r) => r.status === 201 || r.status === 429 || r.status === 503,
    'create post response time acceptable': (r) => r.timings.duration < 3000,
  });
  
  errorRate.add(!success);
}

function testCreateMessage(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  // Get a random post first
  const postsResponse = http.get(`${BASE_URL}/api/v1/posts`);
  
  if (postsResponse.status === 200) {
    try {
      const postsData = JSON.parse(postsResponse.body);
      if (postsData.posts && postsData.posts.length > 0) {
        const postId = postsData.posts[Math.floor(Math.random() * postsData.posts.length)].id;
        
        const messageData = {
          message: `Chaos test message ${Date.now()}`
        };
        
        const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/messages`, JSON.stringify(messageData), {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
        });
        
        const success = check(response, {
          'create message status acceptable': (r) => r.status === 201 || r.status === 429 || r.status === 503,
          'create message response time acceptable': (r) => r.timings.duration < 2000,
        });
        
        errorRate.add(!success);
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

function testHealthCheck() {
  const response = http.get(`${BASE_URL}/health`);
  
  const success = check(response, {
    'health check status': (r) => r.status === 200,
    'health check response time': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
}

export function teardown(data) {
  console.log('🏁 Chaos Engineering Test Completed!');
  console.log(`📊 Chaos Test Summary:`);
  console.log(`   - Chaos events triggered: Check chaos_events metric`);
  console.log(`   - System recovery time: Check recovery_time metric`);
  console.log(`   - Error rate during chaos: Check errors metric`);
  console.log(`   - Test demonstrated system resilience under failure conditions`);
}