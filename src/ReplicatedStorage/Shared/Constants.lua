local Constants = {
	PlotCount = 24,
	PlotRows = 4,
	PlotColumns = 6,
	PlotCellRows = 8,
	PlotCellColumns = 8,
	PlotCellSize = 6,
	PlotSpacing = 64,
	PlotOrigin = Vector3.new(-160, 0, -140),
	PlotPathOffset = 12,
	FarmBasePower = 10,
	FarmPowerPerLevel = 2,
	CropTickRate = 1,
	ContestLengthSeconds = 300,
	ContestBreakSeconds = 180,
	AuctionListingLimit = 15,
	AuctionFeeMultiplier = 0.92,
	DailyRewards = {
		{ Coins = 300 },
		{ Coins = 450 },
		{ Gems = 6 },
		{ Coins = 750 },
		{ Gems = 10 },
		{ Coins = 1200 },
		{ Gems = 18 },
	},
	MutationWeights = {
		None = 78,
		Golden = 12,
		Giant = 6,
		Rainbow = 3,
		Explosive = 1,
	},
	MutationMultipliers = {
		None = 1,
		Golden = 2.2,
		Giant = 2.8,
		Rainbow = 4.5,
		Explosive = 6,
	},
	ToolKinds = {
		"Hoe",
		"WateringCan",
		"HarvestTool",
	},
	ToolTiers = {
		"Starter",
		"Copper",
		"Iron",
		"Diamond",
		"Mythic",
	},
	BiomeOrder = {
		"Forest",
		"CrystalCave",
		"Volcano",
		"SkyIsland",
	},
}

function Constants.GetLevelXP(level)
	return 100 + ((level - 1) * 55)
end

function Constants.GetDailyKey(now)
	return string.format("%d-%02d-%02d", now.Year, now.Month, now.Day)
end

return Constants
