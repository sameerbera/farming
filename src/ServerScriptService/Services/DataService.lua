local DataStoreService = game:GetService("DataStoreService")

local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local DataService = {
	Profiles = {},
	DirtyProfiles = {},
	UsingMemoryStore = false,
}

local profileStore = nil
local attemptedStoreInit = false

local function getProfileStore()
	if attemptedStoreInit then
		return profileStore
	end

	attemptedStoreInit = true

	local success, result = pcall(function()
		return DataStoreService:GetDataStore("FarmMutationMMO_Profile_v1")
	end)

	if success then
		profileStore = result
	else
		DataService.UsingMemoryStore = true
		warn("FarmMutationMMO: DataStore unavailable, using session-only memory profiles.")
	end

	return profileStore
end

local function deepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end

	local clone = {}

	for key, child in pairs(value) do
		clone[key] = deepCopy(child)
	end

	return clone
end

local function mergeDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = deepCopy(value)
		elseif typeof(value) == "table" and typeof(target[key]) == "table" then
			mergeDefaults(target[key], value)
		end
	end
end

function DataService:CreateDefaultProfile()
	return {
		Coins = 300,
		Gems = 20,
		Level = 1,
		XP = 0,
		ToolTier = "Starter",
		UnlockedBiomes = {
			Forest = true,
		},
		UnlockedSeeds = {
			Carrot = true,
		},
		Seeds = {
			Carrot = 12,
		},
		Produce = {},
		OwnedMachines = {
			Sprinkler = 0,
			HarvesterDrone = 0,
			GrowthAccelerator = 0,
			SeedDuplicator = 0,
		},
		OwnedPets = {
			Chick = true,
		},
		EquippedPet = "Chick",
		Daily = {
			LastClaimKey = "",
			Streak = 0,
		},
		Stats = {
			MutationsHarvested = 0,
			TotalHarvests = 0,
			ContestWins = 0,
		},
		Runtime = {
			SelectedSeed = "Carrot",
			SelectedMachine = "",
		},
	}
end

function DataService:GetProfile(player)
	return self.Profiles[player.UserId]
end

function DataService:GetProfileByUserId(userId)
	return self.Profiles[userId]
end

function DataService:MarkDirty(playerOrUserId)
	local userId = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or playerOrUserId
	self.DirtyProfiles[userId] = true
end

function DataService:LoadPlayer(player)
	local profile = self:CreateDefaultProfile()
	local store = getProfileStore()

	if store then
		local success, result = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)

		if success and typeof(result) == "table" then
			mergeDefaults(result, profile)
			profile = result
		end
	end

	self.Profiles[player.UserId] = profile
	return profile
end

function DataService:SavePlayer(playerOrUserId)
	local userId = typeof(playerOrUserId) == "Instance" and playerOrUserId.UserId or playerOrUserId
	local profile = self.Profiles[userId]

	if not profile then
		return
	end

	local payload = deepCopy(profile)
	payload.Runtime = nil

	local store = getProfileStore()
	if not store then
		self.DirtyProfiles[userId] = nil
		return
	end

	local success = pcall(function()
		store:SetAsync(tostring(userId), payload)
	end)

	if success then
		self.DirtyProfiles[userId] = nil
	end
end

function DataService:UnloadPlayer(player)
	self:SavePlayer(player)
	self.Profiles[player.UserId] = nil
	self.DirtyProfiles[player.UserId] = nil
end

