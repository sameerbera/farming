local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InteractionService = {}

function InteractionService:Init(context)
	self.Context = context
	self.StateEvent = context.RemoteFolder:WaitForChild(Remotes.StateEventName)
	self.ActionEvent = context.RemoteFolder:WaitForChild(Remotes.ActionEventName)
	self.RequestStateFunction = context.RemoteFolder:WaitForChild(Remotes.RequestStateFunctionName)
end

function InteractionService:Send(player, payload)
	self.StateEvent:FireClient(player, payload)
end

function InteractionService:Notify(player, message)
	self:Send(player, {
		Type = "Notification",
		Message = message,
	})
end

function InteractionService:OpenPanel(player, panel)
	self:Send(player, {
		Type = "OpenPanel",
		Panel = panel,
	})
end

function InteractionService:BuildFullState(player)
	local plotId = self.Context.Services.PlotService:GetPlotIdForPlayer(player)
	return {
		Profile = self.Context.Services.DataService:BuildProfileSnapshot(player),
		Market = self.Context.Services.EconomyService:BuildMarketSnapshot(player),
		Auctions = self.Context.Services.TradingService:GetAuctionSnapshot(),
		Contest = self.Context.Services.CompetitionService:GetSnapshot(),
		TradePlayers = self.Context.Services.PlotService:GetTradeEligiblePlayers(player),
		Runtime = {
			PlotId = plotId,
			PowerUsage = plotId and self.Context.Services.AutomationService:GetPowerUsage(plotId) or 0,
			PowerCapacity = self.Context.Services.ProgressionService:GetPowerCapacity(player),
		},
	}
end

function InteractionService:PushFullState(player)
	self:Send(player, {
		Type = "FullState",
		State = self:BuildFullState(player),
	})
end

function InteractionService:PushProfile(player)
	local plotId = self.Context.Services.PlotService:GetPlotIdForPlayer(player)
	self:Send(player, {
		Type = "ProfileUpdate",
		Profile = self.Context.Services.DataService:BuildProfileSnapshot(player),
		Runtime = {
			PlotId = plotId,
			PowerUsage = plotId and self.Context.Services.AutomationService:GetPowerUsage(plotId) or 0,
			PowerCapacity = self.Context.Services.ProgressionService:GetPowerCapacity(player),
		},
	})
end

function InteractionService:PushMarket(player)
	self:Send(player, {
		Type = "MarketUpdate",
		Market = self.Context.Services.EconomyService:BuildMarketSnapshot(player),
	})
end

function InteractionService:PushMarketAll()
	for _, player in ipairs(Players:GetPlayers()) do
		self:PushMarket(player)
	end
end

function InteractionService:PushAuctions()
	local snapshot = self.Context.Services.TradingService:GetAuctionSnapshot()
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, {
			Type = "AuctionUpdate",
			Auctions = snapshot,
		})
	end
end

function InteractionService:PushContest()
	local snapshot = self.Context.Services.CompetitionService:GetSnapshot()
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, {
			Type = "ContestUpdate",
			Contest = snapshot,
		})
	end
end

function InteractionService:PushTradeRoster()
	for _, player in ipairs(Players:GetPlayers()) do
		self:Send(player, {
			Type = "TradeRoster",
			Players = self.Context.Services.PlotService:GetTradeEligiblePlayers(player),
		})
	end
end

function InteractionService:HandlePrompt(player, prompt)
	local interactionType = prompt:GetAttribute("InteractionType")

	if interactionType == "Portal" then
		local biomeId = prompt:GetAttribute("BiomeId")
		local profile = self.Context.Services.DataService:GetProfile(player)
		if not profile.UnlockedBiomes[biomeId] then
			self:Notify(player, "That biome unlocks later in progression.")
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(self.Context.World.BiomeSpawns[biomeId])
		end
		return
	end

	self:OpenPanel(player, interactionType)
end

function InteractionService:HandleAction(player, payload)
	local actionType = payload.Type

	if actionType == "SelectSeed" then
		self.Context.Services.PlotService:SetSelectedSeed(player, payload.SeedId)
	elseif actionType == "SelectMachine" then
		self.Context.Services.PlotService:SetSelectedMachine(player, payload.MachineId)
	elseif actionType == "InteractCell" then
		self.Context.Services.PlotService:HandleCellClick(player, payload.PlotId, payload.CellId)
	elseif actionType == "InteractMachinePad" then
		self.Context.Services.PlotService:HandleMachinePadClick(player, payload.PlotId, payload.PadId)
	elseif actionType == "BuySeed" then
		self.Context.Services.EconomyService:BuySeed(player, payload.SeedId, payload.Quantity)
	elseif actionType == "SellProduce" then
		self.Context.Services.EconomyService:SellProduce(player, payload.ProduceKey, payload.Quantity)
	elseif actionType == "UpgradeTools" then
		self.Context.Services.EconomyService:UpgradeTools(player)
	elseif actionType == "BuyMachine" then
		self.Context.Services.EconomyService:BuyMachine(player, payload.MachineId)
	elseif actionType == "ClaimDailyReward" then
		self.Context.Services.EconomyService:ClaimDailyReward(player)
	elseif actionType == "BuyPet" then
		self.Context.Services.EconomyService:BuyPet(player, payload.PetId)
	elseif actionType == "EquipPet" then
		self.Context.Services.EconomyService:EquipPet(player, payload.PetId)
	elseif actionType == "RequestTrade" then
		self.Context.Services.TradingService:RequestTrade(player, payload.TargetUserId)
	elseif actionType == "RespondTrade" then
		self.Context.Services.TradingService:RespondTrade(player, payload.RequesterUserId, payload.Accepted)
	elseif actionType == "SetTradeOffer" then
		self.Context.Services.TradingService:SetTradeOffer(player, payload.Items or {}, payload.Coins or 0)
	elseif actionType == "SetTradeLocked" then
		self.Context.Services.TradingService:SetTradeLocked(player, payload.Locked == true)
	elseif actionType == "ConfirmTrade" then
		self.Context.Services.TradingService:ConfirmTrade(player)
	elseif actionType == "CreateAuction" then
		self.Context.Services.TradingService:CreateAuction(player, payload.ProduceKey, payload.Quantity, payload.Price)
	elseif actionType == "BuyAuction" then
		self.Context.Services.TradingService:BuyAuction(player, payload.ListingId)
	elseif actionType == "Refresh" then
		self:PushFullState(player)
	end
end

function InteractionService:Start()
	self.ActionEvent.OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" then
			return
		end
		self:HandleAction(player, payload)
	end)

	self.RequestStateFunction.OnServerInvoke = function(player)
		return self:BuildFullState(player)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt and prompt:GetAttribute("InteractionType") then
			self:HandlePrompt(player, prompt)
		end
	end)
end

return InteractionService
