-----------------------------------------------------------------------------------------------
-- Chomp
--- Vim <Codex>
 
Chomp = {
	name = "Chomp",
	version = {},
	GameVars = {
		fClock = 0.1,     -- max messages sent : 25 per second
		StartRadius = 15,
	},
	bDebug = true,
	tPlayers = {},
}

function Chomp:OnLoad()
 	self.xmlDoc = XmlDoc.CreateFromFile("Chomp.xml")
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "Chomp", nil, self)
	self.wndDebug = self.wndMain:FindChild("Debug")
	
	self.channel = ICCommLib.JoinChannel("Chomp", ICCommLib.CodeEnumICCommChannelType.Guild, self.Utils.GetGuild())
	self.channel:SetJoinResultFunction("OnJoinResult", self)
	self.channel:SetReceivedMessageFunction("OnMessageReceived", self)
	self.channel:SetSendMessageResultFunction("OnMessageSent", self)
	self.channel:SetThrottledFunction("OnMessageThrottled", self)
	
	Apollo.RegisterSlashCommand("chomp", "OnSlashCommand", self)
end

-- UI Drawing functions

function Chomp:AddPixie(tOptions) return self.wndMain:AddPixie(tOptions) end
function Chomp:DestroyPixie(idPixie) self.wndMain:DestroyPixie(idPixie) end

function Chomp:UpdatePixie(idPixie, tOptions)
	local tPixieOptions = self.wndMain:GetPixieInfo(idPixie)
	for k,v in pairs(tOptions) do tPixieOptions[k] = v end
	return self.wndMain:UpdatePixie(idPixie, tPixieOptions)
end

function Chomp:GetCanvasCenter()
	local wndCanvas = self.wndMain
	return wndCanvas:GetWidth()/2, wndCanvas:GetHeight()/2
end

-- Player class

Chomp.Player = {
	UpdatePos = function(self, x, y)
		self.posX = x
		self.posY = y
		local r = self.radius
		Chomp:UpdatePixie(self.pixies.circle, {loc = {nOffsets = {x-r,y-r,x+r,y+r}}})
	end,
	new = function(x,y,cr)
		local player = {
			radius = Chomp.GameVars.StartRadius,
			posX = x,
			posY = y,
			pixies = {
				circle = Chomp:AddPixie({strSprite = "WhiteCircle", cr = cr or Chomp.Utils.RandomColor(), loc = {nOffsets = {0,0,0,0}}}),
			},
		}
		
		setmetatable(player, {__index = Chomp.Player}) 
		player:UpdatePos(x,y)
		
		return player
	end,
	Destroy = function(self)
		Chomp:DestroyPixie(self.pixies.circle)
	end,
}

-- Game Logic

function Chomp:StartGame()
	self.player = self.Player.new(self:GetCanvasCenter())
	Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
	self.tmrClock = ApolloTimer.Create(self.GameVars.fClock, true, "OnUpdate", self)
end

function Chomp:StopGame()
	Apollo.RemoveEventHandler("NextFrame", self)
	self.tmrClock:Stop()
	self.tmrClock = nil
	self.player:Destroy()
	self.player = nil
	self:SendQuit()
end

-- Main loop

function Chomp:OnFrame()
	local tMouse = self.wndMain:GetMouse()
	self.wndDebug:SetText("x: "..tMouse.x.." - y: "..tMouse.y)
	self.player:UpdatePos(tMouse.x, tMouse.y)
end

function Chomp:OnUpdate()
	self:SendPos(self.player.posX, self.player.posY)
end

-- Addon Communication

function Chomp:OnMessageReceived(channel, strMessage, strSender)
	local x,y = tonumber(strMessage:sub(1,4)),tonumber(strMessage:sub(5,8))
	local player = self.tPlayers[strSender]
	if not player then
		self.tPlayers[strSender] = Chomp.Player.new(x,y)
	else
		if strMessage == "" then
			player:Destroy()
		else
			player:UpdatePos(x,y)
		end
	end
end

function Chomp:SendMessageResultEvent()
end

function Chomp:OnJoinResult(...)       self.Utils.Debug("Join",      arg) end
function Chomp:OnMessageThrottled(...) self.Utils.Debug("Throttled", arg) end
function Chomp:OnMessageSent(...)      self.Utils.Debug("Sent",      arg) end

function Chomp:SendPos(x,y)
	self.channel:SendMessage(string.format("%4u%4u", x, y))
end

function Chomp:SendQuit()
	self.channel:SendMessage("")
end

-- UI Event Handlers

function Chomp:OnSlashCommand() 
	self.wndMain:Invoke()
	self:StartGame()
end

function Chomp:OnCloseWindow()
	self:StopGame()
end

-- Utils

Chomp.Utils = {
	RandomColor = function() return ApolloColor.new(2*math.random(),2*math.random(),2*math.random()) end,
	GetGuild = function() 
		for i,g in pairs(GuildLib.GetGuilds()) do
			if g:GetType() == GuildLib.GuildType_Guild then return g end
		end
	end,
	Debug = function(str, ...)
		if Chomp.bDebug and Apollo.GetAddon("Rover") then SendVarToRover("ChompDebug - "..str, arg) end
	end,
}

Apollo.RegisterAddon(Chomp)