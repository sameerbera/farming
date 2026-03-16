local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local CompetitionService = {
	State = {
		Active = false,
		Scores = {},
		EndsAt = 0,
		StartsAt = 0,
	},
}

local mutationPoints = {
	Golden = 2,
	Giant = 3,
	Rainbow = 5,
	Explosive = 7,
}

function CompetitionService:Init(context)
	self.Context = context
	self.State.StartsAt = os.time() + Constants.ContestBreakSeconds
end

function CompetitionService:Start()
	task.spawn(function()
		while true do
			task.wait(1)
			self:Tick()
		end
	end)
end

function CompetitionService:GetTopScores()
	local scores = {}
	for userId, points in pairs(self.State.Scores) do
		local player = Players:GetPlayerByUserId(userId)
		table.insert(scores, {
			UserId = userId,
			Name = player and player.DisplayName or tostring(userId),
			Points = points,
		})
	end

	table.sort(scores, function(a, b)
		return a.Points > b.Points
	end)

	local trimmed = {}
	for index = 1, math.min(#scores, 5) do
		trimmed[index] = scores[index]
	end
	return trimmed
end

function CompetitionService:GetSnapshot()
	local now = os.time()
	return {
		Active = self.State.Active,
		SecondsRemaining = math.max(0, (self.State.Active and self.State.EndsAt or self.State.StartsAt) - now),
		TopScores = self:GetTopScores(),
	}
end

function CompetitionService:PushState()
	local snapshot = self:GetSnapshot()
	self.Context.World.ContestLabel.Text = snapshot.Active and ("Mutation Clash\n%ds left"):format(snapshot.SecondsRemaining) or ("Mutation Clash\nNext round in %ds"):format(snapshot.SecondsRemaining)
	self.Context.Services.InteractionService:PushContest()
end

function CompetitionService:StartContest()
	self.State.Active = true
	self.State.Scores = {}
	self.State.EndsAt = os.time() + Constants.ContestLengthSeconds
	self:PushState()
end

function CompetitionService:FinishContest()
	local podium = self:GetTopScores()
	local rewards = {
		{ Gems = 15, Coins = 2500 },
		{ Gems = 8, Coins = 1400 },
		{ Gems = 4, Coins = 700 },
	}

	for place = 1, math.min(3, #podium) do
		local entry = podium[place]
		local player = Players:GetPlayerByUserId(entry.UserId)
		if player then
			local reward = rewards[place]
			self.Context.Services.DataService:AdjustCurrency(player, "Gems", reward.Gems)
			self.Context.Services.DataService:AdjustCurrency(player, "Coins", reward.Coins)
			if place == 1 then
				self.Context.Services.DataService:AdjustStat(player, "ContestWins", 1)
			end
			self.Context.Services.InteractionService:Notify(player, ("Contest finished. Place #%d rewards delivered."):format(place))
			self.Context.Services.InteractionService:PushProfile(player)
		end
	end

	self.State.Active = false
	self.State.StartsAt = os.time() + Constants.ContestBreakSeconds
	self.State.Scores = {}
	self:PushState()
end

function CompetitionService:Tick()
	local now = os.time()
	if self.State.Active then
		if now >= self.State.EndsAt then
			self:FinishContest()
		elseif now % 5 == 0 then
			self:PushState()
		end
	elseif now >= self.State.StartsAt then
		self:StartContest()
	end
end

function CompetitionService:RecordHarvest(player, _, mutation, quantity)
	if not self.State.Active then
		return
	end

	local points = mutationPoints[mutation]
	if not points then
		return
	end

	self.State.Scores[player.UserId] = (self.State.Scores[player.UserId] or 0) + (points * quantity)
end

return CompetitionService
