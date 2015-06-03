-----------------------------------------------------------------------------------------------
-- Chomp
--- Vim <Codex>
 
Chomp = {
	name = "Chomp",
	version = {},
}

function Chomp:OnLoad()
 	self.xmlDoc = XmlDoc.CreateFromFile("Chomp.xml")
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ChompForm", nil, self)
	Apollo.RegisterSlashCommand("chomp", "OnChompOn", self)
end

function Chomp:OnSlashCommand() self.wndMain:Invoke() end

Apollo.RegisterAddon(Chomp)