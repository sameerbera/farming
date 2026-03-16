local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)
local BiomeDefinitions = require(ReplicatedStorage.Shared.BiomeDefinitions)

local WorldBuilder = {}

local function createPart(properties)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = properties.Material or Enum.Material.SmoothPlastic
	part.Color = properties.Color or Color3.fromRGB(255, 255, 255)
	part.Size = properties.Size or Vector3.new(4, 1, 4)
	part.Position = properties.Position or Vector3.new()
	part.Shape = properties.Shape or Enum.PartType.Block
	part.Name = properties.Name or "Part"
	part.Parent = properties.Parent
	part.CanCollide = properties.CanCollide ~= false
	part.Transparency = properties.Transparency or 0
	return part
end

local function addBillboard(part, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard

	return label
end

local function addSurfaceText(part, face, text)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = face
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 35
	surfaceGui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 247, 215)
	label.Parent = surfaceGui
	return label
end

local function createPrompt(part, actionText, objectText, interactionType, extraAttributes)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = part
	prompt:SetAttribute("InteractionType", interactionType)

	if extraAttributes then
		for key, value in pairs(extraAttributes) do
			prompt:SetAttribute(key, value)
		end
	end

	return prompt
end

local function createCylinder(parent, position, size, color, material)
	local part = createPart({
		Parent = parent,
		Position = position,
		Size = size,
		Color = color,
		Material = material,
		Shape = Enum.PartType.Cylinder,
	})
	part.Orientation = Vector3.new(0, 0, 90)
	return part
end

function WorldBuilder:Init(context)
	self.Context = context
end

local function buildZoneDecor(zoneModel, center, color, material, height, treeCount)
	local base = createPart({
		Name = "ZoneBase",
		Parent = zoneModel,
		Position = center,
		Size = Vector3.new(90, 8, 90),
		Color = color,
		Material = material,
	})

	for index = 1, treeCount do
		local angle = (math.pi * 2) * (index / treeCount)
		local radius = 18 + ((index % 4) * 8)
		local trunk = createPart({
			Name = "Decor",
			Parent = zoneModel,
			Position = center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius),
			Size = Vector3.new(3, 12, 3),
			Color = Color3.fromRGB(97, 68, 44),
			Material = Enum.Material.Wood,
		})

		local canopy = createPart({
			Name = "DecorTop",
			Parent = zoneModel,
			Position = trunk.Position + Vector3.new(0, 10, 0),
			Size = Vector3.new(11, 10, 11),
			Color = color:Lerp(Color3.new(1, 1, 1), 0.2),
			Material = Enum.Material.Grass,
			Shape = Enum.PartType.Ball,
		})

		if material == Enum.Material.Neon then
			canopy.Material = Enum.Material.Neon
			canopy.Shape = Enum.PartType.Block
		end
	end

	return base
end