function DataService:AdjustCurrency(player, currencyName, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	local newValue = math.max(0, (profile[currencyName] or 0) + amount)
	profile[currencyName] = newValue
	self:MarkDirty(player)
	return true, newValue
end

function DataService:CanAfford(player, currencyName, amount)
	local profile = self:GetProfile(player)
	return profile and (profile[currencyName] or 0) >= amount
end

function DataService:SpendCurrency(player, currencyName, amount)
	local profile = self:GetProfile(player)

	if not profile or (profile[currencyName] or 0) < amount then
		return false
	end

	profile[currencyName] -= amount
	self:MarkDirty(player)
	return true
end

function DataService:AdjustSeed(player, seedId, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	profile.Seeds[seedId] = math.max(0, (profile.Seeds[seedId] or 0) + amount)
	self:MarkDirty(player)
	return true, profile.Seeds[seedId]
end

function DataService:AdjustProduce(playerOrUserId, produceKey, amount)
	local profile = typeof(playerOrUserId) == "Instance" and self:GetProfile(playerOrUserId) or self:GetProfileByUserId(playerOrUserId)
	if not profile then
		return false, 0
	end

	profile.Produce[produceKey] = math.max(0, (profile.Produce[produceKey] or 0) + amount)

	if profile.Produce[produceKey] <= 0 then
		profile.Produce[produceKey] = nil
	end

	self:MarkDirty(typeof(playerOrUserId) == "Instance" and playerOrUserId or playerOrUserId)
	return true, profile.Produce[produceKey] or 0
end

function DataService:AdjustMachine(player, machineId, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	profile.OwnedMachines[machineId] = math.max(0, (profile.OwnedMachines[machineId] or 0) + amount)
	self:MarkDirty(player)
	return true, profile.OwnedMachines[machineId]
end

function DataService:OwnsPet(player, petId)
	local profile = self:GetProfile(player)
	return profile and profile.OwnedPets[petId] == true
end

function DataService:UnlockPet(player, petId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.OwnedPets[petId] = true
	self:MarkDirty(player)
	return true
end

function DataService:SetEquippedPet(player, petId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.EquippedPet = petId
	self:MarkDirty(player)
	return true
end

function DataService:SetToolTier(player, tierName)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.ToolTier = tierName
	self:MarkDirty(player)
	return true
end

function DataService:AdjustXP(player, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	profile.XP += amount
	self:MarkDirty(player)
	return true, profile.XP
end

function DataService:SetLevel(player, level)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.Level = level
	self:MarkDirty(player)
	return true
end

function DataService:UnlockSeed(player, seedId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.UnlockedSeeds[seedId] = true
	self:MarkDirty(player)
	return true
end

function DataService:UnlockBiome(player, biomeId)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.UnlockedBiomes[biomeId] = true
	self:MarkDirty(player)
	return true
end

function DataService:AdjustStat(player, statName, amount)
	local profile = self:GetProfile(player)
	if not profile then
		return false, 0
	end

	profile.Stats[statName] = (profile.Stats[statName] or 0) + amount
	self:MarkDirty(player)
	return true, profile.Stats[statName]
end

function DataService:SetDailyClaim(player, claimKey, streak)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.Daily.LastClaimKey = claimKey
	profile.Daily.Streak = streak
	self:MarkDirty(player)
	return true
end

function DataService:SetRuntimeValue(player, key, value)
	local profile = self:GetProfile(player)
	if not profile then
		return false
	end

	profile.Runtime[key] = value
	return true
end

function DataService:BuildProfileSnapshot(player)
	local profile = self:GetProfile(player)
	if not profile then
		return nil
	end

	return {
		Coins = profile.Coins,
		Gems = profile.Gems,
		Level = profile.Level,
		XP = profile.XP,
		XPNeeded = Constants.GetLevelXP(profile.Level),
		ToolTier = profile.ToolTier,
		UnlockedBiomes = deepCopy(profile.UnlockedBiomes),
		UnlockedSeeds = deepCopy(profile.UnlockedSeeds),
		Seeds = deepCopy(profile.Seeds),
		Produce = deepCopy(profile.Produce),
		OwnedMachines = deepCopy(profile.OwnedMachines),
		OwnedPets = deepCopy(profile.OwnedPets),
		EquippedPet = profile.EquippedPet,
		Daily = deepCopy(profile.Daily),
		Stats = deepCopy(profile.Stats),
		Runtime = deepCopy(profile.Runtime),
	}
end

return DataService
