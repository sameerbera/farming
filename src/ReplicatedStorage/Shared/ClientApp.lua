local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ClientApp = {}

local started = false
local player = Players.LocalPlayer

local THEME = {
	BackgroundTop = Color3.fromRGB(8, 12, 24),
	BackgroundBottom = Color3.fromRGB(15, 22, 37),
	Glass = Color3.fromRGB(20, 28, 44),
	Panel = Color3.fromRGB(30, 39, 58),
	Text = Color3.fromRGB(246, 248, 255),
	Muted = Color3.fromRGB(176, 190, 214),
	Faint = Color3.fromRGB(125, 142, 172),
	Orange = Color3.fromRGB(255, 170, 58),
	Gold = Color3.fromRGB(255, 212, 92),
	Green = Color3.fromRGB(76, 223, 132),
	Cyan = Color3.fromRGB(88, 233, 255),
	Blue = Color3.fromRGB(97, 158, 255),
	Purple = Color3.fromRGB(171, 110, 255),
	Red = Color3.fromRGB(255, 101, 101),
}

local RARITY_COLORS = {
	Common = Color3.fromRGB(145, 151, 163),
	Uncommon = Color3.fromRGB(86, 204, 130),
	Rare = Color3.fromRGB(87, 153, 255),
	Epic = Color3.fromRGB(173, 109, 255),
	Legendary = Color3.fromRGB(255, 209, 77),
	Mythic = Color3.fromRGB(255, 86, 86),
	Cosmic = Color3.fromRGB(52, 255, 241),
}

local PET_RARITIES = {
	Chick = "Common",
	Bee = "Rare",
	Fox = "Epic",
	Golem = "Legendary",
	Phoenix = "Mythic",
}

local MENU_ENTRIES = {
	{ Id = "Market", Icon = "M", Accent = Color3.fromRGB(255, 178, 76), Tooltip = "Buy seeds and upgrades." },
	{ Id = "Pets", Icon = "P", Accent = Color3.fromRGB(108, 221, 139), Tooltip = "Manage buffs and pet companions." },
	{ Id = "Automation", Icon = "A", Accent = Color3.fromRGB(97, 214, 255), Tooltip = "Machines, power, and placement mode." },
	{ Id = "Trade", Icon = "T", Accent = Color3.fromRGB(255, 158, 112), Tooltip = "Safe player-to-player trading." },
	{ Id = "Auction", Icon = "Au", Accent = Color3.fromRGB(203, 132, 255), Tooltip = "List or buy rare produce." },
	{ Id = "Season", Icon = "S", Accent = Color3.fromRGB(255, 214, 93), Tooltip = "Live event progress and rewards." },
	{ Id = "Daily", Icon = "D", Accent = Color3.fromRGB(110, 245, 181), Tooltip = "Claim your daily reward." },
	{ Id = "Rebirth", Icon = "R", Accent = Color3.fromRGB(79, 255, 233), Tooltip = "Meta progression and resets." },
}

local SHOP_PRODUCTS = {
	{
		Title = "Gem Crate",
		Subtitle = "Premium currency boost for pets and future offers.",
		PriceLabel = "120 Gems",
		Type = "DevProduct",
		ProductId = nil,
		Accent = THEME.Orange,
		Badge = "Popular",
	},
	{
		Title = "Mutation Surge",
		Subtitle = "Premium boost card for rare mutation sessions.",
		PriceLabel = "x3 Luck",
		Type = "DevProduct",
		ProductId = nil,
		Accent = THEME.Green,
		Badge = "Limited",
	},
	{
		Title = "VIP Fields",
		Subtitle = "Premium pass concept for simulator-style retention boosts.",
		PriceLabel = "Gamepass",
		Type = "GamePass",
		ProductId = nil,
		Accent = THEME.Purple,
		Badge = "VIP",
	},
}

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

local function applyCorner(object, radius)
	create("UICorner", {
		Parent = object,
		CornerRadius = UDim.new(0, radius or 16),
	})
end

local function round(object, color)
	applyCorner(object, 16)
	create("UIStroke", {
		Parent = object,
		Color = color or Color3.fromRGB(255, 255, 255),
		Transparency = 0.58,
		Thickness = 1.2,
	})
end

local function addShadow(object)
	create("ImageLabel", {
		Name = "Shadow",
		Parent = object,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 10),
		Size = UDim2.new(1, 28, 1, 28),
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.78,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = math.max(0, object.ZIndex - 1),
	})
end

local function applyGradient(object, startColor, endColor, rotation)
	create("UIGradient", {
		Parent = object,
		Rotation = rotation or 90,
		Color = ColorSequence.new(startColor, endColor),
	})
end

local function glassPanel(parent, props, accent)
	local panel = create("Frame", props)
	panel.BackgroundColor3 = panel.BackgroundColor3 or THEME.Glass
	panel.BackgroundTransparency = panel.BackgroundTransparency == nil and 0.1 or panel.BackgroundTransparency
	round(panel, accent or Color3.fromRGB(255, 255, 255))
	addShadow(panel)
	return panel
end

local function rarityColor(rarity)
	return RARITY_COLORS[rarity] or RARITY_COLORS.Common
end

local function iconTextFromName(name)
	local trimmed = name:gsub("[^%a]", "")
	if #trimmed >= 2 then
		return string.upper(trimmed:sub(1, 2))
	end
	return string.upper(trimmed:sub(1, 1))
end

local function pointInside(guiObject, point)
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
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

