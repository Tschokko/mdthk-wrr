-- Setup proper connection to Redis DB
local redis = require "redis"
local client = redis:new()
local ok, err = client:connect("127.0.0.1", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    return ngx.exit(500)
end
if not client:ping() then
    ngx.log(ngx.ERR, "failed to access redis: ", err)
    return ngx.exit(500)
end

-- Define necessary variables
local server_weights = {}
local server_keys = {}
local server_count = 0

-- Access Redis DB and populate the variables for load balancing
local function load_server_weights()
    local res, err = client:zrange("mdthk:vlb:weights", 0, -1)
    local i = 0
    
    for _, key in ipairs(res) do
        server_weights[i] = tonumber(client:zscore("mdthk:vlb:weights", key))
        server_keys[i] = key
        i = i + 1
    end

    server_count = tonumber(client:zcard("mdthk:vlb:weights"))
end

-- Returns max weight from a table with following spec:
-- a[0..N] = weight
local function max(a)
    local max = -1
    for key in pairs(a) do
        if a[key] > max then
            max = a[key]
        end
    end
    return max
end

-- Returns greatest common divisor from a table with following spec:
-- a[0..N] = weight
local function gcd(a)
    local function gcd(m, n)
        while m ~= 0 do
            m, n = (n % m), m;
        end
        return n;
    end

    local m = 0
    for key in pairs(a) do
        m = gcd(m, a[key])
    end
    return m
end

local function wrr()
    local i = tonumber(client:get("mdthk:vlb:cindex"))
    local cw = tonumber(client:get("mdthk:vlb:cweight"))
    while true do
        i = (i + 1) % server_count
        if i == 0 then
            cw = cw - gcd(server_weights)
            if cw <= 0 then
                cw = max(server_weights)
                if cw == 0 then
                    return nil
                end
            end
        end
        if server_weights[i] >= cw then
            if client:hexists("mdthk:vlb:servers", server_keys[i]) then
                -- Save the current index and weight for next request
                client:set("mdthk:vlb:cindex", i)
                client:set("mdthk:vlb:cweight", cw)

                -- Increment hits counter for selected server
                client:zincrby("mdthk:vlb:hits", 1, server_keys[i])

                return client:hget("mdthk:vlb:servers", server_keys[i])
            end
        end
    end
end


-- Set current index and weight if not exists (see SETNX)
client:setnx("mdthk:vlb:cindex", -1)
client:setnx("mdthk:vlb:cweight", 0)

-- Load the server weights
load_server_weights()

-- Get next redirect url with weighted-round-robin algorithm
local redirect_url = wrr()
if redirect_url == nil then
    ngx.status = 404
    ngx.say("could not find a suitable server")
    return ngx.exit(404)
end

ngx.redirect(redirect_url .. ngx.var.request_uri, 302)
