include "parser.lua"

local KNOWN_VARS = {
	PI = math.pi
}

local function replace_vars(expr)
	local res = expr:sub(1, #expr)
	for i, var in pairs(KNOWN_VARS) do
		res = res:gsub(i, string.format("%.40e", var))
	end
	return res
end

local function isOp(expr)
	return expr:match("^[%+%-%*/^%(%)]$") ~= nil
end

Calc = {}
Calc.alternate = false
Calc.expr = ""
Calc.charLimit = 21
Calc.pointer = 1
Calc.cursorPos = 1
Calc.result = "0"
Calc.restart = false -- If '=' was pressed before, erase old expression
Calc.basicKeys = {
	{ "7", "8", "9", "(", ")" },
	{ "4", "5", "6", "*", "/" },
	{ "1", "2", "3", "+", "-" },
	{ "0", ".", "ANS", "^", "=" }
}
Calc.navKeys = {
	{ "FN", "BK", "<-", "->", "AC" }
}
Calc.sciKeys = {
	{ "PI", "sin", "cos", "tan" },
	{ "e^x", "EXP", "n!", "log" }
}
Calc.altSciKeys = {
	{ "DEG", "asin", "acos", "atan" },
	{ "ln", "sinh", "cosh", "tanh" }
}

-- Avoid placing the cursor in the middle of
-- a function or variable name
function Calc:incrementCursor()
	local right = self.expr:sub(self.cursorPos, #self.expr)
	local amount = 0
	if #right > 0 then
		local match =
			right:match("^%a%w*%(") or
			right:match("^%a%w*")
			
		amount = match and #match or 1
		self.cursorPos = self.cursorPos + amount
		if self.cursorPos - self.pointer >
			self.charLimit then
			self.pointer = self.pointer + self.charLimit
		end
	end
	self.restart = false
	return amount
end

function Calc:decrementCursor()
	local left = self.expr:sub(1, self.cursorPos-1)
	
	local amount = 0
	if #left > 0 then
		local match = 
			left:match("%a%w*%($") or
			left:match("%a%w*$")
	
		amount = match and #match or 1
		self.cursorPos = self.cursorPos - amount
		if self.cursorPos <= self.pointer and
			self.pointer > self.charLimit then
			self.pointer = self.pointer - self.charLimit
		end
	end
	self.restart = false
	return amount
end

function Calc:resetCursors()
	self.pointer = 1
	self.cursorPos = 1
end

function Calc:insertStr(str)
	if self.cursorPos > 0 then
		local left = self.expr:sub(1, self.cursorPos-1)
		local right = self.expr:sub(self.cursorPos, #self.expr)
		self.expr = left..str..right
	else
		self.expr = str..self.expr
	end
	self:incrementCursor()
end

function Calc:removeStr()
	local last = self.cursorPos
	local amount = self:decrementCursor()
	if amount > 0 then
		local left = self.expr:sub(1, last-amount-1)
		local right = self.expr:sub(last, #self.expr)
		self.expr = left..right
	end
end

function Calc:typeBasic(row, col)
	local button = self.basicKeys[row][col]
	if button == "ANS" then
		if self.result then
			self.expr = self.expr..(tonumber(self.result) or 0)
			local amount = 0
			repeat amount = self:incrementCursor() until amount == 0
		end
		self.restart = false
	elseif button == "=" then
		local expr = replace_vars(self.expr)
		local res = Parse(expr)
		if res then
			self.result = res..""
		else
			self.result = "Invalid expression"
		end
		self.restart = true
	else
		if Calc.restart then
			local followThrough = isOp(button) and self.result ~= "0"
			self.expr =  ""..(followThrough and tonumber(self.result) or "")
			self.restart = false
			self.cursorPos = #self.expr+1
			self.pointer = 1
		end
		self:insertStr(self.basicKeys[row][col])
	end
end

function Calc:typeNav(row, col)
	if self.navKeys[row][col] == "AC" then
		self.expr = ""
		self.result = "0"
		self.pointer = 1
		self.cursorPos = 1
	elseif self.navKeys[row][col] == "->" then
		self:incrementCursor()
	elseif self.navKeys[row][col] == "<-" then
		self:decrementCursor()
	elseif self.navKeys[row][col] == "BK" then
		self:removeStr()
	elseif self.navKeys[row][col] == "FN" then
		Calc.alternate = not Calc.alternate
		Gui = nil
		Gui = CreateGui()
	end
end

function Calc:typeSci(row, col)
	if Calc.restart then
		self.expr = ""
		self.restart = false
		self:resetCursors()
	end
	if self.alternate then
		self:handleAltSci(row, col)
	else
		self:handleSci(row, col)
	end
end

function Calc:handleSci(row, col)
	local button = self.sciKeys[row][col]
	if button == "e^x" then
		self:insertStr("exp(")
	elseif button == "EXP" then
		if self.expr:match("%d+$") then
			self.expr = self.expr.."*"
		end
		self.expr = self.expr.."10^"
		local match = self.expr:match("%*?10^$")
		for i=1,#match do
			self:incrementCursor()
		end
	elseif button == "n!" then
		self:insertStr("fact(")
	elseif KNOWN_VARS[button] then
		self:insertStr(button)
	else
		self:insertStr(button.."(")
	end
end

function Calc:handleAltSci(row, col)
	local button = self.altSciKeys[row][col]
	if button == "DEG" then
		local number = tonumber(self.result)
		if number then
			self.result = math.deg(number)..""
		end
	else
		self:insertStr(button.."(")
	end
end