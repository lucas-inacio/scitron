include "algorithm.lua"
include "mathematic.lua"

local KNOWN_FUNCTIONS = {
    sin = Sin,
    cos = Cos,
    tan = Tan,
    asin = Asin,
    acos = Acos,
    atan = Atan,
    ln = Ln,
    log = Log10,
    sqrt = math.sqrt,
    exp = math.exp,
    sinh = Sinh,
    cosh = Cosh,
    tanh = Tanh,
    fact = Factorial
}

local function copy_table(tb, start, stp)
    local newTb = {}
    local final = stp or #tb
    for i = start, final do
        table.insert(newTb, tb[i])
    end

    return newTb
end

-- Used to split expression by operation
local function split_op(expr, sep)
    local subExpr = {}
    local start = 1
    while start <= #expr do
        local stp = expr:find(sep, start, true)
        if stp then
            table.insert(subExpr, expr:sub(start, stp-1))
            start = stp+1
        elseif start > 1 then
            table.insert(subExpr, expr:sub(start))
            break
        else
            break
        end
    end
    return subExpr
end

-- Plus and minus are special cases, since there are numbers like 2e+3 or 1.5e-7.
-- Should not split expr in the middle of a number.
local function split_minus_plus(expr, sep)
    local subExpr = {}
    local exprCp = expr:sub(1)
    local remain = ""
    while #exprCp > 0 do
        local stp = exprCp:find(sep, 1, true)
        if stp then
            local numberStart, numberEnd = exprCp:find("(%d+%.?%d*e%"..sep.."%d+)")
            -- Found scientific notation
            if numberStart and
                numberStart <= stp and
                numberEnd >= stp then
                
                remain = remain..exprCp:sub(1, numberEnd)
                local rest = exprCp:sub(numberEnd+1)
                -- If there is nothing left to process, add number to list
                if #subExpr > 0 and #rest == 0 then
                    table.insert(subExpr, remain)
                    break
                -- Else, keep going
                else
                    exprCp = rest
                    goto continue
                end
            else
                table.insert(subExpr, remain..exprCp:sub(1, stp-1))
                exprCp = exprCp:sub(stp+1)
            end
        -- No + or - symbol found. Keep entire expression.
        elseif #subExpr > 0 then
            table.insert(subExpr, remain..exprCp:sub(1))
            break
        else
            break
        end

        remain=""
        ::continue::
    end
    return subExpr
end

local function preprocess(expression)
    -- Remove spaces
    local expr = expression:gsub("%s+", "")
    -- Change symbol for unary minus, to facilitate parsing
    expr = expr:gsub("([%+%(/*%^])%-", "%1~")
    expr = expr:gsub("^-", "~")
    return expr
end

local function eval(expr, vars)
	local number = tonumber(expr)
	if number then return number end
	
	-- Negative number
	if expr:sub(1, 1) == "~" then
	    number = tonumber(expr:sub(2, #expr))
	    if number then return -number end
	end
	
	-- If the expression is just a variable,
	-- replace with result
	local index = tonumber(expr:match("^%$(%d+)$"))
	if index then
		return vars[index]
	end
	
	-- Simplify double minus, in case any previous
	-- operation resulted in a negative number
	expr = expr:gsub("%-%-", "+")
	
	-- Find nested operations, compute their values
	-- and save them for later.
	-- Nested expressions are replaced with variable
	-- numbers like $1..$n
	local subExprs = {}
	local start, stp = expr:find("%b()")
	while start and stp do
		local left = expr:sub(1, start-1)
		local nested = expr:sub(start+1, stp-1)
		local right = expr:sub(stp+1)
		
		-- If it's a function call...
		local func = left:match("%a%w*$")
		if func and KNOWN_FUNCTIONS[func] then
			table.insert(subExprs, KNOWN_FUNCTIONS[func](eval(nested)))
			-- ...replace whole call with $n
			expr = left:sub(1, #left-#func).."$"..#subExprs..right
		else
			table.insert(subExprs, eval(nested))
			expr = left.."$"..#subExprs..right
		end
		start, stp = expr:find("%b()")
	end
	subExprs = vars or subExprs
	
	-- Sum
	local sums = split_minus_plus(expr, "+")
	if #sums > 0 then
	   return Reduce(
	      copy_table(sums, 2),
	      function(a, b) return eval(a, subExprs)+eval(b, subExprs) end,
	      sums[1]
	   )
	end
	
	-- Subtraction
	local subs = split_minus_plus(expr, "-")
	if #subs > 0 then
	   return Reduce(
	      copy_table(subs, 2),
	      function(a, b) return eval(a, subExprs)-eval(b, subExprs) end,
	      subs[1]
	   )
	end
	
	-- Multiplication
	local muls = split_op(expr, "*")
	if #muls > 0 then
	    return Reduce(
	        copy_table(muls, 2),
	        function(a, b) return eval(a, subExprs)*eval(b, subExprs) end,
	        muls[1]
	    )
	end
	
	-- Division
	local divs = split_op(expr, "/")
	if #divs > 0 then
	    return Reduce(
	        copy_table(divs, 2),
	        function(a, b)
	        		-- Division by zero
	        		dvr = eval(b, subExprs)
	        		if dvr < MIN_ZERO then error("Division by zero") end
	            return eval(a, subExprs)/dvr
	        end,
	        divs[1]
	    )
	end
	
	-- Exponentiation
	local exps = split_op(expr, "^")
	if #exps > 0 then
	    return Reduce(
	        copy_table(exps, 2),
	        function(a, b) return eval(a, subExprs)^eval(b, subExprs) end,
	        exps[1]
	    )
	end
	
	-- None of previous basic operations were performed,
	-- so there must be a single value left
	local result = #subExprs == 1 and subExprs[1] or nil
	if result then
	    if expr:sub(1,1) == "~" then result = -result end
	end
	
	return result
end 

-- Wrap eval in a protected call to catch errors
function Parse(expression)
	local expr = preprocess(expression)
	local success, result = pcall(eval, expr)
	if not success then
		return "Invalid expression"
	else
		return result
	end
end