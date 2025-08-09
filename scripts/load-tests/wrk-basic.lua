-- wrk Lua script for basic load testing
local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   requests = 0
   responses = 0
   
   -- Test data
   local users = {
      {username = "wrkuser1", email = "wrk1@example.com", password = "password123"},
      {username = "wrkuser2", email = "wrk2@example.com", password = "password123"},
      {username = "wrkuser3", email = "wrk3@example.com", password = "password123"}
   }
   
   -- Register and login users to get tokens
   tokens = {}
   for i, user in ipairs(users) do
      -- Register user
      local register_body = string.format('{"username":"%s","email":"%s","password":"%s"}', 
                                         user.username, user.email, user.password)
      
      -- For simplicity, we'll use pre-generated tokens in real test
      -- In practice, you'd make HTTP requests here to register/login
      tokens[i] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example.token"
   end
end

function request()
   requests = requests + 1
   
   -- Rotate between different request types
   local request_type = requests % 4
   
   if request_type == 0 then
      -- GET posts
      return wrk.format("GET", "/api/v1/posts")
   elseif request_type == 1 then
      -- GET health check
      return wrk.format("GET", "/health")
   elseif request_type == 2 then
      -- POST create post (with auth)
      local token = tokens[math.random(#tokens)]
      local body = string.format('{"image_url":"https://picsum.photos/800/600?random=%d","caption":"wrk load test %d"}', 
                                math.random(1000), requests)
      local headers = {}
      headers["Content-Type"] = "application/json"
      headers["Authorization"] = "Bearer " .. token
      return wrk.format("POST", "/api/v1/posts", headers, body)
   else
      -- GET metrics
      return wrk.format("GET", "/metrics")
   end
end

function response(status, headers, body)
   responses = responses + 1
   
   if status ~= 200 and status ~= 201 and status ~= 429 then
      print("Unexpected status: " .. status)
   end
end

function done(summary, latency, requests)
   io.write("------------------------------\n")
   io.write("WRK Load Test Results:\n")
   io.write("------------------------------\n")
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests")
      local responses = thread:get("responses")
      local msg = "thread %d made %d requests and got %d responses"
      io.write(msg:format(id, requests, responses) .. "\n")
   end
   
   io.write("Total Requests: " .. summary.requests .. "\n")
   io.write("Total Duration: " .. summary.duration .. "μs\n")
   io.write("Average Latency: " .. latency.mean .. "μs\n")
   io.write("Max Latency: " .. latency.max .. "μs\n")
   io.write("Requests/sec: " .. (summary.requests / (summary.duration / 1000000)) .. "\n")
end