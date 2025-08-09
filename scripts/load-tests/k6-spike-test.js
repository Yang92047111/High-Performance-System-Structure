import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const spikeRecovery = new Counter('spike_recovery_events');

export const options = {
  stages: [
    { duration: '1m', target: 100 },   // Normal load
    { duration: '30s', target: 2000 }, // Sudden spike!
    { duration: '1m', target: 2000 },  // Sustain spike
    { duration: '30s', target: 100 },  // Quick drop
    { duration: '2m', target: 100 },   // Recovery monitoring
    { duration: '30s', target: 0 },    // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // Lenient during spike
    http_req_failed: ['rate<0.5'],     // Accept high error rate during spike
    errors: ['rate<0.5'],
  },
};

const BASE_URL = 'http://localhost:8000';

export function setup() {
  console.log('⚡ Starting Spike Load Test - Sudden Traffic Surge');
  
  // Create test users for spike test
  const tokens = [];
  for (let i = 1; i <= 20; i++) {
    const user = {
      username: `spiketest${i}`,
      email: `spike${i}@example.com`,
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
  
  console.log(`✅ Created ${tokens.length} users for spike testing`);
  return { tokens };
}

export default function(data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  
  // During spike, simulate viral content behavior
  const scenario = Math.random();
  
  if (scenario < 0.6) {
    // 60% - Heavy read traffic (viral post viewing)
    rapidFireReads();
  } else if (scenario < 0.8) {
    // 20% - Rapid post creation (everyone posting about the viral event)
    spikePostCreation(token);
  } else {
    // 20% - Message flooding (comments on viral posts)
    messageFlood(token);
  }
  
  // Minimal sleep during spike to simulate real traffic surge
  sleep(Math.random() * 0.1);
}

function rapidFireReads() {
  // Simulate users rapidly refreshing to see viral content
  const requests = [];
  for (let i = 0; i < 5; i++) {
    requests.push(['GET', `${BASE_URL}/api/v1/posts`]);
  }
  
  const responses = http.batch(requests);
  
  responses.forEach((response, index) => {
    const success = check(response, {
      [`rapid read ${index + 1} status`]: (r) => r.status === 200 || r.status === 429,
      [`rapid read ${index + 1} time`]: (r) => r.timings.duration < 3000,
    });
    
    if (!success) {
      errorRate.add(1);
    }
    
    // Check if system is recovering from spike
    if (response.status === 200 && response.timings.duration < 500) {
      spikeRecovery.add(1);
    }
  });
}

function spikePostCreation(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  // Simulate everyone posting about the viral event
  const viralTopics = [
    'Breaking news!',
    'Can you believe this?',
    'This is trending everywhere!',
    'Everyone needs to see this!',
    'Going viral right now!'
  ];
  
  const postData = {
    image_url: `https://picsum.photos/800/600?random=${Math.floor(Math.random() * 100)}`,
    caption: `${viralTopics[Math.floor(Math.random() * viralTopics.length)]} #viral #trending ${Date.now()}`
  };
  
  const response = http.post(`${BASE_URL}/api/v1/posts`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  });
  
  const success = check(response, {
    'spike post creation status': (r) => r.status === 201 || r.status === 429 || r.status === 503,
    'spike post creation time': (r) => r.timings.duration < 5000,
  });
  
  if (!success) {
    errorRate.add(1);
  }
}

function messageFlood(token) {
  if (!token) {
    errorRate.add(true);
    return;
  }
  
  // Get posts to comment on
  const postsResponse = http.get(`${BASE_URL}/api/v1/posts`);
  
  if (postsResponse.status === 200) {
    try {
      const postsData = JSON.parse(postsResponse.body);
      if (postsData.posts && postsData.posts.length > 0) {
        // Pick a random post (simulating viral post getting all the comments)
        const postId = postsData.posts[0].id; // Everyone comments on the first (viral) post
        
        // Create multiple rapid comments
        const comments = [
          'OMG this is amazing!',
          'I can\'t believe this!',
          'Sharing this everywhere!',
          'This needs to go viral!',
          'Everyone look at this!'
        ];
        
        for (let i = 0; i < 3; i++) {
          const messageData = {
            message: `${comments[Math.floor(Math.random() * comments.length)]} ${Date.now()}`
          };
          
          const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/messages`, JSON.stringify(messageData), {
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
          });
          
          const success = check(response, {
            [`message flood ${i + 1} status`]: (r) => r.status === 201 || r.status === 429 || r.status === 503,
            [`message flood ${i + 1} time`]: (r) => r.timings.duration < 3000,
          });
          
          if (!success) {
            errorRate.add(1);
          }
        }
      }
    } catch (e) {
      errorRate.add(true);
    }
  }
}

export function teardown(data) {
  console.log('⚡ Spike Load Test Completed!');
  console.log(`📊 Spike Test Summary:`);
  console.log(`   - Peak load: 2000 concurrent users`);
  console.log(`   - Spike duration: 1.5 minutes`);
  console.log(`   - Recovery monitoring: 2 minutes`);
  console.log(`   - Test users: ${data.tokens.length}`);
  console.log(`   - Simulated viral content scenario`);
  console.log(`   - Check metrics for system behavior during traffic surge`);
}