-- # HELP http_requests_total The total number of HTTP requests.
-- # TYPE http_requests_total counter
-- http_requests_total{method="post",code="200"} 1027 1395066363000
-- http_requests_total{method="post",code="400"}    3 1395066363000
ngx.req.set_header("Content-Type", "text/plain")

-- Setup proper connection to Redis DB
local redis = require "redis"
local client = redis:new()
local ok, err = client:connect("127.0.0.1", 6379)
if not ok then
    ngx.status = 500
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    return ngx.exit(500)
end
if not client:ping() then
    ngx.status = 500
    ngx.log(ngx.ERR, "failed to access redis: ", err)
    return ngx.exit(500)
end

ngx.status = 200
ngx.say("# HELP mdthk_vlb_hits_total The total number of server hits selected by the WRR load balancer.")
ngx.say("# TYPE mdthk_vlb_hits_total counter")
local res, err = client:zrange("mdthk:vlb:hits", 0, -1)
for _, key in ipairs(res) do
    local hits = tonumber(client:zscore("mdthk:vlb:hits", key))
    local server = client:hget("mdthk:vlb:servers", key)
    ngx.say("mdthk_vlb_hits_total{server=\"" .. server  .. "\"} " .. tostring(hits))
end

return ngx.exit(200)
