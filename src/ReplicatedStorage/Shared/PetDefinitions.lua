local Pets = {
	Chick = {
		Id = "Chick",
		DisplayName = "Sunny Chick",
		CostGems = 0,
		Buffs = {
			SellBonus = 0.05,
		},
		Description = "A friendly starter pet that boosts sell prices slightly.",
	},
	Bee = {
		Id = "Bee",
		DisplayName = "Mutation Bee",
		CostGems = 55,
		Buffs = {
			MutationBonus = 0.025,
		},
		Description = "Improves the odds of golden, rainbow and giant crops.",
	},
	Fox = {
		Id = "Fox",
		DisplayName = "Swift Fox",
		CostGems = 80,
		Buffs = {
			GrowthBonus = 0.1,
		},
		Description = "Speeds up crop growth across your whole farm.",
	},
	Golem = {
		Id = "Golem",
		DisplayName = "Power Golem",
		CostGems = 120,
		Buffs = {
			PowerBonus = 5,
		},
		Description = "Adds more power capacity for automation machines.",
	},
	Phoenix = {
		Id = "Phoenix",
		DisplayName = "Ash Phoenix",
		CostGems = 180,
		Buffs = {
			SellBonus = 0.15,
			GrowthBonus = 0.12,
		},
		Description = "A premium pet with strong profit and growth buffs.",
	},
}

return Pets
