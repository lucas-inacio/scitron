local function round(val, cnt)
	local mult = 10^(cnt or 0)
	return math.floor(val * mult + 0.5) / mult
end

MIN_ZERO = 2^-1074

function Sin(x)
	local result = math.sin(x)
	return round(result, PRECISION)
end

function Cos(x)
	local result = math.cos(x)
	return round(result, PRECISION)
end

function Tan(x)
	local result = math.tan(x)
	return round(result, PRECISION)
end

function Asin(x)
	local result = math.asin(x)
	return round(result, PRECISION)
end

function Acos(x)
	local result = math.acos(x)
	return round(result, PRECISION)
end

function Atan(x)
	local result = math.atan(x)
	return round(result, PRECISION)
end

function Sinh(x)
	local result = (math.exp(x)-math.exp(-x))/2
	return round(result, PRECISION)
end

function Cosh(x)
	return (math.exp(x)+math.exp(-x))/2
end

function Tanh(x)
	local result = Sinh(x)/Cosh(x)
	return round(result, PRECISION)
end

function Log10(x)
	local result = math.log(x, 10)
	return round(result, PRECISION)
end

function Ln(x)
	local result = math.log(x)
	return round(result, PRECISION)
end

function Factorial(x)
	local val = x + 0.0
	if val == 0.0 then
		return 1.0
	else
		return val*Factorial(val-1)
	end
end