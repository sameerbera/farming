local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local CropDefinitions = require(ReplicatedStorage.Shared.CropDefinitions)
local Format = require(ReplicatedStorage.Shared.Format)

local CropService = {
	CropsByPlot = {},
}

local function cloneTable(source)
	local output = {}
	for key, value in pairs(source) do
		output[key] = value
	end
	return output
end

local function weightedChoice(weights)
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end

	local roll = math.random() * total
	local cursor = 0
	for key, weight in pairs(weights) do
		cursor += weight
		if roll <= cursor then
			return key
		end
	end

	return "None"
end

local function mutationVisualColor(baseColor, mutation)
	if mutation == "Golden" then
		return Color3.fromRGB(255, 214, 72)
	elseif mutation == "Giant" then
		return baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
	elseif mutation == "Rainbow" then
		return Color3.fromRGB(255, 80, 214)
	elseif mutation == "Explosive" then
		return Color3.fromRGB(255, 79, 43)
	end

	return baseColor
end

function CropService:Init(context)
	self.Context = context
end

function CropService:Start()
	task.spawn(function()
		while true do
			task.wait(Constants.CropTickRate)
			self:Tick(Constants.CropTickRate)
		end
	end)
end

function CropService:ClearPlot(plotId)
	local plotCrops = self.CropsByPlot[plotId]
	if not plotCrops then
		return
	end

	for _, crop in pairs(plotCrops) do
		if crop.Model then
			crop.Model:Destroy()
		end
	end

	self.CropsByPlot[plotId] = nil
end

function CropService:GetCrop(plotId, cellId)
	return self.CropsByPlot[plotId] and self.CropsByPlot[plotId][cellId] or nil
end

function CropService:CreateCropModel(plotId, cellId, cropId)
	local plot = self.Context.Services.PlotService.World.Plots[plotId]
	local cellPart = plot.Cells[cellId]
	local cropDef = CropDefinitions[cropId]

	local model = Instance.new("Part")
	model.Name = cropId
	model.Anchored = true
	model.CanCollide = false
	model.CanTouch = false
	model.CanQuery = false
	model.Material = Enum.Material.Grass
	model.Shape = Enum.PartType.Ball
	model.Color = cropDef.Color
	model.Size = Vector3.new(2.5, cropDef.StageHeights[1], 2.5)
	model.Position = cellPart.Position + Vector3.new(0, 1.2 + (model.Size.Y / 2), 0)
	model.Parent = plot.Model

	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Range = 10
	light.Parent = model

	return model
end

function CropService:GetMutationWeights(player)
	local weights = cloneTable(Constants.MutationWeights)
	local buffs = self.Context.Services.ProgressionService:GetPetBuffs(player)
	local bonus = buffs.MutationBonus or 0

	if bonus > 0 then
		local bonusPoints = bonus * 100
		weights.None = math.max(50, weights.None - bonusPoints)
		weights.Golden += bonusPoints * 0.45
		weights.Giant += bonusPoints * 0.3
		weights.Rainbow += bonusPoints * 0.17
		weights.Explosive += bonusPoints * 0.08
	end

	return weights
end

function CropService:PlantCrop(player, plotId, cellId, seedId)
	local profile = self.Context.Services.DataService:GetProfile(player)
	local cropDef = CropDefinitions[seedId]

	if not cropDef then
		self.Context.Services.InteractionService:Notify(player, "Unknown seed selected.")
		return false
	end

	if not profile.UnlockedSeeds[seedId] then
		self.Context.Services.InteractionService:Notify(player, "That seed is not unlocked yet.")
		return false
	end

	if (profile.Seeds[seedId] or 0) <= 0 then
		self.Context.Services.InteractionService:Notify(player, "You are out of " .. cropDef.DisplayName .. " seeds.")
		return false
	end

	if self:GetCrop(plotId, cellId) then
		self.Context.Services.InteractionService:Notify(player, "That farm tile is already occupied.")
		return false
	end

	self.Context.Services.DataService:AdjustSeed(player, seedId, -1)

	self.CropsByPlot[plotId] = self.CropsByPlot[plotId] or {}
	local crop = {
		CropId = seedId,
		OwnerUserId = player.UserId,
		PlotId = plotId,
		CellId = cellId,
		Stage = 1,
		Progress = 0,
		GrowthDuration = cropDef.GrowthTime,
		Mutation = "None",
		Mature = false,
		Model = self:CreateCropModel(plotId, cellId, seedId),
	}
	self.CropsByPlot[plotId][cellId] = crop

	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function CropService:WaterCrop(player, plotId, cellId, fromMachine)
	local crop = self:GetCrop(plotId, cellId)
	if not crop then
		if not fromMachine and player then
			self.Context.Services.InteractionService:Notify(player, "There is nothing planted there.")
		end
		return false
	end

	if crop.Mature then
		if not fromMachine and player then
			self.Context.Services.InteractionService:Notify(player, "That crop is already ready to harvest.")
		end
		return false
	end

	local bonus = 0.05
	if not fromMachine and player then
		local toolStats = self.Context.Services.ToolService:GetToolStats(player)
		bonus = 0.08 * toolStats.WaterBoost
	end

	crop.Progress = math.min(1, crop.Progress + bonus)
	self:RefreshCropVisual(crop)
	return true
