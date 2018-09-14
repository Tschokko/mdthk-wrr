srvs = {}
srvs[0] = "A"
srvs[1] = "B"
srvs[2] = "C"

weights = {}
weights[0] = 4
weights[1] = 3
weights[2] = 2

i = -1
cw = 0

function max(a)
    local max = -1
    for k in pairs(a) do 
        if a[k] > max then
            max = a[k]
        end
    end
    return max
end

function gcd(a)
    local function gcd(m, n)
        -- greatest common divisor
        while m ~= 0 do
            m, n = (n % m), m;
        end
    
        return n;
    end

    local m = 0
    for k in pairs(a) do 
        m = gcd(m, a[k])
    end
    return m
end

function wrr()
    while true do
        i = (i + 1) % 3
        if i == 0 then
            cw = cw - gcd(weights)
            if cw <= 0 then
                cw = max(weights)
                if cw == 0 then
                    return nil
                end
            end
        end
        if weights[i] >= cw then
            return srvs[i]
        end
    end
end

for x = 1,9 do print(wrr()) end
