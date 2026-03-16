local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local remoteFolder = ReplicatedStorage:FindFirstChild(Remotes.FolderName)
if remoteFolder then
	remoteFolder:Destroy()
end

remoteFolder = Instance.new("Folder")
remoteFolder.Name = Remotes.FolderName
remoteFolder.Parent = ReplicatedStorage

local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = Remotes.ActionEventName
actionEvent.Parent = remoteFolder

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = Remotes.StateEventName
stateEvent.Parent = remoteFolder

local requestState = Instance.new("RemoteFunction")
requestState.Name = Remotes.RequestStateFunctionName
requestState.Parent = remoteFolder

local services = {
	DataService = require(ServerScriptService.Services.DataService),
	ProgressionService = require(ServerScriptService.Services.ProgressionService),
	ToolService = require(ServerScriptService.Services.ToolService),
	WorldBuilder = require(ServerScriptService.Services.WorldBuilder),
	PlotService = require(ServerScriptService.Services.PlotService),
	CropService = require(ServerScriptService.Services.CropService),
	AutomationService = require(ServerScriptService.Services.AutomationService),
	EconomyService = require(ServerScriptService.Services.EconomyService),
	TradingService = require(ServerScriptService.Services.TradingService),
	CompetitionService = require(ServerScriptService.Services.CompetitionService),
	InteractionService = require(ServerScriptService.Services.InteractionService),
}

local context = {
	Services = services,
	RemoteFolder = remoteFolder,
}

for _, service in pairs(services) do
	if service.Init then
		service:Init(context)
	end
end

context.World = services.WorldBuilder:BuildWorld()
services.PlotService:RegisterWorld(context.World)

for _, service in pairs(services) do
	if service.Start then
		service:Start()
	end
end

local function onPlayerAdded(player)
	services.DataService:LoadPlayer(player)
	services.ProgressionService:OnPlayerAdded(player)
	services.PlotService:AssignPlot(player)
	services.ToolService:RefreshTools(player)
	services.InteractionService:PushTradeRoster()

	player.CharacterAdded:Connect(function()
		task.wait(0.6)
		services.ToolService:RefreshTools(player)
		services.PlotService:TeleportToPlot(player)
	end)

	task.defer(function()
		services.InteractionService:PushFullState(player)
	end)
end

local function onPlayerRemoving(player)
	services.TradingService:HandlePlayerRemoving(player)
	services.PlotService:ReleasePlot(player)
	services.DataService:UnloadPlayer(player)
	services.InteractionService:PushTradeRoster()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)
