-- wrk Lua script for stress testing
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
   errors = 0
   
   -- Simulate multiple users
   math.randomseed(os.time())
end

function request()
   requests = requests + 1
   
   -- High frequency mixed requests for stress testing
   local request_type = math.random(10)
   
   if request_type <= 5 then
      -- 50% - Rapid GET requests to test caching
      return wrk.format("GET", "/api/v1/posts")
   elseif request_type <= 7 then
      -- 20% - Health checks
      return wrk.format("GET", "/health")
   elseif request_type <= 8 then
      -- 10% - Metrics endpoint
      return wrk.format("GET", "/metrics")
   else
      -- 20% - Random post requests
      local post_id = math.random(100) -- Assume we have posts with IDs 1-100
      return wrk.format("GET", "/api/v1/posts/" .. post_id)
   end
end

function response(status, headers, body)
   responses = responses + 1
   
   -- Count errors (5xx status codes)
   if status >= 500 then
      errors = errors + 1
   end
   
   -- Rate limiting is acceptable during stress test
   if status ~= 200 and status ~= 201 and status ~= 404 and status ~= 429 and status < 500 then
      print("Unexpected status: " .. status)
   end
end

function done(summary, latency, requests)
   io.write("==============================\n")
   io.write("WRK STRESS TEST RESULTS:\n")
   io.write("==============================\n")
   
   local total_requests = 0
   local total_responses = 0
   local total_errors = 0
   
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests") or 0
      local responses = thread:get("responses") or 0
      local errors    = thread:get("errors") or 0
      
      total_requests = total_requests + requests
      total_responses = total_responses + responses
      total_errors = total_errors + errors
      
      local msg = "Thread %d: %d requests, %d responses, %d errors"
      io.write(msg:format(id, requests, responses, errors) .. "\n")
   end
   
   io.write("------------------------------\n")
   io.write("SUMMARY:\n")
   io.write("Total Requests: " .. summary.requests .. "\n")
   io.write("Total Duration: " .. (summary.duration / 1000000) .. " seconds\n")
   io.write("Requests/sec: " .. string.format("%.2f", summary.requests / (summary.duration / 1000000)) .. "\n")
   io.write("Average Latency: " .. string.format("%.2f", latency.mean / 1000) .. " ms\n")
   io.write("Max Latency: " .. string.format("%.2f", latency.max / 1000) .. " ms\n")
   io.write("P50 Latency: " .. string.format("%.2f", latency:percentile(50) / 1000) .. " ms\n")
   io.write("P95 Latency: " .. string.format("%.2f", latency:percentile(95) / 1000) .. " ms\n")
   io.write("P99 Latency: " .. string.format("%.2f", latency:percentile(99) / 1000) .. " ms\n")
   io.write("Error Rate: " .. string.format("%.2f", (total_errors / total_responses) * 100) .. "%\n")
   io.write("==============================\n")
end