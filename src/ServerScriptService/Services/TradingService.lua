local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local TradingService = {
	PendingRequests = {},
	ActiveTrades = {},
	Auctions = {},
	NextTradeId = 1,
	NextAuctionId = 1,
}

local function deepCopy(source)
	local output = {}
	for key, value in pairs(source) do
		if typeof(value) == "table" then
			output[key] = deepCopy(value)
		else
			output[key] = value
		end
	end
	return output
end

function TradingService:Init(context)
	self.Context = context
end

function TradingService:GetTradeForPlayer(player)
	local tradeId = self.ActiveTrades[player.UserId]
	return tradeId and self.ActiveTrades[tradeId] or nil
end

function TradingService:BuildTradeSnapshot(trade)
	local function buildSide(userId)
		local player = Players:GetPlayerByUserId(userId)
		local offer = trade.Offers[userId]
		return {
			UserId = userId,
			Name = player and player.DisplayName or tostring(userId),
			Items = deepCopy(offer.Items),
			Coins = offer.Coins,
			Locked = offer.Locked,
			Confirmed = offer.Confirmed,
		}
	end

	return {
		TradeId = trade.Id,
		Left = buildSide(trade.PlayerA),
		Right = buildSide(trade.PlayerB),
	}
end

function TradingService:PushTrade(trade)
	local packet = {
		Type = "TradeUpdate",
		Trade = self:BuildTradeSnapshot(trade),
	}

	for _, userId in ipairs({ trade.PlayerA, trade.PlayerB }) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			self.Context.Services.InteractionService:Send(player, packet)
		end
	end
end

function TradingService:CloseTrade(trade, reason)
	for _, userId in ipairs({ trade.PlayerA, trade.PlayerB }) do
		local player = Players:GetPlayerByUserId(userId)
		self.ActiveTrades[userId] = nil
		if player then
			self.Context.Services.InteractionService:Send(player, {
				Type = "TradeClosed",
				Reason = reason,
			})
		end
	end

	self.ActiveTrades[trade.Id] = nil
end

function TradingService:RequestTrade(player, targetUserId)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		self.Context.Services.InteractionService:Notify(player, "That player is not available.")
		return false
	end

	if self:GetTradeForPlayer(player) or self:GetTradeForPlayer(target) then
		self.Context.Services.InteractionService:Notify(player, "One of you is already trading.")
		return false
	end

	self.PendingRequests[targetUserId] = player.UserId
	self.Context.Services.InteractionService:Notify(player, "Trade request sent.")
	self.Context.Services.InteractionService:Send(target, {
		Type = "TradeRequest",
		FromUserId = player.UserId,
		FromName = player.DisplayName,
	})
	return true
end

function TradingService:RespondTrade(player, requesterUserId, accepted)
	if self.PendingRequests[player.UserId] ~= requesterUserId then
		return false
	end

	self.PendingRequests[player.UserId] = nil
	local requester = Players:GetPlayerByUserId(requesterUserId)
	if not requester then
		return false
	end

	if not accepted then
		self.Context.Services.InteractionService:Notify(requester, player.DisplayName .. " declined your trade request.")
		return true
	end

	local trade = {
		Id = self.NextTradeId,
		PlayerA = requesterUserId,
		PlayerB = player.UserId,
		Offers = {
			[requesterUserId] = { Items = {}, Coins = 0, Locked = false, Confirmed = false },
			[player.UserId] = { Items = {}, Coins = 0, Locked = false, Confirmed = false },
		},
	}
	self.NextTradeId += 1
	self.ActiveTrades[trade.Id] = trade
	self.ActiveTrades[requesterUserId] = trade.Id
	self.ActiveTrades[player.UserId] = trade.Id
	self:PushTrade(trade)
	return true
end

