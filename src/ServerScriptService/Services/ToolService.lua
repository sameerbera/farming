local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ToolDefinitions = require(ReplicatedStorage.Shared.ToolDefinitions)

local ToolService = {}

local function createFarmTool(toolKind, tierName)
	local tool = Instance.new("Tool")
	tool.Name = string.format("%s %s", tierName, toolKind)
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute("FarmMutationTool", true)
	tool:SetAttribute("ToolKind", toolKind)
	tool:SetAttribute("TierName", tierName)
	return tool
end

function ToolService:Init(context)
	self.Context = context
end

function ToolService:RefreshTools(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	local tierName = self.Context.Services.DataService:GetProfile(player).ToolTier or "Starter"

	for _, container in ipairs({ backpack, player:FindFirstChild("StarterGear"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("FarmMutationTool") then
					child:Destroy()
				end
			end
		end
	end

	for _, toolKind in ipairs(Constants.ToolKinds) do
		local tool = createFarmTool(toolKind, tierName)
		tool.Parent = backpack

		local starterCopy = tool:Clone()
		local starterGear = player:FindFirstChild("StarterGear")
		if starterGear then
			starterCopy.Parent = starterGear
		else
			starterCopy:Destroy()
		end
	end
end

function ToolService:GetEquippedToolKind(player)
	local character = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("FarmMutationTool") then
			return child:GetAttribute("ToolKind")
		end
	end

	return nil
end

function ToolService:GetToolStats(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	local tierName = profile and profile.ToolTier or "Starter"
	return ToolDefinitions[tierName]
end

function ToolService:GetNextTier(player)
	local profile = self.Context.Services.DataService:GetProfile(player)
	local currentTier = profile and profile.ToolTier or "Starter"

	for index, tierName in ipairs(Constants.ToolTiers) do
		if tierName == currentTier then
			return Constants.ToolTiers[index + 1]
		end
	end

	return nil
end

return ToolService
