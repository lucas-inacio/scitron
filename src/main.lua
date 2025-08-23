include "gui.lua"

Gui = nil
function _init()
	fetch("/system/fonts/lil_mono.font"):poke(0x4000)
	Gui = CreateGui()
	window{
		width=Gui.width,
		height= Gui.height,
		resizeable = false,
		title = "Scitron"
	}
end

function _update()
	Gui:update_all()
end

function show_cpu_usage()
   print(string.format(
		"%.2f", stat(1)*100), Gui.width - 10,
		Gui.height - 10, 11
	)
end

function _draw()
	cls(7)
	Gui:draw_all()
	--show_cpu_usage()
end