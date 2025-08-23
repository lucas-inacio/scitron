include "calc.lua"

local function drawButtonReleased(self, label)
	local size = #label * 4
	rect(0, 0, self.width-1, self.height-1, 0)
	rect(1, 1, self.width-2, self.height-2, 0)
	if label == "FN" then
		rectfill(2, 2, self.width-3, self.height-3, 9)
	end
	line(1, 1, self.width - 2, 1, 7)
	line(1, 1, 1, self.height - 2, 7)
	print(
		label,
		self.width / 2 - size / 2,
		self.height / 2 - 3,
		7
	)			
end

local function drawButtonClicked(self, label)
	local size = #label * 4
	rect(0, 0, self.width-1, self.height-1, 0)
	rectfill(1, 1, self.width-2, self.height-2, 6)
	print(
		label,
		self.width / 2 - size / 2,
		self.height / 2 - 3,
		7
	)			
end

function buildKeyboard(keyboard, keys, callback)
	local rows = #keys
	local cols = #keys[1]
	for row=0, rows-1 do
		for col = 0, cols-1 do
			local label = keys[row+1][col+1]
			local button = keyboard:attach{
				x = col * keyboard.width / cols + 2,
				y = row * keyboard.height / rows + 2,
				width = keyboard.width / cols - 4,
				height = keyboard.height / rows - 4,
				draw = function(self)
					if self.clicked then
						drawButtonClicked(self, label)
					else
						drawButtonReleased(self, label)
					end
				end,
				click = function(self) self.clicked = true end,
				release = function(self) self.clicked = false end,
				tap = function(self)
					callback(Calc, row+1, col+1)
				end
			}
		end
	end
end

local function findKeyIndex(targetKey, keyMap)
	for rowIndex, rowVal in ipairs(keyMap) do
		for colIndex, colVal in ipairs(rowVal) do
			if ord(targetKey) == ord(keyMap[rowIndex][colIndex]) then
				return rowIndex, colIndex
			end
		end
	end
	return nil, nil
end

function CreateGui()
	local Gui = create_gui()
	Gui.width = 128
	Gui.height = 200
	
	local mainFrame = Gui:attach{
		x = 0, y = 0,
		width = Gui.width, height = Gui.height,
		draw = function(self)
			rectfill(0, 0, self.width, self.height, 13)
		end
	}
	
	local screen = mainFrame:attach{
		x = 6, y = 2,
		width = mainFrame.width*0.91,
		height = mainFrame.height*0.3,
		draw = function(self)
			rectfill(0, 0, self.width, self.height, 28)
			line(0, 0, self.width, 0, 0)
			line(0, 1, self.width, 1, 0)
			line(0, 0, 0, self.height, 0)
			line(1, 0, 1, self.height, 0)
			line(0, self.height-1, self.width, self.height-1, 6)
			line(2, self.height-2, self.width, self.height-2, 6)
			line(self.width-1, 0, self.width-1, self.height, 6)
			line(self.width-2, 1, self.width-2, self.height-3, 6)
			if #Calc.expr > 0 then
				local str = Calc.expr:sub(
					Calc.pointer,
					Calc.pointer + Calc.charLimit)
				local cursorPos = Calc.cursorPos - Calc.pointer
				print(str, 5, 15, 0)
				line(cursorPos*5+5, 22, cursorPos*5+9, 22)
			end
			
			if #Calc.result > 0 then
				local size = #Calc.result * 5
				print(Calc.result, self.width - size - 10, 48, 0)
			end
		end
	}
	
	local keyboard = mainFrame:attach{
		x = 4, y = 62,
		width = mainFrame.width*0.94,
		height = mainFrame.height*0.67,
		update = function()
			local c = readtext(true)
			if c then
				local row, col = findKeyIndex(c, Calc.basicKeys)
				if row and col then
					Calc:typeBasic(row, col) 
				end
			elseif keyp("backspace") then
				Calc:removeStr()
			elseif keyp("enter") then
				local row, col = findKeyIndex("=", Calc.basicKeys)
				if row and col then
					Calc:typeBasic(row, col) 
				end
			elseif keyp("ctrl") then
				local row, col = findKeyIndex("FN", Calc.navKeys)
				if row and col then
					Calc:typeNav(row, col) 
				end
			elseif keyp("left") then
				local row, col = findKeyIndex("<-", Calc.navKeys)
				if row and col then
					Calc:typeNav(row, col) 
				end	
			elseif keyp("right") then
				local row, col = findKeyIndex("->", Calc.navKeys)
				if row and col then
					Calc:typeNav(row, col) 
				end
			elseif keyp("A") then
				local row, col = findKeyIndex("ANS", Calc.basicKeys)
				if row and col then
					Calc:typeBasic(row, col) 
				end
			end
		end
	}
	
	local navKeys = keyboard:attach{
		x = 0, y = 0,
		width = keyboard.width, height = keyboard.height/7
	}
	
	local sciKeys = keyboard:attach{
		x = 0, y = navKeys.height + navKeys.y,
		width = keyboard.width, height = keyboard.height*2/7
	}
	
	local basicKeys = keyboard:attach{
		x = 0, y = sciKeys.y + sciKeys.height,
		width = keyboard.width, height = keyboard.height*4/7,
	}
	
	buildKeyboard(basicKeys, Calc.basicKeys, Calc.typeBasic)
	buildKeyboard(navKeys, Calc.navKeys, Calc.typeNav)
	if Calc.alternate then
		buildKeyboard(sciKeys, Calc.altSciKeys, Calc.typeSci)
	else
		buildKeyboard(sciKeys, Calc.sciKeys, Calc.typeSci)
	end
	return Gui
end