function TradingService:SetTradeOffer(player, items, coins)
	local trade = self:GetTradeForPlayer(player)
	if not trade then
		return false
	end

	local offer = trade.Offers[player.UserId]
	local otherUserId = trade.PlayerA == player.UserId and trade.PlayerB or trade.PlayerA
	local otherOffer = trade.Offers[otherUserId]
	local profile = self.Context.Services.DataService:GetProfile(player)

	offer.Items = {}
	offer.Coins = math.max(0, math.floor(coins or 0))
	offer.Locked = false
	offer.Confirmed = false
	otherOffer.Locked = false
	otherOffer.Confirmed = false

	for produceKey, quantity in pairs(items or {}) do
		quantity = math.max(0, math.floor(quantity))
		if quantity > 0 and (profile.Produce[produceKey] or 0) >= quantity then
			offer.Items[produceKey] = quantity
		end
	end

	if offer.Coins > profile.Coins then
		offer.Coins = profile.Coins
	end

	self:PushTrade(trade)
	return true
end

function TradingService:SetTradeLocked(player, locked)
	local trade = self:GetTradeForPlayer(player)
	if not trade then
		return false
	end

	trade.Offers[player.UserId].Locked = locked
	if not locked then
		trade.Offers[player.UserId].Confirmed = false
	end

	self:PushTrade(trade)
	return true
end

function TradingService:ConfirmTrade(player)
	local trade = self:GetTradeForPlayer(player)
	if not trade then
		return false
	end

	local offer = trade.Offers[player.UserId]
	if not offer.Locked then
		self.Context.Services.InteractionService:Notify(player, "Lock your offer first.")
		return false
	end

	offer.Confirmed = true
	self:PushTrade(trade)

	local otherUserId = trade.PlayerA == player.UserId and trade.PlayerB or trade.PlayerA
	local otherOffer = trade.Offers[otherUserId]
	if not (otherOffer.Locked and otherOffer.Confirmed) then
		return true
	end

	local dataService = self.Context.Services.DataService
	local playerA = Players:GetPlayerByUserId(trade.PlayerA)
	local playerB = Players:GetPlayerByUserId(trade.PlayerB)
	local profileA = playerA and dataService:GetProfile(playerA)
	local profileB = playerB and dataService:GetProfile(playerB)
	if not profileA or not profileB then
		self:CloseTrade(trade, "A player left.")
		return false
	end

	for produceKey, quantity in pairs(trade.Offers[trade.PlayerA].Items) do
		if (profileA.Produce[produceKey] or 0) < quantity then
			self:CloseTrade(trade, "Trade cancelled because an item was missing.")
			return false
		end
	end

	for produceKey, quantity in pairs(trade.Offers[trade.PlayerB].Items) do
		if (profileB.Produce[produceKey] or 0) < quantity then
			self:CloseTrade(trade, "Trade cancelled because an item was missing.")
			return false
		end
	end

	if profileA.Coins < trade.Offers[trade.PlayerA].Coins or profileB.Coins < trade.Offers[trade.PlayerB].Coins then
		self:CloseTrade(trade, "Trade cancelled because a coin offer changed.")
		return false
	end

	for produceKey, quantity in pairs(trade.Offers[trade.PlayerA].Items) do
		dataService:AdjustProduce(playerA, produceKey, -quantity)
		dataService:AdjustProduce(playerB, produceKey, quantity)
	end

	for produceKey, quantity in pairs(trade.Offers[trade.PlayerB].Items) do
		dataService:AdjustProduce(playerB, produceKey, -quantity)
		dataService:AdjustProduce(playerA, produceKey, quantity)
	end

	dataService:AdjustCurrency(playerA, "Coins", -trade.Offers[trade.PlayerA].Coins)
	dataService:AdjustCurrency(playerB, "Coins", trade.Offers[trade.PlayerA].Coins)
	dataService:AdjustCurrency(playerB, "Coins", -trade.Offers[trade.PlayerB].Coins)
	dataService:AdjustCurrency(playerA, "Coins", trade.Offers[trade.PlayerB].Coins)

	self.Context.Services.InteractionService:PushProfile(playerA)
	self.Context.Services.InteractionService:PushProfile(playerB)
	self:CloseTrade(trade, "Trade completed.")
	return true
