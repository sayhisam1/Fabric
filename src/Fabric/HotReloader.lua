local HotReloader = {}
HotReloader.__index = HotReloader

function HotReloader.new(fabric)
	return setmetatable({
		fabric = fabric;
		staticComponents = {};
	}, HotReloader)
end

function HotReloader:giveModule(module, initialValue)
	self.staticComponents[module] = initialValue

	module.Changed:Connect(function()
		local newStaticComponent = require(module:Clone())
		local oldStaticComponent = self.staticComponents[module]

		self.fabric._collection:register(newStaticComponent, true)

		local count = 0
		for _, componentMap in pairs(self.fabric._collection._refComponents) do
			if componentMap[oldStaticComponent] then
				componentMap[newStaticComponent] = componentMap[oldStaticComponent]
				componentMap[oldStaticComponent] = nil

				setmetatable(componentMap[newStaticComponent], newStaticComponent)

				local ok, errorValue = xpcall(function()
					componentMap[newStaticComponent]:_runEffects()
				end, function(errorValue)
					return debug.traceback(errorValue)
				end)

				if not ok then
					warn(("Effects of %s encountered an error during hot reloading:\n\n%s"):format(
						tostring(componentMap[newStaticComponent]),
						tostring(errorValue)
					))
				end

				count = count + 1
			end
		end

		self.staticComponents[module] = newStaticComponent

		self.fabric:debug("[Hot Reload]", module.Name, "->", count, "components")
	end)
end

return HotReloader