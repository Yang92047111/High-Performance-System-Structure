import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics for endurance testing
const errorRate = new Rate('errors');
const memoryLeakIndicator = new Trend('response_time_trend');
const resourceExhaustion = new Counter('resource_exhaustion_events');

export const options = {
  stages: [
    { duration: '5m', target: 200 },   // Ramp up
    { duration: '60m', target: 200 },  // Sustained load for 1 hour
    { duration: '5m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'],  // Should maintain performance
    http_req_failed: ['rate<0.02'],    // Very low error rate for endurance
    response_time_trend: ['p(95)<400'], // Monitor for degradation
  },
};

const BASE_URL = 'http://localhost:8000';
let testStartTime = Date.now();
let responseTimeBaseline = 0;
let baselineSet = false;

export function setup() {
  console.log('🏃‍♂️ Starting Endurance Test - 1 Hour Sustained Load');
  console.log('This test will monitor for:');
  console.log('  - Memory leaks (increasing response times)');
  console.log('  - Resource exhaustion');
  console.log('  - Connection pool issues');
  console.log('  - Cache performance degradation');
  
  // Create test users for endurance test
  const tokens = [];
  for (let i = 1; i <= 50; i++) {
    const user = {
      username: `endurancetest${i}`,
      email: `endurance${i}@example.com`,
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
  
  console.log(`✅ Created ${tokens.length} users for endurance testing`);
  return { tokens };
}

export default function(data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  const testDurationMinutes = (Date.now() - testStartTime) / (1000 * 60);
  
  // Realistic user behavior patterns over time
  const scenario = Math.random();
  
  if (scenario < 0.5) {
    // 50% - Read operations (browsing)
    const responseTime = testReadOperations();
    monitorPerformanceDegradation(responseTime);
  } else if (scenario < 0.7) {
    // 20% - Write operations (posting)
    testWriteOperations(token);
  } else if (scenario < 0.9) {
    // 20% - Interactive operations (messaging)
    testInteractiveOperations(token);
  } else {
    // 10% - System health checks
    testSystemHealth();
  }
  
  // Log progress every 10 minutes
  if (Math.floor(testDurationMinutes) % 10 === 0 && testDurationMinutes > 0) {
    console.log(`⏱️  Endurance test running for ${Math.floor(testDurationMinutes)} minutes`);
  }
  
  // Simulate realistic user think time
  sleep(Math.random() * 3 + 1); // 1-4 seconds
}

function testReadOperations() {
  const startTime = Date.now();
  
  // Test various read operations
  const operations = [
    () => http.get(`${BASE_URL}/api/v1/posts`),
    () => http.get(`${BASE_URL}/health`),
    () => http.get(`${BASE_URL}/metrics`),
  ];
  
  const operation = operations[Math.floor(Math.random() * operations.length)];
  const response = operation();
  
  const responseTime = Date.now() - startTime;
  
  const success = check(response, {
    'read operation status': (r) => r.status === 200,
    'read operation response time': (r) => r.timings.duration < 1000,
  });
  
  if (!success) {
    errorRate.add(1);
  }
  
  return responseTime;
}

function testWriteOperations(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.floor(Math.random() * 10000)}`,
    caption: `Endurance test post ${Date.now()} - Testing system stability over time`
  };
  
  const response = http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  });
  
  const success = check(response, {
    'write operation status': (r) => r.status === 201,
    'write operation response time': (r) => r.timings.duration < 2000,
  });
  
  if (!success) {
    errorRate.add(1);
    
    // Check for resource exhaustion indicators
    if (response.status === 503 || response.status === 500) {
      resourceExhaustion.add(1);
    }
  }
}

function testInteractiveOperations(token) {
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
        
        // Create a message
        const messageData = {
          message: `Endurance test message ${Date.now()} - Long running test`
        };
        
        const messageResponse = http.post(`${BASE_URL}/api/v1/posts/${postId}/messages`, JSON.stringify(messageData), {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
        });
        
        // Get messages to test read after write
        const getMessagesResponse = http.get(`${BASE_URL}/api/v1/posts/${postId}/messages`);
        
        const success = check(messageResponse, {
          'interactive create message status': (r) => r.status === 201,
          'interactive create message time': (r) => r.timings.duration < 1500,
        }) && check(getMessagesResponse, {
          'interactive get messages status': (r) => r.status === 200,
          'interactive get messages time': (r) => r.timings.duration < 1000,
        });
        
        if (!success) {
          errorRate.add(1);
        }
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

function testSystemHealth() {
  // Test multiple health indicators
  const healthResponse = http.get(`${BASE_URL}/health`);
  const metricsResponse = http.get(`${BASE_URL}/metrics`);
  
  const success = check(healthResponse, {
    'health check status': (r) => r.status === 200,
    'health check response time': (r) => r.timings.duration < 500,
  }) && check(metricsResponse, {
    'metrics endpoint status': (r) => r.status === 200,
    'metrics endpoint response time': (r) => r.timings.duration < 1000,
  });
  
  if (!success) {
    errorRate.add(1);
  }
}

function monitorPerformanceDegradation(responseTime) {
  memoryLeakIndicator.add(responseTime);
  
  // Set baseline in first 5 minutes
  if (!baselineSet && (Date.now() - testStartTime) > 5 * 60 * 1000) {
    responseTimeBaseline = responseTime;
    baselineSet = true;
    console.log(`📊 Performance baseline set: ${responseTimeBaseline}ms`);
  }
  
  // Check for significant performance degradation (potential memory leak)
  if (baselineSet && responseTime > responseTimeBaseline * 2) {
    console.log(`⚠️  Performance degradation detected: ${responseTime}ms vs baseline ${responseTimeBaseline}ms`);
    resourceExhaustion.add(1);
  }
}

export function teardown(data) {
  const testDurationHours = (Date.now() - testStartTime) / (1000 * 60 * 60);
  
  console.log('🏃‍♂️ Endurance Test Completed!');
  console.log(`📊 Endurance Test Summary:`);
  console.log(`   - Test duration: ${testDurationHours.toFixed(2)} hours`);
  console.log(`   - Sustained load: 200 concurrent users`);
  console.log(`   - Test users: ${data.tokens.length}`);
  console.log(`   - Performance baseline: ${responseTimeBaseline}ms`);
  console.log(`   - Check metrics for:`);
  console.log(`     * Memory leaks (response_time_trend)`);
  console.log(`     * Resource exhaustion (resource_exhaustion_events)`);
  console.log(`     * Error rate stability (errors)`);
  console.log(`     * System stability over time`);
}