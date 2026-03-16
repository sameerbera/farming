local Machines = {
	Sprinkler = {
		Id = "Sprinkler",
		DisplayName = "Auto Water Sprinkler",
		Cost = 1250,
		PowerCost = 2,
		Range = 14,
		Description = "Waters nearby crops every few seconds.",
		Color = Color3.fromRGB(84, 194, 255),
	},
	HarvesterDrone = {
		Id = "HarvesterDrone",
		DisplayName = "Harvester Drone",
		Cost = 3400,
		PowerCost = 4,
		Range = 20,
		Description = "Harvests mature crops in its radius.",
		Color = Color3.fromRGB(255, 196, 70),
	},
	GrowthAccelerator = {
		Id = "GrowthAccelerator",
		DisplayName = "Growth Accelerator",
		Cost = 4200,
		PowerCost = 5,
		Range = 16,
		SpeedMultiplier = 0.7,
		Description = "Speeds up crop growth in its radius.",
		Color = Color3.fromRGB(111, 255, 134),
	},
	SeedDuplicator = {
		Id = "SeedDuplicator",
		DisplayName = "Seed Duplicator",
		Cost = 5600,
		PowerCost = 6,
		Range = 22,
		DuplicateChance = 0.2,
		Description = "Sometimes duplicates seeds when crops are harvested nearby.",
		Color = Color3.fromRGB(233, 120, 255),
	},
}

return Machines