end

function TradingService:GetAuctionSnapshot()
	local listings = {}
	for _, listing in pairs(self.Auctions) do
		table.insert(listings, {
			Id = listing.Id,
			SellerUserId = listing.SellerUserId,
			SellerName = listing.SellerName,
			ProduceKey = listing.ProduceKey,
			Quantity = listing.Quantity,
			Price = listing.Price,
		})
	end

	table.sort(listings, function(a, b)
		return a.Id > b.Id
	end)

	return listings
end

function TradingService:CreateAuction(player, produceKey, quantity, price)
	local profile = self.Context.Services.DataService:GetProfile(player)
	quantity = math.max(1, math.floor(quantity or 1))
	price = math.max(10, math.floor(price or 10))

	local listingCount = 0
	for _, listing in pairs(self.Auctions) do
		if listing.SellerUserId == player.UserId then
			listingCount += 1
		end
	end

	if listingCount >= Constants.AuctionListingLimit then
		self.Context.Services.InteractionService:Notify(player, "You already have too many active listings.")
		return false
	end

	if (profile.Produce[produceKey] or 0) < quantity then
		self.Context.Services.InteractionService:Notify(player, "You do not own enough of that crop stack.")
		return false
	end

	self.Context.Services.DataService:AdjustProduce(player, produceKey, -quantity)
	self.Auctions[self.NextAuctionId] = {
		Id = self.NextAuctionId,
		SellerUserId = player.UserId,
		SellerName = player.DisplayName,
		ProduceKey = produceKey,
		Quantity = quantity,
		Price = price,
	}
	self.NextAuctionId += 1

	self.Context.Services.InteractionService:Notify(player, "Auction listing created.")
	self.Context.Services.InteractionService:PushProfile(player)
	self.Context.Services.InteractionService:PushAuctions()
	return true
end

function TradingService:BuyAuction(player, listingId)
	local listing = self.Auctions[listingId]
	if not listing then
		return false
	end

	if listing.SellerUserId == player.UserId then
		self.Context.Services.InteractionService:Notify(player, "You cannot buy your own listing.")
		return false
	end

	if not self.Context.Services.DataService:SpendCurrency(player, "Coins", listing.Price) then
		self.Context.Services.InteractionService:Notify(player, "Not enough coins.")
		return false
	end

	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	if seller then
		self.Context.Services.DataService:AdjustCurrency(seller, "Coins", math.floor(listing.Price * Constants.AuctionFeeMultiplier))
		self.Context.Services.InteractionService:PushProfile(seller)
		self.Context.Services.InteractionService:Notify(seller, player.DisplayName .. " bought one of your auction listings.")
	end

	self.Context.Services.DataService:AdjustProduce(player, listing.ProduceKey, listing.Quantity)
	self.Auctions[listingId] = nil
	self.Context.Services.InteractionService:PushProfile(player)
	self.Context.Services.InteractionService:PushAuctions()
	return true
end

function TradingService:HandlePlayerRemoving(player)
	self.PendingRequests[player.UserId] = nil
	for targetUserId, requesterUserId in pairs(self.PendingRequests) do
		if requesterUserId == player.UserId then
			self.PendingRequests[targetUserId] = nil
		end
	end

	local trade = self:GetTradeForPlayer(player)
	if trade then
		self:CloseTrade(trade, player.DisplayName .. " left the trade.")
	end

	for listingId, listing in pairs(self.Auctions) do
		if listing.SellerUserId == player.UserId then
			self.Context.Services.DataService:AdjustProduce(player, listing.ProduceKey, listing.Quantity)
			self.Auctions[listingId] = nil
		end
	end
end

return TradingService
