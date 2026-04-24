local Serialize = {}

local function encodeValue(value)
    local t = type(value)
    if t == "number" then
        return tostring(value)
    end
    if t == "boolean" then
        return value and "true" or "false"
    end
    if t == "string" then
        return string.format("%q", value)
    end
    if t == "table" then
        local isArray = true
        local maxIndex = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                isArray = false
                break
            end
            if k > maxIndex then
                maxIndex = k
            end
        end

        local parts = {}
        if isArray then
            for i = 1, maxIndex do
                parts[#parts + 1] = encodeValue(value[i])
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end

        for k, v in pairs(value) do
            local key
            if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
                key = k
            else
                key = "[" .. encodeValue(k) .. "]"
            end
            parts[#parts + 1] = key .. "=" .. encodeValue(v)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "nil"
end

function Serialize.encode(tbl)
    return "return " .. encodeValue(tbl)
end

function Serialize.decode(str)
    local chunk, err = loadstring(str)
    if not chunk then
        return nil, err
    end
    local ok, result = pcall(chunk)
    if not ok then
        return nil, result
    end
    if type(result) ~= "table" then
        return nil, "decoded value is not a table"
    end
    return result
end

return Serialize
