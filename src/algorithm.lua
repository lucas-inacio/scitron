function Reduce(list, func, init)
    local result = init or 0
    for i=1, #list do
        result = func(result, list[i])
    end
    return result
end

function Foreach(list, func)
    for _, value in ipairs(list) do
        func(value)
    end
end