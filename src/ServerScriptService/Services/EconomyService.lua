local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local CropDefinitions = require(ReplicatedStorage.Shared.CropDefinitions)
local ToolDefinitions = require(ReplicatedStorage.Shared.ToolDefinitions)
local MachineDefinitions = require(ReplicatedStorage.Shared.MachineDefinitions)
local PetDefinitions = require(ReplicatedStorage.Shared.PetDefinitions)
local Format = require(ReplicatedStorage.Shared.Format)

local EconomyService = {
	MarketMultipliers = {},
}

local rarityRanges = {
	Common = { 0.9, 1.15 },
	Uncommon = { 0.85, 1.2 },
	Rare = { 0.82, 1.28 },
	Epic = { 0.8, 1.35 },
	Legendary = { 0.76, 1.45 },
}

function EconomyService:Init(context)
	self.Context = context
	self:RollMarket()
end

function EconomyService:Start()
	task.spawn(function()
		while true do
			task.wait(180)
			self:RollMarket()
		end
	end)
end

function EconomyService:RollMarket()
	for cropId, crop in pairs(CropDefinitions) do
		local range = rarityRanges[crop.Rarity]
		local roll = range[1] + (math.random() * (range[2] - range[1]))
		self.MarketMultipliers[cropId] = math.floor(roll * 100) / 100
	end

	if self.Context and self.Context.Services.InteractionService and self.Context.Services.InteractionService.StateEvent then
		self.Context.Services.InteractionService:PushMarketAll()
	end
end

function EconomyService:GetSellValue(player, cropId, mutation, quantity)
	local crop = CropDefinitions[cropId]
	local multiplier = self.MarketMultipliers[cropId] or 1
	local mutationBoost = Constants.MutationMultipliers[mutation or "None"] or 1
	local buffs = self.Context.Services.ProgressionService:GetPetBuffs(player)
	local sellBonus = 1 + (buffs.SellBonus or 0)
	return math.floor(crop.BaseSell * multiplier * mutationBoost * quantity * sellBonus)
end

function EconomyService:BuildMarketSnapshot(player)
	local toolService = self.Context.Services.ToolService
	local nextTier = toolService:GetNextTier(player)

	local crops = {}
	for cropId, crop in pairs(CropDefinitions) do
		crops[cropId] = {
			DisplayName = crop.DisplayName,
			SeedPrice = crop.SeedPrice,
			BaseSell = crop.BaseSell,
			Multiplier = self.MarketMultipliers[cropId] or 1,
			Rarity = crop.Rarity,
			UnlockLevel = crop.UnlockLevel,
		}
	end

	local machines = {}
	for machineId, machine in pairs(MachineDefinitions) do
		machines[machineId] = machine
	end

	local pets = {}
	for petId, pet in pairs(PetDefinitions) do
		pets[petId] = {
			DisplayName = pet.DisplayName,
			CostGems = pet.CostGems,
			Description = pet.Description,
		}
	end

	return {
		Crops = crops,
		NextToolTier = nextTier,
		NextToolCost = nextTier and ToolDefinitions[nextTier].UpgradeCost or nil,
		Machines = machines,
		Pets = pets,
		DailyRewards = Constants.DailyRewards,
	}
end