local function safeThumbnail()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end)
	return ok and image or ""
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
		local BiomeDefinitions = require(Shared.BiomeDefinitions)
		local Constants = require(Shared.Constants)
		local CropDefinitions = require(Shared.CropDefinitions)
		local MachineDefinitions = require(Shared.MachineDefinitions)
		local PetDefinitions = require(Shared.PetDefinitions)
		local Format = require(Shared.Format)
		local Remotes = require(Shared.Remotes)

		local remoteFolder = ReplicatedStorage:WaitForChild(Remotes.FolderName)
		local actionEvent = remoteFolder:WaitForChild(Remotes.ActionEventName)
		local stateEvent = remoteFolder:WaitForChild(Remotes.StateEventName)
		local requestState = remoteFolder:WaitForChild(Remotes.RequestStateFunctionName)

		local state = {
			Profile = {
				Coins = 0,
				Gems = 0,
				Level = 1,
				Rebirths = 0,
				XP = 0,
				XPNeeded = 100,
				UnlockedSeeds = {},
				UnlockedBiomes = {},
				Seeds = {},
				Produce = {},
				OwnedMachines = {},
				OwnedPets = {},
				Runtime = {},
				Daily = {},
				Stats = {},
			},
			Market = { Crops = {}, Machines = {}, Pets = {}, DailyRewards = {} },
			Runtime = { PlotId = "?", PowerUsage = 0, PowerCapacity = Constants.FarmBasePower },
			Auctions = {},
			TradePlayers = {},
			Trade = nil,
			TradeRequest = nil,
			Contest = {},
		}

		local currentPanel = nil
		local ui = {}
		local localSettings = {
			Tooltips = true,
			ScreenFx = true,
			FloatText = true,
			ClickSounds = true,
		}
		local resourceState = {}
		local goalState = {}
		local offerDraft = { Items = {}, Coins = 0 }
		local closingModal = false
		local toastToken = 0
		local dragState = nil
		local shakeRunning = false

		local function fire(payload)
			actionEvent:FireServer(payload)
		end

		local function tween(instance, info, props)
			local animation = TweenService:Create(instance, info, props)
			animation:Play()
			return animation
		end

		local function playClick()
			if not localSettings.ClickSounds or not ui.ClickSound then
				return
			end
			ui.ClickSound.TimePosition = 0
			ui.ClickSound:Play()
		end

		local function bindTooltip(target, text)
			target.MouseEnter:Connect(function()
				if not localSettings.Tooltips or not ui.TooltipFrame then
					return
				end
				ui.Tooltip.Text = text
				ui.TooltipFrame.Visible = true
			end)
			target.MouseMoved:Connect(function(x, y)
				if ui.TooltipFrame and ui.TooltipFrame.Visible then
					ui.TooltipFrame.Position = UDim2.fromOffset(x + 18, y + 14)
				end
			end)
			target.MouseLeave:Connect(function()
				if ui.TooltipFrame then
					ui.TooltipFrame.Visible = false
				end
			end)
		end

		local function bounce(scaleObject, peak)
			if not scaleObject then
				return
			end
			scaleObject.Scale = 0.96
			tween(scaleObject, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = peak or 1.06 })
			task.delay(0.09, function()
				if scaleObject.Parent then
					tween(scaleObject, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
				end
			end)
		end

		local function sweepShine(frame)
			if not frame then
				return
			end
			local shine = frame:FindFirstChild("Shine")
			if not shine then
				shine = create("Frame", {
					Name = "Shine",
					Parent = frame,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.82,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(-0.35, 0),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = frame.ZIndex + 2,
				})
				applyCorner(shine, 16)
				applyGradient(shine, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), 20)
			end
			shine.Visible = true
			shine.Position = UDim2.fromScale(-0.35, 0)
			tween(shine, TweenInfo.new(0.44, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(1.15, 0),
				BackgroundTransparency = 1,
			})
		end

		local function toast(text)
			if not ui.ToastFrame then
				return
			end
			toastToken += 1
			local token = toastToken
			ui.ToastLabel.Text = text
			ui.ToastFrame.Visible = true
			ui.ToastFrame.Position = UDim2.new(0.5, 0, 1, 34)
			tween(ui.ToastFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 1, -22),
			})
			task.delay(2.9, function()
				if token ~= toastToken or not ui.ToastFrame then
					return
				end
				local closeTween = tween(ui.ToastFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(0.5, 0, 1, 38),
				})
				closeTween.Completed:Connect(function()
					if token == toastToken and ui.ToastFrame then
						ui.ToastFrame.Visible = false
					end
				end)
			end)
		end

		local function spawnFloatText(text, color)
			if not localSettings.FloatText or not ui.FloatLayer then
				return
			end
			local label = create("TextLabel", {
				Parent = ui.FloatLayer,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, math.random(-80, 80), 0.7, 0),
				Size = UDim2.fromOffset(250, 48),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				Text = text,
				TextColor3 = color,
				TextSize = 24,
				ZIndex = 90,
			})
			create("UIStroke", {
				Parent = label,
				Color = THEME.Panel,
				Thickness = 2,
				Transparency = 0.35,
			})
			local scale = create("UIScale", { Parent = label, Scale = 0.82 })
			tween(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.06 })
			tween(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = label.Position - UDim2.fromOffset(0, 82),
				TextTransparency = 1,
			})
			task.delay(0.86, function()
				label:Destroy()
			end)
		end

		local function flashMutation(color)
			if not localSettings.ScreenFx or not ui.MutationFlash then
				return
			end
			ui.MutationFlash.BackgroundColor3 = color
			ui.MutationFlash.Visible = true
			ui.MutationFlash.BackgroundTransparency = 0.84
			local animation = tween(ui.MutationFlash, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			})
			animation.Completed:Connect(function()
				if ui.MutationFlash then
					ui.MutationFlash.Visible = false
				end
			end)
		end

		local function shakeCamera(intensity, duration)
			if not localSettings.ScreenFx or shakeRunning then
				return
			end
			shakeRunning = true
			task.spawn(function()
				local camera = Workspace.CurrentCamera
				if not camera then
					shakeRunning = false
					return
				end
				local lastOffset = CFrame.new()
				local start = tick()
				while tick() - start < duration do
					local alpha = 1 - ((tick() - start) / duration)
					local offset = CFrame.new(
						(math.random() - 0.5) * 0.18 * intensity * alpha,
						(math.random() - 0.5) * 0.12 * intensity * alpha,
						0
					)
					camera.CFrame = camera.CFrame * lastOffset:Inverse() * offset
					lastOffset = offset
					RunService.RenderStepped:Wait()
				end
				camera.CFrame = camera.CFrame * lastOffset:Inverse()
				shakeRunning = false
			end)
		end

		local function createMetricChip(parent, text, accent)
			local chip = glassPanel(parent, {
				Size = UDim2.fromOffset(124, 32),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.05,
			}, accent)
			create("TextLabel", {
				Parent = chip,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = Enum.Font.GothamBold,
				Text = text,
				TextColor3 = THEME.Text,
				TextSize = 12,
			})
			return chip
		end

		local function createSectionTitle(parent, title, subtitle)
			local holder = create("Frame", {
				Parent = parent,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, subtitle and 46 or 28),
			})
			create("TextLabel", {
				Parent = holder,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				Font = Enum.Font.GothamBlack,
				Text = title,
				TextColor3 = THEME.Text,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			if subtitle then
				create("TextLabel", {
					Parent = holder,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, 24),
					Size = UDim2.new(1, 0, 0, 18),
					Font = Enum.Font.Gotham,
					Text = subtitle,
					TextColor3 = THEME.Muted,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
			end
			return holder
		end

		local function animateResource(key, target)
			local resource = resourceState[key]
			if not resource or resource.Value.Value == target then
				return
			end
			if target > resource.Value.Value then
				sweepShine(resource.Frame)
				bounce(resource.Scale, 1.08)
			end
			tween(resource.Value, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = target,
			})
		end

		local function parseNotification(message)
			if message:find("^Sold for") then
				local amount = message:match("Sold for ([%d,]+)")
				spawnFloatText("+" .. (amount or "?") .. " Coins", THEME.Orange)
			elseif message:find("^Harvested") then
				local quantity = tonumber(message:match("Harvested (%d+)x")) or 1
				spawnFloatText("+" .. quantity .. " Harvest", THEME.Green)
				local mutation = message:match("Harvested %d+x ([A-Za-z]+) ")
				if mutation == "Golden" then
					flashMutation(THEME.Gold)
				elseif mutation == "Giant" then
					flashMutation(THEME.Orange)
				elseif mutation == "Rainbow" then
					flashMutation(rarityColor("Cosmic"))
					shakeCamera(1.1, 0.16)
				elseif mutation == "Explosive" then
					flashMutation(THEME.Red)
					shakeCamera(1.35, 0.18)
				end
			elseif message:find("seeds unlocked") or message:find(" unlocked!") then
				spawnFloatText("Unlocked", THEME.Cyan)
			end
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

		local function textButton(parent, label, color, callback, width, height, tooltip)
			local brightness = (color.R + color.G + color.B) / 3
			local button = create("TextButton", {
				Parent = parent,
				Size = UDim2.fromOffset(width or 96, height or 36),
				BackgroundColor3 = color,
				BackgroundTransparency = 0,
				Text = label,
				TextColor3 = brightness < 0.45 and THEME.Text or Color3.fromRGB(18, 18, 24),
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				AutoButtonColor = false,
			})
			round(button, color:Lerp(Color3.new(1, 1, 1), 0.25))
			addShadow(button)
			applyGradient(button, color:Lerp(Color3.new(1, 1, 1), 0.16), color, 90)
			local scale = create("UIScale", { Parent = button, Scale = 1 })
			button.MouseEnter:Connect(function()
				tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.04 })
			end)
			button.MouseLeave:Connect(function()
				tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
			end)
			button.MouseButton1Down:Connect(function()
				tween(scale, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 })
			end)
			button.MouseButton1Up:Connect(function()
				tween(scale, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.04 })
			end)
			button.MouseButton1Click:Connect(function()
				playClick()
				bounce(scale, 1.08)
				if callback then
					callback()
				end
			end)
			if tooltip then
				bindTooltip(button, tooltip)
			end
			return button
		end

		local function makeRow(parent, title, subtitle, color, height)
			local row = glassPanel(parent, {
				Parent = parent,
				Size = UDim2.new(1, 0, 0, height or 82),
				BackgroundColor3 = color or THEME.Panel,
				BackgroundTransparency = 0.06,
			}, color)
			create("TextLabel", {
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 10),
				Size = UDim2.new(1, -220, 0, 20),
				Font = Enum.Font.GothamBlack,
				Text = title,
				TextColor3 = THEME.Text,
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
				TextColor3 = THEME.Muted,
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
			local seedLayout = addLayout(ui.SeedList, true)
			seedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			addPadding(ui.SeedList)
			local selectedSeed = state.Profile.Runtime.SelectedSeed or "Carrot"
			local totalSeeds = 0
			for _, quantity in pairs(state.Profile.Seeds or {}) do
				totalSeeds += quantity
			end
			if ui.SeedMeta then
				ui.SeedMeta.Text = string.format("Selected: %s   |   Stored Seeds: %s   |   Tap a seed card to arm planting.", selectedSeed, Format.Commas(totalSeeds))
			end
			for _, cropId in ipairs(seedIds()) do
				local crop = CropDefinitions[cropId]
				local accent = rarityColor(crop.Rarity)
				local selected = selectedSeed == cropId
				local card = glassPanel(ui.SeedList, {
					Size = UDim2.fromOffset(176, 132),
					BackgroundColor3 = THEME.Panel,
					BackgroundTransparency = selected and 0.02 or 0.08,
				}, accent)
				local scale = create("UIScale", { Parent = card, Scale = selected and 1.02 or 1 })
				local hit = create("TextButton", {
					Parent = card,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 5,
				})

				local pill = create("TextLabel", {
					Parent = card,
					Position = UDim2.fromOffset(12, 12),
					Size = UDim2.fromOffset(78, 20),
					BackgroundColor3 = accent,
					BackgroundTransparency = 0.08,
					Font = Enum.Font.GothamBlack,
					Text = string.upper(crop.Rarity),
					TextColor3 = Color3.fromRGB(18, 18, 24),
					TextSize = 10,
				})
				applyCorner(pill, 10)

				local iconShell = create("Frame", {
					Parent = card,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -12, 0, 12),
					Size = UDim2.fromOffset(34, 34),
					BackgroundColor3 = crop.Color,
				})
				applyCorner(iconShell, 12)
				create("TextLabel", {
					Parent = iconShell,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBlack,
					Text = iconTextFromName(crop.DisplayName),
					TextColor3 = Color3.fromRGB(18, 18, 24),
					TextSize = 12,
				})

				create("TextLabel", {
					Parent = card,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 40),
					Size = UDim2.new(1, -24, 0, 24),
					Font = Enum.Font.GothamBlack,
					Text = crop.DisplayName,
					TextColor3 = THEME.Text,
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = card,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 64),
					Size = UDim2.new(1, -24, 0, 16),
					Font = Enum.Font.Gotham,
					Text = string.format("Luck %d%%   |   Grow %ss", 10 + (crop.UnlockLevel * 3), crop.GrowthTime),
					TextColor3 = THEME.Muted,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = card,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 86),
					Size = UDim2.new(1, -24, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = "Owned Seeds  " .. tostring(state.Profile.Seeds[cropId] or 0),
					TextColor3 = THEME.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = card,
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new(0, 12, 1, -10),
					Size = UDim2.new(1, -24, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamMedium,
					Text = selected and "Selected seed" or "Tap to select",
					TextColor3 = selected and accent or THEME.Faint,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				if selected then
					sweepShine(card)
					tween(scale, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
						Scale = 1.045,
					})
				else
					hit.MouseEnter:Connect(function()
						tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.03 })
					end)
					hit.MouseLeave:Connect(function()
						tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
					end)
				end

				hit.MouseButton1Click:Connect(function()
					playClick()
					fire({ Type = "SelectSeed", SeedId = cropId })
				end)
				bindTooltip(hit, crop.DisplayName .. "\nRarity: " .. crop.Rarity .. "\nGrowth: " .. crop.GrowthTime .. "s")
			end
		end

		local function renderInventory()
			clear(ui.InventoryList)
			addLayout(ui.InventoryList, false)
			addPadding(ui.InventoryList)
			if ui.InventoryMeta then
				ui.InventoryMeta.Text = string.format("Stacks: %d   |   Mutations Harvested: %s", #inventoryItems(), Format.Commas(state.Profile.Stats and state.Profile.Stats.MutationsHarvested or 0))
			end
			makeRow(ui.InventoryList, "How To Farm", "Choose a seed, equip Hoe, plant on your farm, water, then harvest and sell for dopamine.", THEME.Green, 82)
			for _, item in ipairs(inventoryItems()) do
				local cropId, mutation = Format.SplitProduceKey(item.Key)
				local crop = CropDefinitions[cropId]
				if crop then
					local accent = mutation ~= "None" and rarityColor(mutation == "Rainbow" and "Cosmic" or (mutation == "Explosive" and "Mythic" or crop.Rarity)) or rarityColor(crop.Rarity)
					local subtitle = string.format("Owned %d   |   %s rarity   |   %s", item.Quantity, crop.Rarity, mutation ~= "None" and ("Mutation " .. mutation) or "Standard stack")
					local row, actions = makeRow(ui.InventoryList, (mutation ~= "None" and (mutation .. " ") or "") .. crop.DisplayName, subtitle, accent, 88)
					textButton(actions, "Sell 1", THEME.Gold, function()
						fire({ Type = "SellProduce", ProduceKey = item.Key, Quantity = 1 })
					end, 88, 38, "Sell one item from this stack.")
					textButton(actions, "Sell All", THEME.Orange, function()
						fire({ Type = "SellProduce", ProduceKey = item.Key, Quantity = item.Quantity })
					end, 96, 38, "Sell the full produce stack instantly.")
					row.LayoutOrder = 10
				end
			end
		end

		local function renderModal()
			if not ui.Modal or not ui.ModalBackdrop then
				return
			end

			if not currentPanel then
				if closingModal then
					return
				end
				closingModal = true
				local fade = tween(ui.Modal, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 0.24,
					Position = UDim2.new(0.5, 0, 0.53, 0),
				})
				tween(ui.ModalScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 })
				tween(ui.ModalBackdrop, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
				fade.Completed:Connect(function()
					if ui.Modal then
						ui.Modal.Visible = false
					end
					if ui.ModalBackdrop then
						ui.ModalBackdrop.Visible = false
					end
					closingModal = false
				end)
				return
			end

			local opening = not ui.Modal.Visible
			ui.Modal.Visible = true
			ui.ModalBackdrop.Visible = true
			if opening then
				ui.ModalBackdrop.BackgroundTransparency = 1
				ui.Modal.BackgroundTransparency = 0.04
				ui.Modal.Position = UDim2.new(0.5, 0, 0.53, 0)
				ui.ModalScale.Scale = 0.94
				tween(ui.ModalBackdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.28 })
				tween(ui.Modal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) })
				tween(ui.ModalScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			else
				ui.ModalBackdrop.BackgroundTransparency = 0.28
				ui.Modal.Position = UDim2.new(0.5, 0, 0.5, 0)
				ui.ModalScale.Scale = 1
			end
			ui.ModalTitle.Text = currentPanel
			ui.ModalSubtitle.Text = "Premium management panel"
			if currentPanel ~= "Pets" and ui.PetPreviewSpin then
				ui.PetPreviewSpin:Disconnect()
				ui.PetPreviewSpin = nil
				ui.PetPreviewModel = nil
			end
			clear(ui.ModalContent)
			addLayout(ui.ModalContent, false)
			addPadding(ui.ModalContent)

			if currentPanel == "Market" then
				ui.ModalSubtitle.Text = "Buy seeds, restock inventory, and upgrade your tool tier."
				local banner = glassPanel(ui.ModalContent, {
					Size = UDim2.new(1, 0, 0, 104),
					BackgroundColor3 = THEME.Orange,
					BackgroundTransparency = 0.02,
				}, THEME.Orange)
				applyGradient(banner, Color3.fromRGB(255, 180, 72), Color3.fromRGB(255, 122, 72), 14)
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 14),
					Size = UDim2.new(1, -36, 0, 26),
					Font = Enum.Font.GothamBlack,
					Text = "Field Rush Market",
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 28,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 46),
					Size = UDim2.new(1, -36, 0, 34),
					Font = Enum.Font.GothamBold,
					Text = "Stock up on seeds, ride crop multipliers, and push toward your next machine unlock.",
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				if state.Market.NextToolTier then
					local row, actions = makeRow(ui.ModalContent, "Upgrade Tools To " .. state.Market.NextToolTier, "Cost " .. Format.Commas(state.Market.NextToolCost or 0) .. " coins", THEME.Gold, 86)
					textButton(actions, "Upgrade", THEME.Gold, function()
						fire({ Type = "UpgradeTools" })
					end, 116, 38, "Unlock the next tool tier.")
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
					local market = state.Market.Crops[cropId] or {}
					local subtitle = string.format("Unlock Lv.%d   |   Seed %s   |   Sell %s   |   Market x%.2f", crop.UnlockLevel, Format.Commas(crop.SeedPrice), Format.Commas(crop.BaseSell), market.Multiplier or 1)
					local row, actions = makeRow(ui.ModalContent, crop.DisplayName, subtitle, rarityColor(crop.Rarity), 92)
					textButton(actions, "Buy 1", THEME.Green, function()
						fire({ Type = "BuySeed", SeedId = cropId, Quantity = 1 })
					end, 86, 38, "Buy one seed.")
					textButton(actions, "Buy 5", THEME.Orange, function()
						fire({ Type = "BuySeed", SeedId = cropId, Quantity = 5 })
					end, 92, 38, "Buy five seeds.")
					row.LayoutOrder = 10
				end
			elseif currentPanel == "Automation" then
				ui.ModalSubtitle.Text = "Machine tree, power routing, and placement mode."
				local header, actions = makeRow(ui.ModalContent, string.format("Power %d / %d", state.Runtime.PowerUsage or 0, state.Runtime.PowerCapacity or 0), "Select a machine, then click one of the gray pads on your farm plot.", THEME.Cyan, 82)
				textButton(actions, "Remove", THEME.Red, function()
					fire({ Type = "SelectMachine", MachineId = "REMOVE" })
				end, 94, 38, "Store a machine back in inventory.")

				for _, machineId in ipairs({ "Sprinkler", "HarvesterDrone", "GrowthAccelerator", "SeedDuplicator" }) do
					local machine = (state.Market.Machines and state.Market.Machines[machineId]) or MachineDefinitions[machineId]
					if machine then
						local owned = state.Profile.OwnedMachines[machineId] or 0
						local subtitle = string.format("Cost %s   |   Power %d   |   Owned %d", Format.Commas(machine.Cost), machine.PowerCost, owned)
						local row, actions = makeRow(ui.ModalContent, machine.DisplayName, subtitle .. "   |   " .. machine.Description, machine.Color or THEME.Cyan, 94)
						textButton(actions, "Buy", THEME.Gold, function()
							fire({ Type = "BuyMachine", MachineId = machineId })
						end, 72, 38, "Buy this machine.")
						textButton(actions, "Place", machine.Color or THEME.Cyan, function()
							fire({ Type = "SelectMachine", MachineId = machineId })
						end, 82, 38, "Select this machine for placement.")
						row.LayoutOrder = 10
					end
				end
			elseif currentPanel == "Trade" then
				ui.ModalSubtitle.Text = "Safe player-to-player trading with requests and confirmations."
				if state.TradeRequest then
					local row, actions = makeRow(ui.ModalContent, state.TradeRequest.FromName .. " wants to trade", "Accept to open a secure trade room, or decline and keep farming.", THEME.Orange, 92)
					textButton(actions, "Accept", THEME.Green, function()
						fire({ Type = "RespondTrade", RequesterUserId = state.TradeRequest.FromUserId, Accepted = true })
					end, 92, 38)
					textButton(actions, "Decline", THEME.Red, function()
						fire({ Type = "RespondTrade", RequesterUserId = state.TradeRequest.FromUserId, Accepted = false })
					end, 92, 38)
				elseif state.Trade then
					local mySide = state.Trade.Left.UserId == player.UserId and state.Trade.Left or state.Trade.Right
					local otherSide = state.Trade.Left.UserId == player.UserId and state.Trade.Right or state.Trade.Left
					makeRow(ui.ModalContent, "Your Offer", string.format("%s coins   |   %s   |   %s", Format.Commas(mySide.Coins or 0), mySide.Locked and "Locked" or "Editing", mySide.Confirmed and "Confirmed" or "Pending"), THEME.Green, 78)
					makeRow(ui.ModalContent, "Partner Offer", string.format("%s coins   |   %s   |   %s", Format.Commas(otherSide.Coins or 0), otherSide.Locked and "Locked" or "Editing", otherSide.Confirmed and "Confirmed" or "Pending"), THEME.Cyan, 78)
					local draftRow, draftActions = makeRow(ui.ModalContent, "Offer Builder", "Use the buttons below to send, lock, and confirm your trade. Detailed drag-drop can be layered in next.", THEME.Purple, 92)
					textButton(draftActions, "Send", THEME.Green, function()
						fire({ Type = "SetTradeOffer", Items = offerDraft.Items, Coins = offerDraft.Coins })
					end, 78, 38)
					textButton(draftActions, mySide.Locked and "Unlock" or "Lock", THEME.Gold, function()
						fire({ Type = "SetTradeLocked", Locked = not mySide.Locked })
					end, 82, 38)
					textButton(draftActions, "Confirm", THEME.Cyan, function()
						fire({ Type = "ConfirmTrade" })
					end, 92, 38)
					for _, item in ipairs(inventoryItems()) do
						local cropId, mutation = Format.SplitProduceKey(item.Key)
						local crop = CropDefinitions[cropId]
						if crop then
							local quantity = offerDraft.Items[item.Key] or 0
							local row, actions = makeRow(ui.ModalContent, (mutation ~= "None" and mutation .. " " or "") .. crop.DisplayName, string.format("Owned %d   |   Offering %d   |   Tap All to stage the full stack.", item.Quantity, quantity), rarityColor(crop.Rarity), 82)
							textButton(actions, "-1", THEME.Red, function()
								offerDraft.Items[item.Key] = math.max(0, quantity - 1)
								if offerDraft.Items[item.Key] == 0 then
									offerDraft.Items[item.Key] = nil
								end
								refresh()
							end, 52, 34)
							textButton(actions, "+1", THEME.Gold, function()
								if quantity < item.Quantity then
									offerDraft.Items[item.Key] = quantity + 1
								end
								refresh()
							end, 52, 34)
							textButton(actions, "All", THEME.Orange, function()
								offerDraft.Items[item.Key] = item.Quantity
								refresh()
							end, 56, 34)
						end
					end
				else
					makeRow(ui.ModalContent, "Trading", "Use Test > Start with 2 players to test trading in Studio. Send requests from the roster below.", THEME.Orange, 82)
					for _, candidate in ipairs(state.TradePlayers or {}) do
						local row, actions = makeRow(ui.ModalContent, candidate.Name, "Safe trade request. Both players must lock and confirm.", THEME.Cyan, 76)
						textButton(actions, "Request", THEME.Orange, function()
							fire({ Type = "RequestTrade", TargetUserId = candidate.UserId })
						end, 94, 38)
					end
				end
			elseif currentPanel == "Auction" then
				ui.ModalSubtitle.Text = "List your rare harvests and buy prized server drops."
				makeRow(ui.ModalContent, "Create Listing", "List one harvested crop stack at a boosted price from the rows below.", THEME.Purple, 78)
				for _, item in ipairs(inventoryItems()) do
					local cropId, mutation = Format.SplitProduceKey(item.Key)
					local crop = CropDefinitions[cropId]
					if crop then
						local price = math.max(10, math.floor(crop.BaseSell * ((mutation ~= "None") and 3.4 or 2.2)))
						local row, actions = makeRow(ui.ModalContent, (mutation ~= "None" and mutation .. " " or "") .. crop.DisplayName, string.format("Owned %d   |   Suggested Price %s", item.Quantity, Format.Commas(price)), rarityColor(crop.Rarity), 78)
						textButton(actions, "List 1", THEME.Purple, function()
							fire({ Type = "CreateAuction", ProduceKey = item.Key, Quantity = 1, Price = price })
						end, 86, 38)
					end
				end
				makeRow(ui.ModalContent, "Live Listings", "The latest server-side listings appear below.", THEME.Purple, 78)
				for _, listing in ipairs(state.Auctions or {}) do
					local cropId, mutation = Format.SplitProduceKey(listing.ProduceKey)
					local crop = CropDefinitions[cropId]
					if crop then
						local row, actions = makeRow(ui.ModalContent, (mutation ~= "None" and mutation .. " " or "") .. crop.DisplayName, string.format("Seller %s   |   Qty %d   |   Price %s", listing.SellerName, listing.Quantity, Format.Commas(listing.Price)), rarityColor(crop.Rarity), 82)
						textButton(actions, listing.SellerUserId == player.UserId and "Yours" or "Buy", listing.SellerUserId == player.UserId and THEME.Panel or THEME.Green, function()
							if listing.SellerUserId ~= player.UserId then
								fire({ Type = "BuyAuction", ListingId = listing.Id })
							end
						end, 90, 38)
					end
				end
			elseif currentPanel == "Pets" then
				ui.ModalSubtitle.Text = "Equip buffs, browse rarity frames, and plan your next gem purchase."
				local equipped = state.Profile.EquippedPet and PetDefinitions[state.Profile.EquippedPet] or nil
				local equipRow = glassPanel(ui.ModalContent, {
					Size = UDim2.new(1, 0, 0, 180),
					BackgroundColor3 = THEME.Panel,
					BackgroundTransparency = 0.08,
				}, rarityColor(PET_RARITIES[state.Profile.EquippedPet] or "Common"))
				ui.PetEquipSlot = equipRow
				create("TextLabel", {
					Parent = equipRow,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 14),
					Size = UDim2.new(1, -280, 0, 24),
					Font = Enum.Font.GothamBlack,
					Text = equipped and ("Equipped: " .. equipped.DisplayName) or "No Pet Equipped",
					TextColor3 = THEME.Text,
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = equipRow,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 44),
					Size = UDim2.new(1, -280, 0, 48),
					Font = Enum.Font.Gotham,
					Text = equipped and equipped.Description or "Drag an owned pet card onto this glass slot to equip it.",
					TextWrapped = true,
					TextColor3 = THEME.Muted,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
				})
				create("TextLabel", {
					Parent = equipRow,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 144),
					Size = UDim2.new(1, -280, 0, 16),
					Font = Enum.Font.GothamMedium,
					Text = "Drag any owned pet card onto this slot to equip it instantly.",
					TextColor3 = THEME.Faint,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local previewShell = glassPanel(equipRow, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.fromOffset(220, 144),
					BackgroundColor3 = THEME.Glass,
					BackgroundTransparency = 0.04,
				}, THEME.Cyan)
				local viewport = create("ViewportFrame", {
					Parent = previewShell,
					Position = UDim2.fromOffset(10, 10),
					Size = UDim2.new(1, -20, 1, -20),
					BackgroundTransparency = 1,
				})
				local previewCamera = create("Camera", { Parent = viewport })
				viewport.CurrentCamera = previewCamera
				local previewModel = Instance.new("Model")
				previewModel.Parent = viewport
				local previewColor = rarityColor(PET_RARITIES[state.Profile.EquippedPet] or "Common")
				local orb = create("Part", {
					Parent = previewModel,
					Anchored = true,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(3.4, 3.4, 3.4),
					Color = previewColor,
					Material = Enum.Material.Neon,
					Position = Vector3.new(0, 0.7, 0),
				})
				local halo = create("Part", {
					Parent = previewModel,
					Anchored = true,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.18, 4.6, 4.6),
					Color = previewColor,
					Material = Enum.Material.Neon,
					Position = Vector3.new(0, 2.8, 0),
					Orientation = Vector3.new(0, 0, 90),
				})
				local wingLeft = create("Part", {
					Parent = previewModel,
					Anchored = true,
					CanCollide = false,
					CanTouch = false,
					CanQuery = false,
					Size = Vector3.new(0.6, 2, 2.2),
					Color = previewColor:Lerp(Color3.new(1, 1, 1), 0.2),
					Position = Vector3.new(-2.1, 0.5, 0),
				})
				local wingRight = wingLeft:Clone()
				wingRight.Parent = previewModel
				wingRight.Position = Vector3.new(2.1, 0.5, 0)
				previewCamera.CFrame = CFrame.new(Vector3.new(0, 1.1, 9), Vector3.new(0, 1, 0))
				ui.PetPreviewModel = previewModel
				if ui.PetPreviewSpin then
					ui.PetPreviewSpin:Disconnect()
				end
				ui.PetPreviewSpin = RunService.RenderStepped:Connect(function(deltaTime)
					if ui.PetPreviewModel then
						ui.PetPreviewModel:PivotTo(ui.PetPreviewModel:GetPivot() * CFrame.Angles(0, deltaTime * 0.8, 0))
					end
				end)
				local buffTray = create("Frame", {
					Parent = equipRow,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 102),
					Size = UDim2.fromOffset(430, 32),
				})
				local buffLayout = addLayout(buffTray, true)
				buffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				for buffName, amount in pairs(equipped and equipped.Buffs or {}) do
					local suffix = buffName == "PowerBonus" and tostring(amount) or (math.floor(amount * 100) .. "%")
					createMetricChip(buffTray, buffName:gsub("Bonus", "") .. " +" .. suffix, THEME.Green)
				end
				for petId, pet in pairs(PetDefinitions) do
					local owned = state.Profile.OwnedPets[petId]
					local rarity = PET_RARITIES[petId] or "Common"
					local row, actions = makeRow(ui.ModalContent, pet.DisplayName, pet.Description .. string.format("   |   %s   |   Cost %s Gems", rarity, Format.Commas((state.Market.Pets[petId] and state.Market.Pets[petId].CostGems) or pet.CostGems or 0)), rarityColor(rarity), 90)
					if owned then
						row.InputBegan:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
								return
							end
							if dragState and dragState.Ghost then
								dragState.Ghost:Destroy()
							end
							local ghost = glassPanel(ui.FloatLayer, {
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
								Size = UDim2.fromOffset(168, 48),
								BackgroundColor3 = THEME.Panel,
								BackgroundTransparency = 0.04,
								ZIndex = 98,
							}, rarityColor(rarity))
							create("TextLabel", {
								Parent = ghost,
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(1, 1),
								Font = Enum.Font.GothamBlack,
								Text = "Equip " .. pet.DisplayName,
								TextColor3 = THEME.Text,
								TextSize = 14,
								ZIndex = 99,
							})
							dragState = {
								PetId = petId,
								Ghost = ghost,
							}
						end)
					end
					if not owned then
						textButton(actions, "Buy", THEME.Gold, function()
							fire({ Type = "BuyPet", PetId = petId })
						end, 76, 38)
					end
					textButton(actions, state.Profile.EquippedPet == petId and "Equipped" or "Equip", THEME.Cyan, function()
						fire({ Type = "EquipPet", PetId = petId })
					end, 92, 38)
				end
			elseif currentPanel == "Daily" then
				ui.ModalSubtitle.Text = "Claim once per day to keep your streak and retention loop alive."
				local row, actions = makeRow(ui.ModalContent, "Daily Reward Shrine", "Claim once per day for coins and gems.", THEME.Gold, 86)
				textButton(actions, "Claim", THEME.Gold, function()
					fire({ Type = "ClaimDailyReward" })
				end, 92, 38)
				for index, reward in ipairs(state.Market.DailyRewards or Constants.DailyRewards) do
					local claimed = index <= (state.Profile.Daily.Streak or 0)
					local text = reward.Coins and (Format.Commas(reward.Coins) .. " Coins") or (tostring(reward.Gems) .. " Gems")
					makeRow(ui.ModalContent, "Day " .. index, text .. (claimed and "   |   Claimed" or "   |   Ready"), claimed and THEME.Green or THEME.Gold, 70)
				end
			elseif currentPanel == "Season" then
				ui.ModalSubtitle.Text = "Seasonal live-ops shell for premium simulator pacing."
				local monthTheme = {
					{ Name = "Bloom Festival", Accent = THEME.Green, Body = "Green crops and fresh mutations take the spotlight." },
					{ Name = "Crystal Carnival", Accent = THEME.Cyan, Body = "Blue rarity crops feel hotter during crystal events." },
					{ Name = "Volcanic Rush", Accent = THEME.Red, Body = "Explosive jackpots are the season headline." },
					{ Name = "Skyfall Harvest", Accent = THEME.Gold, Body = "Late-game celestial farming becomes the chase." },
				}
				local season = monthTheme[((os.date("*t").Month - 1) % #monthTheme) + 1]
				local banner = glassPanel(ui.ModalContent, {
					Size = UDim2.new(1, 0, 0, 110),
					BackgroundColor3 = season.Accent,
					BackgroundTransparency = 0.02,
				}, season.Accent)
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 14),
					Size = UDim2.new(1, -36, 0, 28),
					Font = Enum.Font.GothamBlack,
					Text = season.Name,
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 28,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 48),
					Size = UDim2.new(1, -36, 0, 34),
					Font = Enum.Font.GothamBold,
					Text = season.Body,
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				makeRow(ui.ModalContent, "Season Goal", "Harvest, mutate, and return daily to keep the live event loop compelling.", season.Accent, 74)
				makeRow(ui.ModalContent, "Reward Track", "Cosmetics, boosts, and leaderboard incentives belong here as the next live-ops step.", THEME.Purple, 74)
			elseif currentPanel == "Rebirth" then
				ui.ModalSubtitle.Text = "Long-term meta progression and replayability shell."
				local nextBiome = nil
				for _, biomeId in ipairs(Constants.BiomeOrder or {}) do
					if not state.Profile.UnlockedBiomes[biomeId] then
						nextBiome = BiomeDefinitions[biomeId]
						break
					end
				end
				makeRow(ui.ModalContent, "Current Rebirths: " .. tostring(state.Profile.Rebirths or 0), "Rebirth should reset your farm while preserving permanent sell, growth, and mutation bonuses.", THEME.Cyan, 90)
				makeRow(ui.ModalContent, "Meta Goal", nextBiome and ("Push toward " .. nextBiome.DisplayName .. " before your first rebirth.") or "Push beyond level 25 to earn a meaningful rebirth moment.", THEME.Cyan, 82)
				makeRow(ui.ModalContent, "Status", "Server-side rebirth action can be wired next. The UI shell is ready for it.", THEME.Gold, 74)
			elseif currentPanel == "Shop" then
				ui.ModalSubtitle.Text = "Premium cards, limited offer banner, and monetization-ready prompts."
				local offerEndsIn = 3600 - (os.time() % 3600)
				local banner = glassPanel(ui.ModalContent, {
					Size = UDim2.new(1, 0, 0, 110),
					BackgroundColor3 = THEME.Orange,
					BackgroundTransparency = 0.02,
				}, THEME.Orange)
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 14),
					Size = UDim2.new(1, -36, 0, 28),
					Font = Enum.Font.GothamBlack,
					Text = "Limited Farm Boost Offer",
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 28,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				create("TextLabel", {
					Parent = banner,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 48),
					Size = UDim2.new(1, -36, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = string.format("Refreshes in %02d:%02d", math.floor(offerEndsIn / 60), offerEndsIn % 60),
					TextColor3 = Color3.fromRGB(21, 17, 18),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				for _, product in ipairs(SHOP_PRODUCTS) do
					local row, actions = makeRow(ui.ModalContent, product.Title, product.Subtitle .. "   |   " .. product.PriceLabel, product.Accent, 86)
					textButton(actions, product.ProductId and "Buy" or "Config", product.Accent, function()
						if not product.ProductId then
							toast("Add your Roblox product ID in ClientApp.lua to enable this purchase.")
							return
						end
						if product.Type == "GamePass" then
							MarketplaceService:PromptGamePassPurchase(player, product.ProductId)
						else
							MarketplaceService:PromptProductPurchase(player, product.ProductId)
						end
					end, 92, 38)
				end
			elseif currentPanel == "Settings" then
				ui.ModalSubtitle.Text = "Local UI toggles for clarity, FX, and responsiveness."
				for _, option in ipairs({
					{ Key = "Tooltips", Title = "Tooltips", Body = "Show hover hints on menu and action buttons.", Accent = THEME.Cyan },
					{ Key = "ScreenFx", Title = "Screen FX", Body = "Enable mutation flash and jackpot camera shake.", Accent = THEME.Purple },
					{ Key = "FloatText", Title = "Floating Numbers", Body = "Show animated harvest and coin popups.", Accent = THEME.Green },
					{ Key = "ClickSounds", Title = "Click Sounds", Body = "Play tactile UI feedback when pressing buttons.", Accent = THEME.Orange },
				}) do
					local row, actions = makeRow(ui.ModalContent, option.Title, option.Body, option.Accent, 78)
					textButton(actions, localSettings[option.Key] and "On" or "Off", localSettings[option.Key] and option.Accent or THEME.Panel, function()
						localSettings[option.Key] = not localSettings[option.Key]
						renderModal()
					end, 88, 38)
				end
			end
		end

		local function refresh()
			if not ui.SeedList or not ui.InventoryList or not ui.Modal then
				return
			end
			if ui.ResourceCoins then
				animateResource("Coins", state.Profile.Coins or 0)
				animateResource("Gems", state.Profile.Gems or 0)
				animateResource("FarmLevel", state.Profile.Level or 1)
				animateResource("Rebirths", state.Profile.Rebirths or 0)
			end
			if ui.ProfileName then
				ui.ProfileName.Text = player.DisplayName
			end
			if ui.ProfileSub then
				ui.ProfileSub.Text = string.format("Plot %s   |   %s Tools   |   Power %d/%d", tostring(state.Runtime.PlotId or "?"), state.Profile.ToolTier or "Starter", state.Runtime.PowerUsage or 0, state.Runtime.PowerCapacity or Constants.FarmBasePower)
			end
			if ui.Contest then
				ui.Contest.Text = state.Contest.Active and ("Live now. " .. tostring(state.Contest.SecondsRemaining or 0) .. "s remaining.") or ("Next Mutation Clash in " .. tostring(state.Contest.SecondsRemaining or 0) .. "s")
			end
			if ui.GoalRows then
				local level = state.Profile.Level or 1
				local produceCount = 0
				for _, quantity in pairs(state.Profile.Produce or {}) do
					produceCount += quantity
				end
				local shortTarget = math.max(3, math.min(8, level + 2))
				local nextMachineId = nil
				for machineId, machine in pairs(MachineDefinitions) do
					if (state.Profile.OwnedMachines[machineId] or 0) <= 0 then
						if not nextMachineId or machine.Cost < MachineDefinitions[nextMachineId].Cost then
							nextMachineId = machineId
						end
					end
				end
				local nextBiome = nil
				for _, biomeId in ipairs(Constants.BiomeOrder or {}) do
					if not state.Profile.UnlockedBiomes[biomeId] then
						nextBiome = BiomeDefinitions[biomeId]
						break
					end
				end
				local goals = {
					{
						Key = "short_harvest",
						Description = ("Harvest or store %d produce this run"):format(shortTarget),
						Progress = math.clamp(produceCount / shortTarget, 0, 1),
						Reward = "Quick sell burst",
					},
					{
						Key = nextMachineId and ("mid_machine_" .. nextMachineId) or "mid_tools",
						Description = nextMachineId and ("Unlock " .. MachineDefinitions[nextMachineId].DisplayName) or (state.Market.NextToolTier and ("Upgrade to " .. state.Market.NextToolTier .. " tools") or "Max all tool tiers"),
						Progress = nextMachineId and math.clamp((state.Profile.Coins or 0) / MachineDefinitions[nextMachineId].Cost, 0, 1) or (state.Market.NextToolTier and math.clamp((state.Profile.Coins or 0) / math.max(1, state.Market.NextToolCost or 1), 0, 1) or 1),
						Reward = "Automation unlock",
					},
					{
						Key = nextBiome and ("long_biome_" .. nextBiome.Id) or "long_mastery",
						Description = nextBiome and ("Reach " .. nextBiome.DisplayName) or "Reach farm level 25 to prepare for rebirth.",
						Progress = nextBiome and math.clamp(level / nextBiome.UnlockLevel, 0, 1) or math.clamp(level / 25, 0, 1),
						Reward = "Long-term progression",
					},
				}
				for index, goal in ipairs(goals) do
					local row = ui.GoalRows[index]
					if row then
						row.Description.Text = goal.Description
						row.Fill.Size = UDim2.fromScale(goal.Progress, 1)
						row.Check.Text = goal.Progress >= 1 and "OK" or ""
						if goal.Progress >= 1 and not goalState[goal.Key] then
							goalState[goal.Key] = true
							toast("Goal complete! " .. goal.Reward)
							spawnFloatText("Goal Complete", THEME.Green)
						end
					end
				end
			end
			for _, entry in ipairs(MENU_ENTRIES) do
				local shell = ui.MenuButtons and ui.MenuButtons[entry.Id]
				if shell then
					local badgeText = ""
					local shouldGlow = false
					if entry.Id == "Daily" then
						local now = os.date("!*t")
						shouldGlow = state.Profile.Daily.LastClaimKey ~= Constants.GetDailyKey(now)
						badgeText = shouldGlow and "!" or ""
					elseif entry.Id == "Auction" and #(state.Auctions or {}) > 0 then
						shouldGlow = true
						badgeText = tostring(math.min(#state.Auctions, 9))
					elseif entry.Id == "Trade" and (state.Trade or state.TradeRequest or #(state.TradePlayers or {}) > 0) then
						shouldGlow = true
						badgeText = state.Trade and "On" or (state.TradeRequest and "!" or tostring(math.min(#state.TradePlayers, 9)))
					elseif entry.Id == "Automation" and (((state.Profile.Level or 1) >= 3) or ((state.Profile.OwnedMachines.Sprinkler or 0) > 0)) then
						shouldGlow = true
					elseif entry.Id == "Rebirth" and (state.Profile.Level or 1) >= 18 then
						shouldGlow = true
					end
					shell.Badge.Text = badgeText
					shell.Badge.Visible = badgeText ~= ""
					tween(shell.Glow, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = shouldGlow and 0.84 or 0.92,
					})
				end
			end
			renderSeeds()
			renderInventory()
			renderModal()
		end

		local function scaleUi()
			if ui.Scale and Workspace.CurrentCamera then
				local viewport = Workspace.CurrentCamera.ViewportSize
				ui.Scale.Scale = math.max(0.72, math.min(1, viewport.X / 1680, viewport.Y / 980))
				if ui.SeedPanel then
					ui.SeedPanel.Size = viewport.X < 1200 and UDim2.fromOffset(760, 210) or UDim2.fromOffset(720, 226)
				end
				if ui.InventoryPanel then
					ui.InventoryPanel.Size = viewport.X < 1200 and UDim2.fromOffset(388, 258) or UDim2.fromOffset(410, 296)
				end
				if ui.Modal then
					ui.Modal.Size = viewport.X < 1200 and UDim2.fromOffset(820, 600) or UDim2.fromOffset(920, 620)
				end
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
				DisplayOrder = 120,
			})
			ui.Scale = create("UIScale", { Parent = gui, Scale = 1 })
			ui.ClickSound = create("Sound", {
				Parent = gui,
				SoundId = "rbxasset://sounds/action_get.wav",
				Volume = 0.45,
			})

			local background = create("Frame", {
				Parent = gui,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = THEME.BackgroundTop,
				BorderSizePixel = 0,
				ZIndex = 0,
			})
			applyGradient(background, THEME.BackgroundTop, THEME.BackgroundBottom, 90)

			ui.FloatLayer = create("Frame", {
				Parent = gui,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 90,
			})
			ui.MutationFlash = create("Frame", {
				Parent = gui,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = THEME.Gold,
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 85,
			})

			local topSafe = GuiService:GetGuiInset().Y + 18
			ui.ProfileCard = glassPanel(gui, {
				Position = UDim2.fromOffset(18, topSafe),
				Size = UDim2.fromOffset(248, 92),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Orange)
			local avatarShell = create("Frame", {
				Parent = ui.ProfileCard,
				Position = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(62, 62),
				BackgroundColor3 = THEME.Glass,
			})
			applyCorner(avatarShell, 31)
			local avatarImage = create("ImageLabel", {
				Parent = avatarShell,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = safeThumbnail(),
			})
			applyCorner(avatarImage, 31)
			ui.ProfileName = create("TextLabel", {
				Parent = ui.ProfileCard,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(88, 16),
				Size = UDim2.new(1, -98, 0, 24),
				Font = Enum.Font.GothamBlack,
				Text = player.DisplayName,
				TextColor3 = THEME.Text,
				TextSize = 19,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.ProfileSub = create("TextLabel", {
				Parent = ui.ProfileCard,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(88, 42),
				Size = UDim2.new(1, -98, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = "Plot loading...",
				TextColor3 = THEME.Muted,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			create("TextLabel", {
				Parent = ui.ProfileCard,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(88, 60),
				Size = UDim2.new(1, -98, 0, 14),
				Font = Enum.Font.Gotham,
				Text = "Plant, water, mutate, sell, repeat.",
				TextColor3 = THEME.Faint,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local resourceBar = glassPanel(gui, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, topSafe),
				Size = UDim2.fromOffset(744, 92),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Gold)
			addPadding(resourceBar)
			local resourceLayout = addLayout(resourceBar, true)
			resourceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			local function createResourceTile(key, label, icon, accent, formatter)
				local tile = glassPanel(resourceBar, {
					Size = UDim2.fromOffset(170, 68),
					BackgroundColor3 = THEME.Glass,
					BackgroundTransparency = 0.06,
				}, accent)
				local scale = create("UIScale", { Parent = tile, Scale = 1 })
				local iconShell = create("Frame", {
					Parent = tile,
					Position = UDim2.fromOffset(10, 10),
					Size = UDim2.fromOffset(46, 46),
					BackgroundColor3 = accent,
				})
				applyCorner(iconShell, 14)
				create("TextLabel", {
					Parent = iconShell,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBlack,
					Text = icon,
					TextColor3 = Color3.fromRGB(18, 18, 24),
					TextSize = 18,
				})
				create("TextLabel", {
					Parent = tile,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(66, 10),
					Size = UDim2.new(1, -74, 0, 18),
					Font = Enum.Font.GothamBold,
					Text = label,
					TextColor3 = THEME.Muted,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local valueLabel = create("TextLabel", {
					Parent = tile,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(66, 24),
					Size = UDim2.new(1, -74, 0, 28),
					Font = Enum.Font.GothamBlack,
					Text = "0",
					TextColor3 = THEME.Text,
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local value = create("NumberValue", { Parent = tile, Value = 0 })
				value:GetPropertyChangedSignal("Value"):Connect(function()
					valueLabel.Text = formatter(math.floor(value.Value + 0.5))
				end)
				resourceState[key] = { Frame = tile, Scale = scale, Value = value }
				return tile
			end
			ui.ResourceCoins = createResourceTile("Coins", "Coins", "C", THEME.Orange, function(value) return Format.Commas(value) end)
			createResourceTile("Gems", "Gems", "G", THEME.Cyan, function(value) return Format.Commas(value) end)
			createResourceTile("FarmLevel", "Farm Level", "Lv", THEME.Green, function(value) return tostring(value) end)
			createResourceTile("Rebirths", "Rebirths", "Rb", THEME.Cyan, function(value) return tostring(value) end)

			local actionTray = create("Frame", {
				Parent = gui,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -18, 0, topSafe),
				Size = UDim2.fromOffset(128, 92),
				BackgroundTransparency = 1,
			})
			addLayout(actionTray, false)
			textButton(actionTray, "Settings", THEME.Panel, function()
				currentPanel = "Settings"
				renderModal()
			end, 128, 40, "Local UI and FX settings.")
			textButton(actionTray, "Shop", THEME.Orange, function()
				currentPanel = "Shop"
				renderModal()
			end, 128, 40, "Premium shop cards and limited offers.")

			local goalPanel = glassPanel(gui, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, topSafe + 104),
				Size = UDim2.fromOffset(632, 162),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Green)
			create("TextLabel", {
				Parent = goalPanel,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 14),
				Size = UDim2.new(1, -36, 0, 24),
				Font = Enum.Font.GothamBlack,
				Text = "Live Goals",
				TextColor3 = THEME.Text,
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			create("TextLabel", {
				Parent = goalPanel,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 38),
				Size = UDim2.new(1, -36, 0, 16),
				Font = Enum.Font.Gotham,
				Text = "Short, mid, and long-term hooks keep every session moving.",
				TextColor3 = THEME.Muted,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.GoalRows = {}
			for index, title in ipairs({ "Short Goal", "Medium Goal", "Long Goal" }) do
				local row = glassPanel(goalPanel, {
					Position = UDim2.fromOffset(16, 58 + ((index - 1) * 32)),
					Size = UDim2.new(1, -32, 0, 26),
					BackgroundColor3 = THEME.Glass,
					BackgroundTransparency = 0.08,
				}, index == 1 and THEME.Orange or (index == 2 and THEME.Green or THEME.Cyan))
				create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.fromOffset(104, 26),
					Font = Enum.Font.GothamBold,
					Text = title,
					TextColor3 = THEME.Text,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local description = create("TextLabel", {
					Parent = row,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(118, 0),
					Size = UDim2.new(1, -250, 1, 0),
					Font = Enum.Font.Gotham,
					Text = "-",
					TextColor3 = THEME.Muted,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local bar = create("Frame", {
					Parent = row,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -44, 0.5, 0),
					Size = UDim2.fromOffset(86, 8),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.84,
					BorderSizePixel = 0,
				})
				applyCorner(bar, 8)
				local fill = create("Frame", {
					Parent = bar,
					Size = UDim2.fromScale(0, 1),
					BackgroundColor3 = index == 1 and THEME.Orange or (index == 2 and THEME.Green or THEME.Cyan),
					BorderSizePixel = 0,
				})
				applyCorner(fill, 8)
				local check = create("TextLabel", {
					Parent = row,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(22, 22),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBlack,
					Text = "",
					TextColor3 = THEME.Green,
					TextSize = 16,
				})
				ui.GoalRows[index] = { Description = description, Fill = fill, Check = check }
			end

			ui.MenuRail = create("Frame", {
				Parent = gui,
				Position = UDim2.fromOffset(18, topSafe + 112),
				Size = UDim2.fromOffset(166, 494),
				BackgroundTransparency = 1,
			})
			addLayout(ui.MenuRail, false)
			ui.MenuButtons = {}
			for _, entry in ipairs(MENU_ENTRIES) do
				local shell = glassPanel(ui.MenuRail, {
					Size = UDim2.fromOffset(166, 48),
					BackgroundColor3 = THEME.Panel,
					BackgroundTransparency = 0.06,
				}, entry.Accent)
				local scale = create("UIScale", { Parent = shell, Scale = 1 })
				local hit = create("TextButton", {
					Parent = shell,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
				})
				local iconShell = create("Frame", {
					Parent = shell,
					Position = UDim2.fromOffset(10, 8),
					Size = UDim2.fromOffset(32, 32),
					BackgroundColor3 = entry.Accent,
				})
				applyCorner(iconShell, 10)
				create("TextLabel", {
					Parent = iconShell,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBlack,
					Text = entry.Icon,
					TextColor3 = Color3.fromRGB(18, 18, 24),
					TextSize = 14,
				})
				create("TextLabel", {
					Parent = shell,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(50, 0),
					Size = UDim2.new(1, -86, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = entry.Id,
					TextColor3 = THEME.Text,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local badge = create("TextLabel", {
					Parent = shell,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(26, 20),
					BackgroundColor3 = entry.Accent,
					BackgroundTransparency = 0.08,
					Font = Enum.Font.GothamBlack,
					Text = "",
					TextColor3 = Color3.fromRGB(18, 18, 24),
					TextSize = 11,
					Visible = false,
				})
				applyCorner(badge, 10)
				local glow = create("Frame", {
					Parent = shell,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, 8, 1, 8),
					BackgroundColor3 = entry.Accent,
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					ZIndex = 0,
				})
				applyCorner(glow, 18)
				hit.MouseEnter:Connect(function()
					tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.04 })
					tween(glow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.82 })
				end)
				hit.MouseLeave:Connect(function()
					tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
					tween(glow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.92 })
				end)
				hit.MouseButton1Click:Connect(function()
					playClick()
					currentPanel = entry.Id
					renderModal()
				end)
				bindTooltip(hit, entry.Tooltip)
				ui.MenuButtons[entry.Id] = { Badge = badge, Glow = glow }
			end

			ui.SeedPanel = glassPanel(gui, {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 18, 1, -18),
				Size = UDim2.fromOffset(720, 226),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Green)
			local seedHeader = createSectionTitle(ui.SeedPanel, "Seed Loadout", "Tap a seed card, equip your hoe, then click your farm tiles.")
			seedHeader.Position = UDim2.fromOffset(16, 12)
			ui.SeedMeta = create("TextLabel", {
				Parent = ui.SeedPanel,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 52),
				Size = UDim2.new(1, -32, 0, 16),
				Font = Enum.Font.Gotham,
				Text = "",
				TextColor3 = THEME.Faint,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.SeedList = create("ScrollingFrame", {
				Parent = ui.SeedPanel,
				Position = UDim2.fromOffset(10, 78),
				Size = UDim2.new(1, -20, 1, -88),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarThickness = 6,
			})

			ui.InventoryPanel = glassPanel(gui, {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -18, 1, -18),
				Size = UDim2.fromOffset(410, 296),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Blue)
			local inventoryHeader = createSectionTitle(ui.InventoryPanel, "Barn Inventory", "Harvested stacks, mutation value, and quick sell actions.")
			inventoryHeader.Position = UDim2.fromOffset(16, 12)
			ui.InventoryMeta = create("TextLabel", {
				Parent = ui.InventoryPanel,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 52),
				Size = UDim2.new(1, -32, 0, 16),
				Font = Enum.Font.Gotham,
				Text = "",
				TextColor3 = THEME.Faint,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.InventoryList = create("ScrollingFrame", {
				Parent = ui.InventoryPanel,
				Position = UDim2.fromOffset(10, 78),
				Size = UDim2.new(1, -20, 1, -88),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarThickness = 6,
			})

			local contest = glassPanel(gui, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -18, 0, topSafe + 112),
				Size = UDim2.fromOffset(300, 148),
				BackgroundColor3 = THEME.Panel,
				BackgroundTransparency = 0.08,
			}, THEME.Purple)
			create("TextLabel", {
				Parent = contest,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 14),
				Size = UDim2.new(1, -32, 0, 24),
				Font = Enum.Font.GothamBlack,
				Text = "Mutation Clash",
				TextColor3 = THEME.Text,
				TextSize = 21,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.Contest = create("TextLabel", {
				Parent = contest,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 42),
				Size = UDim2.new(1, -32, 0, 52),
				Font = Enum.Font.Gotham,
				Text = "",
				TextWrapped = true,
				TextColor3 = THEME.Muted,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})

			ui.ModalBackdrop = create("TextButton", {
				Parent = gui,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 1,
				Text = "",
				Visible = false,
				AutoButtonColor = false,
				ZIndex = 40,
			})
			ui.ModalBackdrop.MouseButton1Click:Connect(function()
				currentPanel = nil
				renderModal()
			end)
			ui.Modal = glassPanel(gui, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(920, 620),
				BackgroundColor3 = THEME.Glass,
				BackgroundTransparency = 0.04,
				Visible = false,
				ZIndex = 41,
			}, THEME.Gold)
			ui.ModalScale = create("UIScale", { Parent = ui.Modal, Scale = 1 })
			ui.ModalTitle = create("TextLabel", {
				Parent = ui.Modal,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(24, 18),
				Size = UDim2.new(1, -150, 0, 30),
				Font = Enum.Font.GothamBlack,
				TextColor3 = THEME.Text,
				TextSize = 28,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			ui.ModalSubtitle = create("TextLabel", {
				Parent = ui.Modal,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(24, 50),
				Size = UDim2.new(1, -150, 0, 18),
				Font = Enum.Font.Gotham,
				TextColor3 = THEME.Muted,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			local closeButton = textButton(ui.Modal, "Close", THEME.Red, function()
				currentPanel = nil
				renderModal()
			end, 110, 40, "Close this panel.")
			closeButton.Position = UDim2.new(1, -128, 0, 18)
			ui.ModalContent = create("ScrollingFrame", {
				Parent = ui.Modal,
				Position = UDim2.fromOffset(18, 84),
				Size = UDim2.new(1, -36, 1, -102),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarThickness = 6,
			})

			ui.TooltipFrame = glassPanel(gui, {
				Size = UDim2.fromOffset(240, 56),
				BackgroundColor3 = THEME.Glass,
				BackgroundTransparency = 0.04,
				Visible = false,
				ZIndex = 130,
			}, THEME.Cyan)
			ui.Tooltip = create("TextLabel", {
				Parent = ui.TooltipFrame,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.new(1, -24, 1, -16),
				Font = Enum.Font.Gotham,
				Text = "",
				TextWrapped = true,
				TextColor3 = THEME.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			})

			ui.ToastFrame = glassPanel(gui, {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 42),
				Size = UDim2.fromOffset(560, 56),
				BackgroundColor3 = THEME.Glass,
				BackgroundTransparency = 0.1,
				Visible = false,
				ZIndex = 100,
			}, THEME.Orange)
			local toastAccent = create("Frame", {
				Parent = ui.ToastFrame,
				Position = UDim2.fromOffset(10, 10),
				Size = UDim2.fromOffset(36, 36),
				BackgroundColor3 = THEME.Orange,
			})
			applyCorner(toastAccent, 14)
			ui.ToastLabel = create("TextLabel", {
				Parent = ui.ToastFrame,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(58, 0),
				Size = UDim2.new(1, -70, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "",
				TextColor3 = THEME.Text,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			scaleUi()
			if Workspace.CurrentCamera then
				Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(scaleUi)
			end
		end

		local function normalizeState()
			state.Profile = state.Profile or {}
			state.Profile.Coins = state.Profile.Coins or 0
			state.Profile.Gems = state.Profile.Gems or 0
			state.Profile.Level = state.Profile.Level or 1
			state.Profile.Rebirths = state.Profile.Rebirths or 0
			state.Profile.XP = state.Profile.XP or 0
			state.Profile.XPNeeded = state.Profile.XPNeeded or Constants.GetLevelXP(state.Profile.Level)
			state.Profile.UnlockedBiomes = state.Profile.UnlockedBiomes or {}
			state.Profile.UnlockedSeeds = state.Profile.UnlockedSeeds or {}
			state.Profile.Seeds = state.Profile.Seeds or {}
			state.Profile.Produce = state.Profile.Produce or {}
			state.Profile.OwnedMachines = state.Profile.OwnedMachines or {}
			state.Profile.OwnedPets = state.Profile.OwnedPets or {}
			state.Profile.Runtime = state.Profile.Runtime or {}
			state.Profile.Daily = state.Profile.Daily or {}
			state.Profile.Stats = state.Profile.Stats or {}
			state.Market = state.Market or { Crops = {}, Machines = {}, Pets = {}, DailyRewards = {} }
			state.Market.Crops = state.Market.Crops or {}
			state.Market.Machines = state.Market.Machines or {}
			state.Market.Pets = state.Market.Pets or {}
			state.Market.DailyRewards = state.Market.DailyRewards or {}
			state.Runtime = state.Runtime or {}
			state.Contest = state.Contest or {}
			state.Auctions = state.Auctions or {}
			state.TradePlayers = state.TradePlayers or {}
			state.Trade = state.Trade or nil
			state.TradeRequest = state.TradeRequest or nil
		end

		local function applyState(newState)
			if typeof(newState) == "table" then
				state = newState
				normalizeState()
				if state.Trade then
					local mySide = state.Trade.Left.UserId == player.UserId and state.Trade.Left or state.Trade.Right
					offerDraft.Items = {}
					offerDraft.Coins = mySide.Coins or 0
					for produceKey, quantity in pairs(mySide.Items or {}) do
						offerDraft.Items[produceKey] = quantity
					end
				end
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
				parseNotification(payload.Message or "")
			elseif payload.Type == "TradeRequest" then
				state.TradeRequest = {
					FromUserId = payload.FromUserId,
					FromName = payload.FromName,
				}
				currentPanel = "Trade"
				refresh()
				toast(payload.FromName .. " sent a trade request.")
			elseif payload.Type == "TradeUpdate" then
				state.Trade = payload.Trade
				state.TradeRequest = nil
				if state.Trade then
					local mySide = state.Trade.Left.UserId == player.UserId and state.Trade.Left or state.Trade.Right
					offerDraft.Items = {}
					offerDraft.Coins = mySide.Coins or 0
					for produceKey, quantity in pairs(mySide.Items or {}) do
						offerDraft.Items[produceKey] = quantity
					end
				end
				currentPanel = "Trade"
				refresh()
			elseif payload.Type == "TradeClosed" then
				state.Trade = nil
				state.TradeRequest = nil
				offerDraft = { Items = {}, Coins = 0 }
				refresh()
				toast(payload.Reason or "Trade closed.")
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragState or not dragState.Ghost then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			dragState.Ghost.Position = UDim2.fromOffset(input.Position.X, input.Position.Y)
		end)

		UserInputService.InputEnded:Connect(function(input)
			if not dragState or not dragState.Ghost then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local pointer = input.Position
			if ui.PetEquipSlot and pointInside(ui.PetEquipSlot, pointer) then
				fire({ Type = "EquipPet", PetId = dragState.PetId })
			end
			dragState.Ghost:Destroy()
			dragState = nil
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
