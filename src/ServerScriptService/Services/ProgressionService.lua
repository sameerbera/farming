local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local CropDefinitions = require(ReplicatedStorage.Shared.CropDefinitions)
local BiomeDefinitions = require(ReplicatedStorage.Shared.BiomeDefinitions)
local PetDefinitions = require(ReplicatedStorage.Shared.PetDefinitions)

local ProgressionService = {}

function ProgressionService:Init(context)
	self.Context = context
end

function ProgressionService:OnPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Farm Level"
	level.Parent = leaderstats

	local mutations = Instance.new("IntValue")
	mutations.Name = "Mutations"
	mutations.Parent = leaderstats

	self:SyncLeaderstats(player)
	self:UnlockFromProgress(player)
end

function ProgressionService:SyncLeaderstats(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	if not profile or not player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = player.leaderstats
	leaderstats.Coins.Value = profile.Coins
	leaderstats["Farm Level"].Value = profile.Level
	leaderstats.Mutations.Value = profile.Stats.MutationsHarvested or 0
end

function ProgressionService:GetPetBuffs(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	if not profile then
		return {}
	end

	local pet = PetDefinitions[profile.EquippedPet or ""]
	return pet and pet.Buffs or {}
end

function ProgressionService:GetPowerCapacity(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	if not profile then
		return Constants.FarmBasePower
	end

	local buffs = self:GetPetBuffs(player)
	return Constants.FarmBasePower + ((profile.Level - 1) * Constants.FarmPowerPerLevel) + (buffs.PowerBonus or 0)
end

function ProgressionService:UnlockFromProgress(player)
	local dataService = self.Context.Services.DataService
	local profile = dataService:GetProfile(player)

	if not profile then
		return
	end

	for biomeId, biome in pairs(BiomeDefinitions) do
		if profile.Level >= biome.UnlockLevel and not profile.UnlockedBiomes[biomeId] then
			dataService:UnlockBiome(player, biomeId)
			self.Context.Services.InteractionService:Notify(player, biome.DisplayName .. " unlocked!")
		end
	end

	for cropId, crop in pairs(CropDefinitions) do
		if profile.Level >= crop.UnlockLevel and not profile.UnlockedSeeds[cropId] then
			dataService:UnlockSeed(player, cropId)
			self.Context.Services.InteractionService:Notify(player, crop.DisplayName .. " seeds unlocked!")
		end
	end
end

function ProgressionService:AddXP(player, amount)
	local dataService = self.Context.Services.DataService
	local profile = dataService:GetProfile(player)

	if not profile then
		return
	end

	profile.XP += amount

	local leveled = false
	while profile.XP >= Constants.GetLevelXP(profile.Level) do
		profile.XP -= Constants.GetLevelXP(profile.Level)
		profile.Level += 1
		leveled = true
	end

	dataService:MarkDirty(player)

	if leveled then
		self.Context.Services.InteractionService:Notify(player, ("Farm Level %d reached!"):format(profile.Level))
		self:UnlockFromProgress(player)
	end

	self:SyncLeaderstats(player)
	self.Context.Services.InteractionService:PushProfile(player)
end

return ProgressionService
