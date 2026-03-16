local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ClientApp = {}

local started = false
local player = Players.LocalPlayer

local function create(className, props)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			object[key] = value
		end
	end
	object.Parent = props and props.Parent or nil
	return object
end

local function round(object, color)
	create("UICorner", { Parent = object, CornerRadius = UDim.new(0, 14) })
	create("UIStroke", { Parent = object, Color = color or Color3.fromRGB(255, 255, 255), Transparency = 0.6 })
end

local function clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function addLayout(parent, horizontal)
	local layout = parent:FindFirstChildOfClass("UIListLayout") or create("UIListLayout", {
		Parent = parent,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
	layout.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	layout.HorizontalAlignment = horizontal and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	return layout
end

local function addPadding(parent)
	local pad = parent:FindFirstChildOfClass("UIPadding") or create("UIPadding", { Parent = parent })
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	return pad
end

local function showError(message)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = create("ScreenGui", {
		Name = "FarmMutationUI_Error",
		Parent = playerGui,
		ResetOnSpawn = false,
		DisplayOrder = 200,
		IgnoreGuiInset = true,
	})
	local frame = create("Frame", {
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(700, 180),
		BackgroundColor3 = Color3.fromRGB(60, 26, 26),
	})
	round(frame, Color3.fromRGB(255, 160, 160))
	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.new(1, -32, 0, 24),
		Font = Enum.Font.GothamBlack,
		Text = "Farm Mutation MMO UI Error",
		TextColor3 = Color3.fromRGB(255, 240, 240),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	create("TextLabel", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 44),
		Size = UDim2.new(1, -32, 1, -56),
		Font = Enum.Font.Code,
		Text = tostring(message),
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(255, 223, 223),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

function ClientApp.Start()
	if started then
		return
	end
	started = true

	local ok, err = xpcall(function()
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		local Constants = require(Shared.Constants)
		local CropDefinitions = require(Shared.CropDefinitions)
		local PetDefinitions = require(Shared.PetDefinitions)
		local Format = require(Shared.Format)
		local Remotes = require(Shared.Remotes)

		local remoteFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
		local actionEvent = remoteFolder:WaitForChild(Remotes.ActionEventName)
		local stateEvent = remoteFolder:WaitForChild(Remotes.StateEventName)
		local requestState = remoteFolder:WaitForChild(Remotes.RequestStateFunctionName)

		local state = {
			Profile = { Coins = 0, Gems = 0, Level = 1, XP = 0, UnlockedSeeds = {}, Seeds = {}, Produce = {}, OwnedMachines = {}, OwnedPets = {}, Runtime = {}, Daily = {} },
			Market = { Crops = {}, Machines = {} },
			Runtime = { PlotId = "?", PowerUsage = 0, PowerCapacity = Constants.FarmBasePower },
			Auctions = {},
			TradePlayers = {},
			Contest = {},
		}

		local currentPanel = nil
		local ui = {}

		local function fire(payload)
			actionEvent:FireServer(payload)
		end

		local function toast(text)
			if not ui.Toast then
				return
			end
			ui.Toast.Text = text
			ui.Toast.Visible = true
		end

		local function seedIds()
			local ids = {}
			for cropId, unlocked in pairs(state.Profile.UnlockedSeeds or {}) do
				if unlocked and CropDefinitions[cropId] then
					table.insert(ids, cropId)
				end
			end
			table.sort(ids, function(a, b)
				return CropDefinitions[a].UnlockLevel < CropDefinitions[b].UnlockLevel
			end)
			return ids
		end

		local function inventoryItems()
			local items = {}
			for key, quantity in pairs(state.Profile.Produce or {}) do
				table.insert(items, { Key = key, Quantity = quantity })
			end
			table.sort(items, function(a, b)
				return a.Quantity > b.Quantity
			end)
			return items
		end

		local function textButton(parent, label, color, callback)
			local button = create("TextButton", {
				Parent = parent,
				Size = UDim2.fromOffset(88, 32),
				BackgroundColor3 = color,
				Text = label,
				TextColor3 = Color3.fromRGB(28, 20, 12),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
			})
			round(button, Color3.fromRGB(255, 255, 255))
			button.MouseButton1Click:Connect(callback)
			return button
		end

		local function makeRow(parent, title, subtitle, color)
			local row = create("Frame", {
				Parent = parent,
				Size = UDim2.new(1, 0, 0, 78),
				BackgroundColor3 = color,
			})
			round(row, Color3.fromRGB(255, 255, 255))
			create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 10),
				Size = UDim2.new(1, -220, 0, 20),
				Font = Enum.Font.GothamBold,
				Text = title,
				TextColor3 = Color3.fromRGB(245, 247, 250),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 30),
				Size = UDim2.new(1, -220, 0, 34),
				Font = Enum.Font.Gotham,
				Text = subtitle,
				TextWrapped = true,
				TextColor3 = Color3.fromRGB(225, 230, 236),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})
			local actions = create("Frame", {
				Parent = row,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(198, 38),
			})
			addLayout(actions, true)
			return row, actions
		end

		local function renderSeeds()
			clear(ui.SeedList)
			addLayout(ui.SeedList, false)
			addPadding(ui.SeedList)
			local selectedSeed = state.Profile.Runtime.SelectedSeed or "Carrot"
			for _, cropId in ipairs(seedIds()) do
				local crop = CropDefinitions[cropId]
				local seedButton = create("TextButton", {
					Parent = ui.SeedList,
					Size = UDim2.new(1, 0, 0, 58),
					BackgroundColor3 = selectedSeed == cropId and crop.Color or Color3.fromRGB(46, 60, 52),
					Text = crop.DisplayName .. "  x" .. tostring(state.Profile.Seeds[cropId] or 0),
					TextColor3 = Color3.fromRGB(245, 248, 245),
					Font = Enum.Font.GothamBold,
					TextSize = 15,
				})
				round(seedButton, Color3.fromRGB(255, 255, 255))
				seedButton.MouseButton1Click:Connect(function()
					fire({ Type = "SelectSeed", SeedId = cropId })
				end)
			end
		end

		local function renderInventory()
			clear(ui.InventoryList)
			addLayout(ui.InventoryList, false)
			addPadding(ui.InventoryList)
			makeRow(ui.InventoryList, "How To Farm", "Choose a seed on the left, equip Hoe, click your plot, water it, then harvest it.", Color3.fromRGB(79, 132, 105))
			for _, item in ipairs(inventoryItems()) do
				local cropId, mutation = Format.SplitProduceKey(item.Key)
				local crop = CropDefinitions[cropId]
				if crop then
					local row, actions = makeRow(ui.InventoryList, (mutation ~= "None" and (mutation .. " ") or "") .. crop.DisplayName, "Owned " .. item.Quantity, Color3.fromRGB(67, 84, 108))
					textButton(actions, "Sell 1", Color3.fromRGB(255, 197, 102), function()
						fire({ Type = "SellProduce", ProduceKey = item.Key, Quantity = 1 })
					end)
					textButton(actions, "Sell All", Color3.fromRGB(255, 164, 84), function()
						fire({ Type = "SellProduce", ProduceKey = item.Key, Quantity = item.Quantity })
					end)
					row.LayoutOrder = 10
				end
			end
		end

		local function renderModal()
			ui.Modal.Visible = currentPanel ~= nil
			if not currentPanel then
				return
			end
			ui.ModalTitle.Text = currentPanel
			clear(ui.ModalContent)
			addLayout(ui.ModalContent, false)
			addPadding(ui.ModalContent)

			if currentPanel == "Market" then
				if state.Market.NextToolTier then
					local row, actions = makeRow(ui.ModalContent, "Upgrade Tools To " .. state.Market.NextToolTier, "Cost " .. Format.Commas(state.Market.NextToolCost or 0) .. " coins", Color3.fromRGB(115, 88, 45))
					textButton(actions, "Upgrade", Color3.fromRGB(255, 210, 118), function()
						fire({ Type = "UpgradeTools" })
					end)
					row.Size = UDim2.new(1, 0, 0, 82)
				end
				local cropIds = {}
				for cropId in pairs(CropDefinitions) do
					table.insert(cropIds, cropId)
				end
				table.sort(cropIds, function(a, b)
					return CropDefinitions[a].UnlockLevel < CropDefinitions[b].UnlockLevel
				end)
				for _, cropId in ipairs(cropIds) do
					local crop = CropDefinitions[cropId]
					local row, actions = makeRow(ui.ModalContent, crop.DisplayName, "Buy seeds or stock up before planting. Unlock Lv." .. tostring(crop.UnlockLevel), Color3.fromRGB(62, 97, 78))
					textButton(actions, "Buy 1", Color3.fromRGB(114, 223, 134), function()
						fire({ Type = "BuySeed", SeedId = cropId, Quantity = 1 })
					end)
					textButton(actions, "Buy 5", Color3.fromRGB(94, 205, 122), function()
						fire({ Type = "BuySeed", SeedId = cropId, Quantity = 5 })
					end)
					row.LayoutOrder = 10
				end
			elseif currentPanel == "Automation" then
				makeRow(ui.ModalContent, string.format("Power %d / %d", state.Runtime.PowerUsage or 0, state.Runtime.PowerCapacity or 0), "Select a machine, then click a gray machine pad on your farm.", Color3.fromRGB(54, 92, 120))
				for machineId, machine in pairs(state.Market.Machines or {}) do
					local row, actions = makeRow(ui.ModalContent, machine.DisplayName, machine.Description, Color3.fromRGB(61, 89, 110))
					textButton(actions, "Buy", Color3.fromRGB(255, 208, 114), function()
						fire({ Type = "BuyMachine", MachineId = machineId })
					end)
					textButton(actions, "Place", Color3.fromRGB(119, 219, 255), function()
						fire({ Type = "SelectMachine", MachineId = machineId })
					end)
					row.LayoutOrder = 10
				end
			elseif currentPanel == "Trade" then
				makeRow(ui.ModalContent, "Trading", "Use Test > Start with 2 players to test trading in Studio.", Color3.fromRGB(98, 74, 62))
			elseif currentPanel == "Auction" then
				makeRow(ui.ModalContent, "Auction Board", "Rare crop listings will appear here as you harvest more items.", Color3.fromRGB(95, 67, 104))
			elseif currentPanel == "Pets" then
				for petId, pet in pairs(PetDefinitions) do
					local row, actions = makeRow(ui.ModalContent, pet.DisplayName, pet.Description, Color3.fromRGB(104, 80, 58))
					if not state.Profile.OwnedPets[petId] then
						textButton(actions, "Buy", Color3.fromRGB(255, 216, 110), function()
							fire({ Type = "BuyPet", PetId = petId })
						end)
					end
					textButton(actions, state.Profile.EquippedPet == petId and "Equipped" or "Equip", Color3.fromRGB(122, 211, 255), function()
						fire({ Type = "EquipPet", PetId = petId })
					end)
					row.LayoutOrder = 10
				end
			elseif currentPanel == "Daily" then
				local row, actions = makeRow(ui.ModalContent, "Daily Reward Shrine", "Claim once per day for coins and gems.", Color3.fromRGB(110, 102, 58))
				textButton(actions, "Claim", Color3.fromRGB(255, 228, 118), function()
					fire({ Type = "ClaimDailyReward" })
				end)
				row.Size = UDim2.new(1, 0, 0, 82)
			end
		end

		local function refresh()
			if not ui.Stats or not ui.SeedList or not ui.InventoryList or not ui.Modal then
				return
			end
			ui.Stats.Text = string.format("%s Coins | %s Gems | Lv.%d | XP %d/%d", Format.Commas(state.Profile.Coins or 0), Format.Commas(state.Profile.Gems or 0), state.Profile.Level or 1, state.Profile.XP or 0, state.Profile.XPNeeded or Constants.GetLevelXP(state.Profile.Level or 1))
			ui.SubStats.Text = string.format("Plot %s | Tool Tier: %s | Seed: %s | Power %d/%d", tostring(state.Runtime.PlotId or "?"), state.Profile.ToolTier or "Starter", state.Profile.Runtime.SelectedSeed or "Carrot", state.Runtime.PowerUsage or 0, state.Runtime.PowerCapacity or Constants.FarmBasePower)
			ui.Contest.Text = state.Contest.Active and ("Mutation Clash live: " .. tostring(state.Contest.SecondsRemaining or 0) .. "s") or ("Next Mutation Clash in " .. tostring(state.Contest.SecondsRemaining or 0) .. "s")
			renderSeeds()
			renderInventory()
			renderModal()
		end

		local function scaleUi()
			if ui.Scale and Workspace.CurrentCamera then
				local viewport = Workspace.CurrentCamera.ViewportSize
				ui.Scale.Scale = math.max(0.68, math.min(1, viewport.X / 1700, viewport.Y / 980))
			end
		end

		local function buildUi()
			local playerGui = player:WaitForChild("PlayerGui")
			local existing = playerGui:FindFirstChild("FarmMutationUI")
			if existing then
				existing:Destroy()
			end

			local gui = create("ScreenGui", {
				Name = "FarmMutationUI",
				Parent = playerGui,
				ResetOnSpawn = false,
				IgnoreGuiInset = true,
				DisplayOrder = 50,
			})
			ui.Scale = create("UIScale", { Parent = gui, Scale = 1 })

			local top = create("Frame", { Parent = gui, Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 92), BackgroundColor3 = Color3.fromRGB(29, 38, 49) })
			round(top, Color3.fromRGB(255, 220, 150))
			ui.Stats = create("TextLabel", { Parent = top, BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 28), Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(247, 245, 239), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
			ui.SubStats = create("TextLabel", { Parent = top, BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 42), Size = UDim2.new(1, -270, 0, 20), Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(215, 227, 238), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
			create("TextLabel", { Parent = top, BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 63), Size = UDim2.new(1, -270, 0, 18), Font = Enum.Font.GothamMedium, Text = "Use the top buttons for systems. Click brown farm tiles with tools. Gray pads are for machines.", TextColor3 = Color3.fromRGB(181, 207, 228), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })

			local nav = create("Frame", { Parent = top, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(630, 40) })
			addLayout(nav, true)
			for _, entry in ipairs({ "Market", "Automation", "Trade", "Auction", "Pets", "Daily" }) do
				textButton(nav, entry, Color3.fromRGB(255, 199, 107), function()
					currentPanel = entry
					renderModal()
				end)
			end

			local contest = create("Frame", { Parent = gui, Position = UDim2.new(0.5, -195, 0, 122), Size = UDim2.fromOffset(390, 70), BackgroundColor3 = Color3.fromRGB(55, 37, 28) })
			round(contest, Color3.fromRGB(255, 214, 150))
			ui.Contest = create("TextLabel", { Parent = contest, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 1, -20), Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(253, 245, 216), TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })

			local seeds = create("Frame", { Parent = gui, Position = UDim2.fromOffset(20, 210), Size = UDim2.fromOffset(260, 500), BackgroundColor3 = Color3.fromRGB(31, 44, 39) })
			round(seeds, Color3.fromRGB(206, 240, 214))
			create("TextLabel", { Parent = seeds, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 24), Font = Enum.Font.GothamBlack, Text = "Seed Loadout", TextColor3 = Color3.fromRGB(244, 248, 241), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
			ui.SeedList = create("ScrollingFrame", { Parent = seeds, Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5 })

			local inventory = create("Frame", { Parent = gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 210), Size = UDim2.fromOffset(350, 500), BackgroundColor3 = Color3.fromRGB(33, 42, 58) })
			round(inventory, Color3.fromRGB(214, 227, 244))
			create("TextLabel", { Parent = inventory, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 24), Font = Enum.Font.GothamBlack, Text = "Barn Inventory", TextColor3 = Color3.fromRGB(244, 247, 252), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
			ui.InventoryList = create("ScrollingFrame", { Parent = inventory, Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5 })

			ui.Modal = create("Frame", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.58, 0), Size = UDim2.fromOffset(560, 520), BackgroundColor3 = Color3.fromRGB(25, 34, 47), Visible = false })
			round(ui.Modal, Color3.fromRGB(255, 220, 160))
			ui.ModalTitle = create("TextLabel", { Parent = ui.Modal, BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -88, 0, 28), Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(246, 243, 235), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
			local closeButton = textButton(ui.Modal, "X", Color3.fromRGB(255, 145, 120), function()
				currentPanel = nil
				renderModal()
			end)
			closeButton.Position = UDim2.new(1, -50, 0, 10)
			ui.ModalContent = create("ScrollingFrame", { Parent = ui.Modal, Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 1, -64), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6 })

			ui.Toast = create("TextLabel", { Parent = gui, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.fromOffset(560, 44), BackgroundColor3 = Color3.fromRGB(24, 31, 42), TextColor3 = Color3.fromRGB(255, 247, 233), Font = Enum.Font.GothamBold, TextSize = 15, Visible = false })
			round(ui.Toast, Color3.fromRGB(255, 220, 170))

			scaleUi()
			if Workspace.CurrentCamera then
				Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(scaleUi)
			end
		end

		local function normalizeState()
			state.Profile = state.Profile or {}
			state.Profile.UnlockedSeeds = state.Profile.UnlockedSeeds or {}
			state.Profile.Seeds = state.Profile.Seeds or {}
			state.Profile.Produce = state.Profile.Produce or {}
			state.Profile.OwnedMachines = state.Profile.OwnedMachines or {}
			state.Profile.OwnedPets = state.Profile.OwnedPets or {}
			state.Profile.Runtime = state.Profile.Runtime or {}
			state.Profile.Daily = state.Profile.Daily or {}
			state.Market = state.Market or { Crops = {}, Machines = {} }
			state.Market.Crops = state.Market.Crops or {}
			state.Market.Machines = state.Market.Machines or {}
			state.Runtime = state.Runtime or {}
			state.Contest = state.Contest or {}
			state.Auctions = state.Auctions or {}
			state.TradePlayers = state.TradePlayers or {}
		end

		local function applyState(newState)
			if typeof(newState) == "table" then
				state = newState
				normalizeState()
				refresh()
			end
		end

		stateEvent.OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "table" then
				return
			end
			if payload.Type == "FullState" then
				applyState(payload.State)
			elseif payload.Type == "ProfileUpdate" then
				state.Profile = payload.Profile or state.Profile
				state.Runtime = payload.Runtime or state.Runtime
				normalizeState()
				refresh()
			elseif payload.Type == "MarketUpdate" then
				state.Market = payload.Market or state.Market
				normalizeState()
				refresh()
			elseif payload.Type == "AuctionUpdate" then
				state.Auctions = payload.Auctions or state.Auctions
				normalizeState()
				refresh()
			elseif payload.Type == "ContestUpdate" then
				state.Contest = payload.Contest or state.Contest
				normalizeState()
				refresh()
			elseif payload.Type == "TradeRoster" then
				state.TradePlayers = payload.Players or state.TradePlayers
				normalizeState()
				refresh()
			elseif payload.Type == "OpenPanel" then
				if payload.Panel == "SeedMarket" or payload.Panel == "ToolShop" then
					currentPanel = "Market"
				elseif payload.Panel == "AutomationShop" then
					currentPanel = "Automation"
				elseif payload.Panel == "Trading" then
					currentPanel = "Trade"
				else
					currentPanel = payload.Panel
				end
				refresh()
			elseif payload.Type == "Notification" then
				toast(payload.Message)
			end
		end)

		local mouse = player:GetMouse()
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local target = mouse.Target
			if not target then
				return
			end
			local plotId = target:GetAttribute("PlotId")
			if not plotId then
				return
			end
			if target:GetAttribute("CellId") then
				fire({ Type = "InteractCell", PlotId = plotId, CellId = target:GetAttribute("CellId") })
			elseif target:GetAttribute("PadId") then
				fire({ Type = "InteractMachinePad", PlotId = plotId, PadId = target:GetAttribute("PadId") })
			end
		end)

		buildUi()
		local success, fullState = pcall(function()
			return requestState:InvokeServer()
		end)
		if success then
			applyState(fullState)
		else
			refresh()
			toast("State sync failed. Try respawning once.")
		end
	end, debug.traceback)

	if not ok then
		started = false
		warn("FarmMutationMMO client bootstrap failed:\n" .. tostring(err))
		showError(err)
	end
end

return ClientApp