function EconomyService:BuySeed(player, seedId, quantity)
	quantity = math.max(1, math.floor(quantity or 1))
	local crop = CropDefinitions[seedId]
	local profile = self.Context.Services.DataService:GetProfile(player)

	if not crop then
		return false
	end

	if not profile.UnlockedSeeds[seedId] then
		self.Context.Services.InteractionService:Notify(player, "That seed has not been unlocked yet.")
		return false
	end

	local cost = crop.SeedPrice * quantity
	if not self.Context.Services.DataService:SpendCurrency(player, "Coins", cost) then
		self.Context.Services.InteractionService:Notify(player, "Not enough coins.")
		return false
	end

	self.Context.Services.DataService:AdjustSeed(player, seedId, quantity)
	self.Context.Services.InteractionService:Notify(player, ("Bought %dx %s seeds."):format(quantity, crop.DisplayName))
	self.Context.Services.ProgressionService:SyncLeaderstats(player)
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function EconomyService:SellProduce(player, produceKey, quantity)
	quantity = math.max(1, math.floor(quantity or 1))
	local cropId, mutation = Format.SplitProduceKey(produceKey)
	local profile = self.Context.Services.DataService:GetProfile(player)

	if (profile.Produce[produceKey] or 0) < quantity then
		self.Context.Services.InteractionService:Notify(player, "You do not have enough of that crop stack.")
		return false
	end

	local sellValue = self:GetSellValue(player, cropId, mutation, quantity)
	self.Context.Services.DataService:AdjustProduce(player, produceKey, -quantity)
	self.Context.Services.DataService:AdjustCurrency(player, "Coins", sellValue)
	self.Context.Services.ProgressionService:SyncLeaderstats(player)
	self.Context.Services.InteractionService:Notify(player, ("Sold for %s coins."):format(Format.Commas(sellValue)))
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function EconomyService:UpgradeTools(player)
	local nextTier = self.Context.Services.ToolService:GetNextTier(player)
	if not nextTier then
		self.Context.Services.InteractionService:Notify(player, "Your tools are already maxed out.")
		return false
	end

	local cost = ToolDefinitions[nextTier].UpgradeCost
	if not self.Context.Services.DataService:SpendCurrency(player, "Coins", cost) then
		self.Context.Services.InteractionService:Notify(player, "Not enough coins for that upgrade.")
		return false
	end

	self.Context.Services.DataService:SetToolTier(player, nextTier)
	self.Context.Services.ToolService:RefreshTools(player)
	self.Context.Services.ProgressionService:SyncLeaderstats(player)
	self.Context.Services.InteractionService:Notify(player, nextTier .. " tools unlocked.")
	self.Context.Services.InteractionService:PushProfile(player)
	self.Context.Services.InteractionService:PushMarket(player)
	return true
end

function EconomyService:BuyMachine(player, machineId)
	local machine = MachineDefinitions[machineId]
	if not machine then
		return false
	end

	if not self.Context.Services.DataService:SpendCurrency(player, "Coins", machine.Cost) then
		self.Context.Services.InteractionService:Notify(player, "Not enough coins for that machine.")
		return false
	end

	self.Context.Services.DataService:AdjustMachine(player, machineId, 1)
	self.Context.Services.InteractionService:Notify(player, machine.DisplayName .. " added to your machine inventory.")
	self.Context.Services.ProgressionService:SyncLeaderstats(player)
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function EconomyService:BuyPet(player, petId)
	local pet = PetDefinitions[petId]
	if not pet then
		return false
	end

	if self.Context.Services.DataService:OwnsPet(player, petId) then
		self.Context.Services.InteractionService:Notify(player, "You already own that pet.")
		return false
	end

	if pet.CostGems > 0 and not self.Context.Services.DataService:SpendCurrency(player, "Gems", pet.CostGems) then
		self.Context.Services.InteractionService:Notify(player, "Not enough gems.")
		return false
	end

	self.Context.Services.DataService:UnlockPet(player, petId)
	self.Context.Services.InteractionService:Notify(player, pet.DisplayName .. " joined your farm.")
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function EconomyService:EquipPet(player, petId)
	if not self.Context.Services.DataService:OwnsPet(player, petId) then
		self.Context.Services.InteractionService:Notify(player, "You do not own that pet.")
		return false
	end

	self.Context.Services.DataService:SetEquippedPet(player, petId)
	self.Context.Services.InteractionService:Notify(player, PetDefinitions[petId].DisplayName .. " is now active.")
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

function EconomyService:ClaimDailyReward(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	local now = os.date("!*t")
	local todayKey = Constants.GetDailyKey(now)

	if profile.Daily.LastClaimKey == todayKey then
		self.Context.Services.InteractionService:Notify(player, "Daily reward already claimed today.")
		return false
	end

	local rewardIndex = (profile.Daily.Streak % #Constants.DailyRewards) + 1
	local reward = Constants.DailyRewards[rewardIndex]
	local newStreak = rewardIndex

	if reward.Coins then
		self.Context.Services.DataService:AdjustCurrency(player, "Coins", reward.Coins)
	end

	if reward.Gems then
		self.Context.Services.DataService:AdjustCurrency(player, "Gems", reward.Gems)
	end

	self.Context.Services.DataService:SetDailyClaim(player, todayKey, newStreak)
	self.Context.Services.ProgressionService:SyncLeaderstats(player)
	self.Context.Services.InteractionService:Notify(player, "Daily reward claimed.")
	self.Context.Services.InteractionService:PushProfile(player)
	return true
end

return EconomyService