function WorldBuilder:BuildWorld()
	local existing = Workspace:FindFirstChild("FarmMutationWorld")
	if existing then
		existing:Destroy()
	end

	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate then
		defaultBaseplate:Destroy()
	end

	local world = {
		Folder = Instance.new("Folder"),
		Plots = {},
		Stations = {},
		Portals = {},
		BiomeSpawns = {},
	}
	world.Folder.Name = "FarmMutationWorld"
	world.Folder.Parent = Workspace

	createPart({
		Name = "Ground",
		Parent = world.Folder,
		Position = Vector3.new(0, -6, 0),
		Size = Vector3.new(900, 12, 900),
		Color = Color3.fromRGB(74, 138, 74),
		Material = Enum.Material.Grass,
	})

	local hub = createCylinder(world.Folder, Vector3.new(0, 1, 0), Vector3.new(120, 6, 120), Color3.fromRGB(233, 206, 157), Enum.Material.Sandstone)
	hub.Name = "TownHub"

	local fountain = createCylinder(world.Folder, Vector3.new(0, 4, 0), Vector3.new(18, 2, 18), Color3.fromRGB(90, 190, 255), Enum.Material.Neon)
	fountain.Name = "Fountain"

	local contestBoard = createPart({
		Name = "ContestBoard",
		Parent = world.Folder,
		Position = Vector3.new(0, 14, -42),
		Size = Vector3.new(28, 16, 2),
		Color = Color3.fromRGB(51, 37, 28),
		Material = Enum.Material.WoodPlanks,
	})
	world.ContestLabel = addSurfaceText(contestBoard, Enum.NormalId.Front, "Mutation Clash")

	local leaderboardBuilding = createPart({
		Name = "LeaderboardBuilding",
		Parent = world.Folder,
		Position = Vector3.new(-42, 8, -20),
		Size = Vector3.new(30, 16, 22),
		Color = Color3.fromRGB(91, 72, 50),
		Material = Enum.Material.WoodPlanks,
	})
	addBillboard(leaderboardBuilding, "Leaderboard Lodge", Color3.fromRGB(255, 245, 187))

	local stationDefinitions = {
		{ Id = "SeedMarket", Label = "Seed Market", Position = Vector3.new(38, 5, 14), Color = Color3.fromRGB(95, 210, 110) },
		{ Id = "ToolShop", Label = "Upgrade Smithy", Position = Vector3.new(24, 5, 36), Color = Color3.fromRGB(255, 188, 95) },
		{ Id = "AutomationShop", Label = "Automation Lab", Position = Vector3.new(-18, 5, 40), Color = Color3.fromRGB(107, 210, 255) },
		{ Id = "Trading", Label = "Trading Zone", Position = Vector3.new(-42, 5, 15), Color = Color3.fromRGB(255, 151, 106) },
		{ Id = "Auction", Label = "Auction Board", Position = Vector3.new(-18, 5, -42), Color = Color3.fromRGB(231, 127, 255) },
		{ Id = "Daily", Label = "Daily Reward Shrine", Position = Vector3.new(17, 5, -44), Color = Color3.fromRGB(255, 246, 145) },
		{ Id = "Pets", Label = "Pet Ranch", Position = Vector3.new(46, 5, -18), Color = Color3.fromRGB(255, 161, 104) },
	}

	for _, station in ipairs(stationDefinitions) do
		local kiosk = createPart({
			Name = station.Id,
			Parent = world.Folder,
			Position = station.Position,
			Size = Vector3.new(12, 10, 12),
			Color = station.Color,
			Material = Enum.Material.SmoothPlastic,
		})
		addBillboard(kiosk, station.Label, Color3.new(1, 1, 1))
		createPrompt(kiosk, "Open", station.Label, station.Id)
		world.Stations[station.Id] = kiosk
	end

	local biomeCenters = {
		Forest = Vector3.new(0, 4, 210),
		CrystalCave = Vector3.new(215, 4, 0),
		Volcano = Vector3.new(-215, 4, 0),
		SkyIsland = Vector3.new(0, 150, -215),
	}

	local portalIndex = 0

	for biomeId, biome in pairs(BiomeDefinitions) do
		portalIndex += 1
		local zoneModel = Instance.new("Model")
		zoneModel.Name = biomeId
		zoneModel.Parent = world.Folder

		local center = biomeCenters[biomeId]
		world.BiomeSpawns[biomeId] = center + Vector3.new(0, 8, 0)

		if biomeId == "Forest" then
			buildZoneDecor(zoneModel, center, Color3.fromRGB(90, 175, 90), Enum.Material.Grass, 12, 12)
		elseif biomeId == "CrystalCave" then
			local base = buildZoneDecor(zoneModel, center, Color3.fromRGB(65, 220, 255), Enum.Material.Slate, 7, 8)
			base.Color = Color3.fromRGB(60, 68, 96)
			for index = 1, 8 do
				local crystal = createPart({
					Name = "Crystal",
					Parent = zoneModel,
					Position = center + Vector3.new(math.cos(index) * 22, 14, math.sin(index) * 20),
					Size = Vector3.new(4, 16, 4),
					Color = Color3.fromRGB(112, 255, 255),
					Material = Enum.Material.Neon,
				})
				crystal.Orientation = Vector3.new(0, index * 22, 12)
			end
		elseif biomeId == "Volcano" then
			local base = buildZoneDecor(zoneModel, center, Color3.fromRGB(76, 50, 46), Enum.Material.Basalt, 8, 10)
			base.Color = Color3.fromRGB(76, 50, 46)
			createCylinder(zoneModel, center + Vector3.new(0, 5, 0), Vector3.new(24, 6, 24), Color3.fromRGB(255, 104, 68), Enum.Material.Neon)
		elseif biomeId == "SkyIsland" then
			local island = buildZoneDecor(zoneModel, center, Color3.fromRGB(183, 225, 255), Enum.Material.SmoothPlastic, 12, 8)
			island.Color = Color3.fromRGB(237, 245, 255)
			for index = 1, 5 do
				createPart({
					Name = "Cloud",
					Parent = zoneModel,
					Position = center + Vector3.new(-30 + (index * 14), 12, 28 - (index * 4)),
					Size = Vector3.new(18, 6, 12),
					Color = Color3.fromRGB(255, 255, 255),
					Material = Enum.Material.SmoothPlastic,
					Shape = Enum.PartType.Ball,
				})
			end
		end

		local portal = createPart({
			Name = biomeId .. "Portal",
			Parent = world.Folder,
			Position = Vector3.new(((portalIndex - 1) * 18) - 28, 3, 66),
			Size = Vector3.new(14, 6, 14),
			Color = biome.Color,
			Material = Enum.Material.Neon,
			Shape = Enum.PartType.Cylinder,
		})
		portal.Orientation = Vector3.new(0, 0, 90)
		addBillboard(portal, biome.DisplayName, biome.Color)
		createPrompt(portal, "Travel", biome.DisplayName, "Portal", { BiomeId = biomeId })
		world.Portals[biomeId] = portal
	end

	local cellRows = Constants.PlotCellRows
	local cellColumns = Constants.PlotCellColumns
	local cellSize = Constants.PlotCellSize
	local plotSizeX = cellColumns * cellSize
	local plotSizeZ = cellRows * cellSize
	local plotIndex = 0

	for row = 1, Constants.PlotRows do
		for column = 1, Constants.PlotColumns do
			plotIndex += 1
			local origin = Constants.PlotOrigin + Vector3.new((column - 1) * Constants.PlotSpacing, 0, (row - 1) * Constants.PlotSpacing)
			local plotModel = Instance.new("Model")
			plotModel.Name = ("Plot_%02d"):format(plotIndex)
			plotModel.Parent = world.Folder

			local base = createPart({
				Name = "PlotBase",
				Parent = plotModel,
				Position = origin,
				Size = Vector3.new(plotSizeX + 18, 2, plotSizeZ + 18),
				Color = Color3.fromRGB(90, 60, 40),
				Material = Enum.Material.Ground,
			})

			local grass = createPart({
				Name = "PlotTop",
				Parent = plotModel,
				Position = origin + Vector3.new(0, 1.5, 0),
				Size = Vector3.new(plotSizeX + 10, 1, plotSizeZ + 10),
				Color = Color3.fromRGB(111, 184, 92),
				Material = Enum.Material.Grass,
			})

			local sign = createPart({
				Name = "Sign",
				Parent = plotModel,
				Position = origin + Vector3.new(0, 8, -(plotSizeZ / 2) - 6),
				Size = Vector3.new(16, 8, 2),
				Color = Color3.fromRGB(87, 67, 49),
				Material = Enum.Material.WoodPlanks,
			})
			local signLabel = addSurfaceText(sign, Enum.NormalId.Front, "Open Plot")

			local spawnPart = createPart({
				Name = "Spawn",
				Parent = plotModel,
				Position = origin + Vector3.new(0, 4, (plotSizeZ / 2) + 6),
				Size = Vector3.new(6, 1, 6),
				Color = Color3.fromRGB(255, 245, 145),
				Material = Enum.Material.Neon,
			})
			spawnPart.Transparency = 0.15

			local cells = {}
			for cellRow = 1, cellRows do
				for cellColumn = 1, cellColumns do
					local cellId = ((cellRow - 1) * cellColumns) + cellColumn
					local offsetX = ((cellColumn - 1) - ((cellColumns - 1) / 2)) * cellSize
					local offsetZ = ((cellRow - 1) - ((cellRows - 1) / 2)) * cellSize
					local cellPart = createPart({
						Name = ("Cell_%02d"):format(cellId),
						Parent = plotModel,
						Position = origin + Vector3.new(offsetX, 2.5, offsetZ),
						Size = Vector3.new(cellSize - 0.3, 1, cellSize - 0.3),
						Color = Color3.fromRGB(114, 84, 61),
						Material = Enum.Material.Ground,
					})
					cellPart:SetAttribute("PlotId", plotIndex)
					cellPart:SetAttribute("CellId", cellId)
					local click = Instance.new("ClickDetector")
					click.MaxActivationDistance = 24
					click.Parent = cellPart
					cells[cellId] = cellPart
				end
			end

			local machinePads = {}
			local padOffsets = {
				Vector3.new(-(plotSizeX / 2) - 8, 2.5, -(plotSizeZ / 2) + 6),
				Vector3.new((plotSizeX / 2) + 8, 2.5, -(plotSizeZ / 2) + 6),
				Vector3.new(-(plotSizeX / 2) - 8, 2.5, 0),
				Vector3.new((plotSizeX / 2) + 8, 2.5, 0),
				Vector3.new(-(plotSizeX / 2) - 8, 2.5, (plotSizeZ / 2) - 6),
				Vector3.new((plotSizeX / 2) + 8, 2.5, (plotSizeZ / 2) - 6),
			}

			for padId, offset in ipairs(padOffsets) do
				local pad = createPart({
					Name = ("MachinePad_%02d"):format(padId),
					Parent = plotModel,
					Position = origin + offset,
					Size = Vector3.new(5, 1, 5),
					Color = Color3.fromRGB(80, 89, 104),
					Material = Enum.Material.Metal,
				})
				pad:SetAttribute("PlotId", plotIndex)
				pad:SetAttribute("PadId", padId)
				addBillboard(pad, "Empty", Color3.fromRGB(220, 235, 255))
				local click = Instance.new("ClickDetector")
				click.MaxActivationDistance = 24
				click.Parent = pad
				machinePads[padId] = pad
			end

			world.Plots[plotIndex] = {
				Id = plotIndex,
				Model = plotModel,
				Base = base,
				Grass = grass,
				Sign = sign,
				SignLabel = signLabel,
				Spawn = spawnPart,
				Cells = cells,
				MachinePads = machinePads,
			}
		end
	end

	return world
end

return WorldBuilder
