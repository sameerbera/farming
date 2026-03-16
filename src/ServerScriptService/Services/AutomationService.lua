local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MachineDefinitions = require(ReplicatedStorage.Shared.MachineDefinitions)

local AutomationService = {
	MachinesByPlot = {},
}

local function distance(a, b)
	return (a - b).Magnitude
end

function AutomationService:Init(context)
	self.Context = context
end

function AutomationService:Start()
	task.spawn(function()
		while true do
			task.wait(4)
			self:Tick()
		end
	end)
end

function AutomationService:GetMachines(plotId)
	self.MachinesByPlot[plotId] = self.MachinesByPlot[plotId] or {}
	return self.MachinesByPlot[plotId]
end

function AutomationService:GetPowerUsage(plotId)
	local used = 0
	for _, machine in pairs(self:GetMachines(plotId)) do
		used += MachineDefinitions[machine.MachineId].PowerCost
	end
	return used
end

function AutomationService:CreateMachineVisual(plotId, padId, machineId)
	local pad = self.Context.Services.PlotService.World.Plots[plotId].MachinePads[padId]
	local definition = MachineDefinitions[machineId]

	local visual = Instance.new("Part")
	visual.Name = machineId
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanTouch = false
	visual.CanQuery = false
	visual.Size = Vector3.new(4, 4, 4)
	visual.Position = pad.Position + Vector3.new(0, 2.5, 0)
	visual.Material = Enum.Material.Neon
	visual.Color = definition.Color
	visual.Shape = machineId == "HarvesterDrone" and Enum.PartType.Ball or Enum.PartType.Block
	visual.Parent = pad.Parent

	local label = pad:FindFirstChild("Label")
	local textLabel = label and label:FindFirstChildOfClass("TextLabel")
	if textLabel then
		textLabel.Text = definition.DisplayName
	end

	return visual
end

function AutomationService:PlaceMachine(player, plotId, padId, machineId)
	local definition = MachineDefinitions[machineId]
	if not definition then
		self.Context.Services.InteractionService:Notify(player, "Unknown machine.")
		return false
	end

	local machines = self:GetMachines(plotId)
	if machines[padId] then
		self.Context.Services.InteractionService:Notify(player, "That machine pad is already occupied.")
		return false
	end

	local profile = self.Context.Services.DataService:GetProfile(player)
	if (profile.OwnedMachines[machineId] or 0) <= 0 then
		self.Context.Services.InteractionService:Notify(player, "You do not own that machine yet.")
		return false
	end

	local capacity = self.Context.Services.ProgressionService:GetPowerCapacity(player)
	local currentUsage = self:GetPowerUsage(plotId)
	if currentUsage + definition.PowerCost > capacity then
		self.Context.Services.InteractionService:Notify(player, "Not enough farm power for that machine.")
		return false
	end

	self.Context.Services.DataService:AdjustMachine(player, machineId, -1)
	machines[padId] = {
		MachineId = machineId,
		PadId = padId,
		OwnerUserId = player.UserId,
		Visual = self:CreateMachineVisual(plotId, padId, machineId),
	}

	self.Context.Services.InteractionService:Notify(player, definition.DisplayName .. " placed.")
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function AutomationService:RemoveMachine(player, plotId, padId)
	local machines = self:GetMachines(plotId)
	local machine = machines[padId]
	if not machine then
		self.Context.Services.InteractionService:Notify(player, "That pad is already empty.")
		return false
	end

	if machine.Visual then
		machine.Visual:Destroy()
	end

	local pad = self.Context.Services.PlotService.World.Plots[plotId].MachinePads[padId]
	local label = pad:FindFirstChild("Label")
	local textLabel = label and label:FindFirstChildOfClass("TextLabel")
	if textLabel then
		textLabel.Text = "Empty"
	end

	self.Context.Services.DataService:AdjustMachine(player, machine.MachineId, 1)
	machines[padId] = nil
	self.Context.Services.InteractionService:Notify(player, "Machine stored back in inventory.")
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function AutomationService:ClearPlot(plotId, ownerPlayer)
	local machines = self:GetMachines(plotId)
	for padId, machine in pairs(machines) do
		if ownerPlayer then
			self.Context.Services.DataService:AdjustMachine(ownerPlayer, machine.MachineId, 1)
		end

		if machine.Visual then
			machine.Visual:Destroy()
		end

		local pad = self.Context.Services.PlotService.World.Plots[plotId].MachinePads[padId]
		local label = pad:FindFirstChild("Label")
		local textLabel = label and label:FindFirstChildOfClass("TextLabel")
		if textLabel then
			textLabel.Text = "Empty"
		end
	end

	self.MachinesByPlot[plotId] = {}
end

function AutomationService:GetGrowthBonus(plotId, cellId)
	local plot = self.Context.Services.PlotService.World.Plots[plotId]
	local cell = plot.Cells[cellId]
	local bonus = 0

	for padId, machine in pairs(self:GetMachines(plotId)) do
		if machine.MachineId == "GrowthAccelerator" then
			local definition = MachineDefinitions.GrowthAccelerator
			local pad = plot.MachinePads[padId]
			if distance(cell.Position, pad.Position) <= definition.Range then
				bonus += 0.35
			end
		end
	end

	return bonus
end

function AutomationService:OnCropHarvest(player, plotId, cellId, cropId, quantity)
	local plot = self.Context.Services.PlotService.World.Plots[plotId]
	local cell = plot.Cells[cellId]
	local duplicated = 0

	for padId, machine in pairs(self:GetMachines(plotId)) do
		if machine.MachineId == "SeedDuplicator" then
			local definition = MachineDefinitions.SeedDuplicator
			local pad = plot.MachinePads[padId]
			if distance(cell.Position, pad.Position) <= definition.Range then
				for _ = 1, quantity do
					if math.random() < definition.DuplicateChance then
						duplicated += 1
					end
				end
			end
		end
	end

	if duplicated > 0 then
		self.Context.Services.DataService:AdjustSeed(player, cropId, duplicated)
		self.Context.Services.InteractionService:Notify(player, ("Seed Duplicator created %dx bonus %s seed."):format(duplicated, cropId))
		self.Context.Services.InteractionService:PushProfile(player)
	end
end

function AutomationService:Tick()
	for plotId, machines in pairs(self.MachinesByPlot) do
		local ownerUserId = self.Context.Services.PlotService.PlotOwners[plotId]
		local owner = ownerUserId and Players:GetPlayerByUserId(ownerUserId) or nil
		local plot = self.Context.Services.PlotService.World.Plots[plotId]

		for padId, machine in pairs(machines) do
			local definition = MachineDefinitions[machine.MachineId]
			local pad = plot.MachinePads[padId]

			if machine.MachineId == "Sprinkler" then
				for cellId, cell in pairs(plot.Cells) do
					if distance(cell.Position, pad.Position) <= definition.Range then
						self.Context.Services.CropService:WaterCrop(owner, plotId, cellId, true)
					end
				end
			elseif machine.MachineId == "HarvesterDrone" and owner then
				for cellId, cell in pairs(plot.Cells) do
					if distance(cell.Position, pad.Position) <= definition.Range then
						self.Context.Services.CropService:HarvestCrop(owner, plotId, cellId, true)
					end
				end
			end
		end
	end
end

return AutomationService
