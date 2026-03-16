local Players = game:GetService("Players")

local PlotService = {
	PlayerPlots = {},
	PlotOwners = {},
}

function PlotService:Init(context)
	self.Context = context
end

function PlotService:RegisterWorld(world)
	self.World = world

	for plotId, plot in pairs(world.Plots) do
		for cellId, cellPart in pairs(plot.Cells) do
			local currentPlotId = plotId
			local currentCellId = cellId
			cellPart.ClickDetector.MouseClick:Connect(function(player)
				self:HandleCellClick(player, currentPlotId, currentCellId)
			end)
		end

		for padId, padPart in pairs(plot.MachinePads) do
			local currentPlotId = plotId
			local currentPadId = padId
			padPart.ClickDetector.MouseClick:Connect(function(player)
				self:HandleMachinePadClick(player, currentPlotId, currentPadId)
			end)
		end
	end
end

function PlotService:GetPlotForPlayer(player)
	local plotId = self.PlayerPlots[player.UserId]
	return plotId and self.World.Plots[plotId] or nil
end

function PlotService:GetPlotIdForPlayer(player)
	return self.PlayerPlots[player.UserId]
end

function PlotService:AssignPlot(player)
	for plotId, plot in ipairs(self.World.Plots) do
		if not self.PlotOwners[plotId] then
			self.PlotOwners[plotId] = player.UserId
			self.PlayerPlots[player.UserId] = plotId
			plot.SignLabel.Text = player.DisplayName .. "'s Farm"
			plot.SignLabel.TextColor3 = Color3.fromRGB(255, 249, 188)
			self:TeleportToPlot(player)
			self.Context.Services.InteractionService:Notify(player, "A farm plot has been assigned to you.")
			return plot
		end
	end

	self.Context.Services.InteractionService:Notify(player, "No farm plots are available in this server.")
	return nil
end

function PlotService:TeleportToPlot(player)
	local plot = self:GetPlotForPlayer(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not root then
		return
	end

	root.CFrame = CFrame.new(plot.Spawn.Position + Vector3.new(0, 4, 0))
end

function PlotService:ReleasePlot(player)
	local plotId = self.PlayerPlots[player.UserId]
	if not plotId then
		return
	end

	local plot = self.World.Plots[plotId]
	self.Context.Services.CropService:ClearPlot(plotId)
	self.Context.Services.AutomationService:ClearPlot(plotId, player)

	if plot then
		plot.SignLabel.Text = "Open Plot"
		plot.SignLabel.TextColor3 = Color3.new(1, 1, 1)
	end

	self.PlayerPlots[player.UserId] = nil
	self.PlotOwners[plotId] = nil
end

function PlotService:SetSelectedSeed(player, seedId)
	self.Context.Services.DataService:SetRuntimeValue(player, "SelectedSeed", seedId)
	self.Context.Services.InteractionService:PushProfile(player)
end

function PlotService:GetSelectedSeed(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	return profile and profile.Runtime.SelectedSeed or "Carrot"
end

function PlotService:SetSelectedMachine(player, machineId)
	self.Context.Services.DataService:SetRuntimeValue(player, "SelectedMachine", machineId or "")
	self.Context.Services.InteractionService:PushProfile(player)
end

function PlotService:GetSelectedMachine(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	return profile and profile.Runtime.SelectedMachine or ""
end

function PlotService:IsOwner(player, plotId)
	return self.PlotOwners[plotId] == player.UserId
end

function PlotService:HandleCellClick(player, plotId, cellId)
	if not self:IsOwner(player, plotId) then
		self.Context.Services.InteractionService:Notify(player, "That plot belongs to another farmer.")
		return
	end

	local toolKind = self.Context.Services.ToolService:GetEquippedToolKind(player)
	if not toolKind then
		self.Context.Services.InteractionService:Notify(player, "Equip a tool first.")
		return
	end

	if toolKind == "Hoe" then
		local seedId = self:GetSelectedSeed(player)
		self.Context.Services.CropService:PlantCrop(player, plotId, cellId, seedId)
	elseif toolKind == "WateringCan" then
		self.Context.Services.CropService:WaterCrop(player, plotId, cellId, false)
	elseif toolKind == "HarvestTool" then
		self.Context.Services.CropService:HarvestCrop(player, plotId, cellId, false)
	end
end

function PlotService:HandleMachinePadClick(player, plotId, padId)
	if not self:IsOwner(player, plotId) then
		self.Context.Services.InteractionService:Notify(player, "That machine pad belongs to another player.")
		return
	end

	local selectedMachine = self:GetSelectedMachine(player)
	if selectedMachine == "" then
		self.Context.Services.InteractionService:Notify(player, "Select a machine from the automation panel first.")
		return
	end

	if selectedMachine == "REMOVE" then
		self.Context.Services.AutomationService:RemoveMachine(player, plotId, padId)
	else
		self.Context.Services.AutomationService:PlaceMachine(player, plotId, padId, selectedMachine)
	end
end

function PlotService:GetTradeEligiblePlayers(viewer)
	local players = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= viewer then
			table.insert(players, {
				UserId = player.UserId,
				Name = player.DisplayName,
			})
		end
	end

	table.sort(players, function(a, b)
		return a.Name < b.Name
	end)

	return players
end

return PlotService
