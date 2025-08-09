import ws from 'k6/ws';
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';

// Custom metrics
const wsConnectionErrors = new Rate('ws_connection_errors');
const wsMessagesSent = new Counter('ws_messages_sent');
const wsMessagesReceived = new Counter('ws_messages_received');

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Start with 10 WebSocket connections
    { duration: '1m', target: 50 },   // Ramp up to 50
    { duration: '2m', target: 100 },  // 100 concurrent WebSocket connections
    { duration: '2m', target: 200 },  // 200 concurrent connections
    { duration: '3m', target: 500 },  // Stress test with 500 connections
    { duration: '1m', target: 0 },    // Ramp down
  ],
  thresholds: {
    ws_connection_errors: ['rate<0.1'], // Less than 10% connection errors
    ws_connecting: ['p(95)<1000'],      // 95% of connections under 1s
  },
};

const BASE_URL = 'http://localhost:8000';
const WS_URL = 'ws://localhost:8000/ws';

export function setup() {
  console.log('🔌 Setting up WebSocket load test...');
  
  // Create test users and get tokens
  const tokens = [];
  
  for (let i = 1; i <= 20; i++) {
    const user = {
      username: `wstest${i}`,
      email: `wstest${i}@example.com`,
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
  
  console.log(`✅ Created ${tokens.length} WebSocket test users`);
  return { tokens };
}

export default function(data) {
  const token = data.tokens[Math.floor(Math.random() * data.tokens.length)];
  
  if (!token) {
    wsConnectionErrors.add(1);
    return;
  }
  
  // Test WebSocket connection with authentication
  const wsUrl = `${WS_URL}?token=${token}`;
  
  const response = ws.connect(wsUrl, {}, function (socket) {
    let messagesReceived = 0;
    let messagesSent = 0;
    
    socket.on('open', function open() {
      console.log(`WebSocket connection opened for VU ${__VU}`);
      
      // Send periodic messages to test real-time functionality
      const interval = setInterval(() => {
        if (socket.readyState === 1) { // WebSocket.OPEN
          const message = {
            type: 'test_message',
            content: `Load test message from VU ${__VU} at ${Date.now()}`,
            timestamp: Date.now()
          };
          
          socket.send(JSON.stringify(message));
          messagesSent++;
          wsMessagesSent.add(1);
        }
      }, 2000); // Send message every 2 seconds
      
      // Keep connection alive for test duration
      setTimeout(() => {
        clearInterval(interval);
        socket.close();
      }, 30000); // Keep connection for 30 seconds
    });
    
    socket.on('message', function (message) {
      try {
        const data = JSON.parse(message);
        console.log(`Received message: ${data.type}`);
        messagesReceived++;
        wsMessagesReceived.add(1);
      } catch (e) {
        console.log(`Received non-JSON message: ${message}`);
      }
    });
    
    socket.on('close', function close() {
      console.log(`WebSocket closed for VU ${__VU}. Sent: ${messagesSent}, Received: ${messagesReceived}`);
    });
    
    socket.on('error', function (e) {
      console.log(`WebSocket error for VU ${__VU}: ${e.error()}`);
      wsConnectionErrors.add(1);
    });
  });
  
  check(response, {
    'WebSocket connection successful': (r) => r && r.status === 101,
  });
  
  if (!response || response.status !== 101) {
    wsConnectionErrors.add(1);
  }
  
  sleep(1);
}

export function teardown(data) {
  console.log('🏁 WebSocket load test completed!');
  console.log(`📊 WebSocket Test Summary:`);
  console.log(`   - Peak concurrent connections: 500`);
  console.log(`   - Test users: ${data.tokens.length}`);
  console.log(`   - Check custom metrics for message counts`);
}