end

function CropService:RollMutation(player)
	return weightedChoice(self:GetMutationWeights(player))
end

function CropService:RefreshCropVisual(crop)
	local cropDef = CropDefinitions[crop.CropId]
	local stageCount = #cropDef.StageHeights
	local newStage = math.clamp(math.ceil(math.max(crop.Progress, 0.01) * stageCount), 1, stageCount)

	if newStage ~= crop.Stage then
		crop.Stage = newStage
	end

	local height = cropDef.StageHeights[newStage]
	local width = 2.5 + ((newStage - 1) * 0.35)

	if crop.Mutation == "Giant" then
		width *= 1.4
		height *= 1.45
	end

	local cellPart = self.Context.Services.PlotService.World.Plots[crop.PlotId].Cells[crop.CellId]
	local goal = {
		Size = Vector3.new(width, height, width),
		Position = cellPart.Position + Vector3.new(0, 1.2 + (height / 2), 0),
		Color = mutationVisualColor(cropDef.Color, crop.Mutation),
	}

	local tween = TweenService:Create(crop.Model, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), goal)
	tween:Play()

	local light = crop.Model:FindFirstChildOfClass("PointLight")
	if crop.Mature then
		crop.Model.Material = crop.Mutation == "Golden" and Enum.Material.Metal or Enum.Material.Neon
		if light then
			light.Brightness = crop.Mutation == "None" and 0 or 1.8
			light.Color = goal.Color
		end
	else
		crop.Model.Material = Enum.Material.Grass
		if light then
			light.Brightness = 0
		end
	end
end

function CropService:HarvestCrop(player, plotId, cellId, fromMachine)
	local crop = self:GetCrop(plotId, cellId)

	if not crop then
		if not fromMachine then
			self.Context.Services.InteractionService:Notify(player, "There is no crop to harvest.")
		end
		return false
	end

	if not crop.Mature then
		if not fromMachine then
			self.Context.Services.InteractionService:Notify(player, "That crop still needs more time.")
		end
		return false
	end

	local toolStats = player and self.Context.Services.ToolService:GetToolStats(player) or { HarvestBonus = 0 }
	local quantity = 1
	if math.random() < (toolStats.HarvestBonus or 0) then
		quantity += 1
	end

	local produceKey = Format.MakeProduceKey(crop.CropId, crop.Mutation)
	self.Context.Services.DataService:AdjustProduce(player, produceKey, quantity)
	self.Context.Services.DataService:AdjustStat(player, "TotalHarvests", quantity)

	if crop.Mutation ~= "None" then
		self.Context.Services.DataService:AdjustStat(player, "MutationsHarvested", quantity)
		self.Context.Services.ProgressionService:SyncLeaderstats(player)
	end

	local xpGain = math.max(10, math.floor(CropDefinitions[crop.CropId].BaseSell * 0.3))
	self.Context.Services.ProgressionService:AddXP(player, xpGain)
	self.Context.Services.AutomationService:OnCropHarvest(player, plotId, cellId, crop.CropId, quantity)
	self.Context.Services.CompetitionService:RecordHarvest(player, crop.CropId, crop.Mutation, quantity)

	crop.Model:Destroy()
	self.CropsByPlot[plotId][cellId] = nil

	self.Context.Services.InteractionService:Notify(player, string.format("Harvested %dx %s %s.", quantity, crop.Mutation ~= "None" and crop.Mutation or "", CropDefinitions[crop.CropId].DisplayName):gsub("%s+", " "))
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function CropService:Tick(deltaTime)
	for plotId, cropMap in pairs(self.CropsByPlot) do
		for _, crop in pairs(cropMap) do
			if not crop.Mature then
				local owner = Players:GetPlayerByUserId(crop.OwnerUserId)
				local buffs = owner and self.Context.Services.ProgressionService:GetPetBuffs(owner) or {}
				local growthBonus = (buffs.GrowthBonus or 0) + self.Context.Services.AutomationService:GetGrowthBonus(plotId, crop.CellId)
				crop.Progress = math.min(1, crop.Progress + ((deltaTime / crop.GrowthDuration) * (1 + growthBonus)))

				if crop.Progress >= 1 and not crop.Mature then
					crop.Mature = true
					crop.Mutation = owner and self:RollMutation(owner) or "None"
					if owner and crop.Mutation ~= "None" then
						self.Context.Services.InteractionService:Notify(owner, CropDefinitions[crop.CropId].DisplayName .. " mutated into " .. crop.Mutation .. "!")
					end
				end

				self:RefreshCropVisual(crop)
			end
		end
	end
end

return CropService
