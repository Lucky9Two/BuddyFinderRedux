
-------------------------------------------------------
-------------------------------------------------------
--	BuddyFinder by AncientEvil
--	Profile Link:	http://steamcommunity.com/id/
--	Modern Update by V92
--	Profile Link:	http://steamcommunity.com/id/JesseVanover/
--	Workshop Link:	http://steamcommunity.com/sharedfiles/filedetails/?id=534923023
-------------------------------------------------------
-------------------------------------------------------

AddCSLuaFile()

function Dbg(debugstring)
	if bf_debug_mode then
		print(debugstring)
	end
end

if CLIENT then

	surface.CreateFont("BuddyFinderHUDText", {		size = 32,	weight = 200,	antialias = true,	shadow = false,	font = "Impact"})
	surface.CreateFont("BuddyFinderHUDIcon", {		size = 72,	weight = 200,	antialias = true,	shadow = false,	font = "phones"})

	HUDBox = {}
	HUDBox.Colour = Color(0, 0, 0, 75)
	function HUDBox:GetWidth()
		--return ScreenScale(35)
		return 96
	end
	function HUDBox:GetHeight()
		--return ScreenScale(38)
		return 96
	end
	HUDBox.Corners = 8
	function HUDBox:GetX()
		--return ScreenScale(590)
		return ScrW() / 2
	end
	function HUDBox:GetY()
		--return ScreenScale(315)
		return ScrH() * 0.9
	end

	HUDIcon = {}
	HUDIcon.PhoneChar = "D"
	function HUDIcon:GetSize()
		--return ScreenScale(31)
		return 64
	end

	HUDIcon.FontExternalName = "Phones"
	HUDIcon.FontInternalName = "BuddyFinderHUDIcon"
	HUDIcon.FontWeight = 500
	HUDIcon.Antialias = true
	HUDIcon.Italic = false
	function HUDIcon:GetX()
		return HUDBox.X + (HUDBox.Width / 2) + ScreenScale(1.25) --offset
	end
	function HUDIcon:GetY()
		return HUDBox.Y + (HUDBox.Height / 3) - (self.Size / 2)
	end

	HUDText = {}
	function HUDText:GetSize()
		//return ScreenScale(10)
		return 48
	end

	HUDText.FontExternalName = "Impact"
	HUDText.FontInternalName = "BuddyFinderHUDText"
	HUDText.FontWeight = 200
	HUDText.Antialias = true
	HUDText.Italic = false
	function HUDText:GetX()
		--return HUDIcon.X - ScreenScale(0.625)
		return HUDIcon.X
	end
	function HUDText:GetY()
		--return HUDIcon.Y + HUDIcon.Size - ScreenScale(1.25) --offset
		return (HUDIcon.Y + HUDIcon.Size) - (ScrH() * 0.005)  --offset
	end

	BFHUDNotification = {}
	BFHUDNotification.bfhnIncoming = {Snd = Sound("npc/scanner/combat_scan1.wav"), 
									Caption = "INCOMING", 
									Loop = true,
									HighColour = Color(255, 232, 55, 255), 
									LowColour = Color(200, 177, 0, 100)}
	BFHUDNotification.bfhnOutgoing = {Snd = Sound("npc/scanner/scanner_scan2.wav"), 
									Caption = "CALLING", 
									Loop = true,
									HighColour = Color(255, 255, 101, 255), 
									LowColour = Color(200, 200, 50, 100)}
	BFHUDNotification.bfhnAccepted = {Snd=Sound("buttons/button14.wav"), 
									Caption = "ACCEPTED", 
									Loop = false,
									HighColour = Color(152, 240, 46, 200)}
	BFHUDNotification.bfhnDenied	 = {Snd=Sound("buttons/button8.wav"), 
									Caption = "DENIED", 
									Loop = false,
									HighColour = Color(227, 60, 56, 200)}
	BFHUDNotification.bfhnBusy	= {Snd=Sound("buttons/blip1.wav"), 
									Caption = "BUSY", 
									Loop = false,
									HighColour = Color(255, 185, 78, 200)}

	BFHUDObject = {}
	BFHUDObject.IsSetup = false

	ScreenDims = {}
	ScreenDims.X = 0
	ScreenDims.Y = 0

	--updates screen objects if the resolution changes
	function ScreenDims:Update()
		if (self.Updating) then
			return
		end
		self.Updating = true
		Dbg('Updating BuddyFinder Screen Objects...')
		for k, v in pairs({HUDBox, HUDIcon, HUDText}) do
			if (v == HUDBox) then
		 v.Width = v:GetWidth()
		 v.Height = v:GetHeight()
			else
		 v.Size = v:GetSize()
			end
			v.X = v:GetX()
			v.Y = v:GetY()
		end
		self.X = ScrW()
		self.Y = ScrH()
		self.Updating = false
	end

	function BFHUDObject:CurrentColour()
		local bfhudcolour = {}
		if self.FlashHigh then
			bfhudcolour = table.Copy(self.HighColour)
		else
			bfhudcolour = table.Copy(self.LowColour)
		end
		--and apply alpha for fades
		bfhudcolour.a = bfhudcolour.a * self.Alpha
		return bfhudcolour
	end

	function BFHUDObject:BoxColour()
		local bfhudboxcolour = table.Copy(HUDBox.Colour)
		--apply alpha for fades
		bfhudboxcolour.a = bfhudboxcolour.a * self.Alpha
		return bfhudboxcolour
	end

	function GetClientBuddy(	ply	)
		local _W = ply:GetWeapons()
		for k, v in pairs(_W) do
			if v:GetPrintName() == "Buddy Finder" then
				return v
			end
		end
	end

	function HUDBuddyFinderNotify()
		if (ScreenDims.X != ScrW())
		or (ScreenDims.Y != ScrH()) then
			ScreenDims:Update()
		end
		draw.RoundedBox(HUDBox.Corners, HUDBox.X, HUDBox.Y, HUDBox.Width, HUDBox.Height, BFHUDObject:BoxColour())
		draw.DrawText(HUDIcon.PhoneChar, HUDIcon.FontInternalName, HUDIcon.X, HUDIcon.Y, BFHUDObject:CurrentColour(), TEXT_ALIGN_CENTER) 
		draw.DrawText(BFHUDObject.Caption, HUDText.FontInternalName, HUDText.X, HUDText.Y, BFHUDObject:CurrentColour(), TEXT_ALIGN_CENTER)
	end

	function SetupHUDObject(notification)
		if BFHUDObject.IsSetup then
			UnSetupHUDObject()
		end
		BFHUDObject.Alpha = 1.0
		BFHUDObject.FlashHigh = false
		BFHUDObject.PlayCount = 0
		BFHUDObject.Caption = notification.Caption
		BFHUDObject.HighColour = notification.HighColour
		if notification.Loop then
			BFHUDObject.LowColour = notification.LowColour
		end
		BFHUDObject.Loops = notification.Loop
		BFHUDObject.Snd = CreateSound(LocalPlayer(), notification.Snd)
		hook.Add("HUDPaint", "HUDBuddyFinderNotify", HUDBuddyFinderNotify)
		BFHUDObject.IsSetup = true
	end

	function UnSetupHUDObject()
		timer.Remove("HUDObjectTimer")
		timer.Remove("HUDFadeoutTimer")
		hook.Remove("HUDPaint", "HUDBuddyFinderNotify")
		BFHUDObject.Notification = nil
		if (BFHUDObject.Snd != nil) then
			BFHUDObject.Snd:Stop()
			BFHUDObject.Snd = nil
		end
		BFHUDObject.IsSetup = false
	end

	function FadeHUDObject()
		BFHUDObject.Alpha = BFHUDObject.Alpha - 0.05
		if (BFHUDObject.Alpha <= 0) then
			timer.Stop("HUDFadeoutTimer")
			UnSetupHUDObject()
		end
	end

	function StartHUDFadeOut()
		timer.Create("HUDFadeoutTimer", 0.1, 30, function() FadeHUDObject() end)
	end

	function PlayHUDObject()
		BFHUDObject.FlashHigh = !BFHUDObject.FlashHigh
		if ((BFHUDObject.PlayCount == 0) or BFHUDObject.Loops) and BFHUDObject.FlashHigh then
			BFHUDObject.Snd:Stop()
			BFHUDObject.Snd:Play()
		end
		--if this is a looping object, set a timer to play us again
		--only on the first play, though
		local createTimer = (BFHUDObject.PlayCount == 0) and BFHUDObject.Loops

		if !BFHUDObject.Loops then
			--if we don't loop then we fade out
			timer.Simple(2, function() StartHUDFadeOut() end)
		end
		BFHUDObject.PlayCount = BFHUDObject.PlayCount + 1

		if createTimer then	 
			timer.Create("HUDObjectTimer", 1.5, 20, function() PlayHUDObject() end)
		end
	end

	function BuddyFinderHUDNotify(um)
		--expects one of two messages - either a cancellation message
		--which contains only a boolean (false) or a notification message
		--which contains the following:
		--bool - true
		--string - hud notification type e.g. bfhnIncoming
		local enable = um:ReadBool()
		if enable then
			--read the rest and use it to set up the notification object
			SetupHUDObject(BFHUDNotification[um:ReadString()])
			--play the HUD Object once (at least)
			PlayHUDObject()
		else
			UnSetupHUDObject()
		end
	end
	usermessage.Hook("buddy_finder_hud_notify", BuddyFinderHUDNotify)

	function PopulateList(um)
		--If the player has a buddy finder then allow him/her to receive the call
		local ply = LocalPlayer()
			local targetBuddy = GetClientBuddy(	ply	)
			if (targetBuddy != nil) then
		 targetBuddy:PopulateThenShowList(um)
			end 
	end
	usermessage.Hook("PopulatePhonePlayerList", PopulateList)

	--run once to define dimensions
	function InitScreenDims()
		--print('Initialising BuddyFinder...')
		ScreenDims:Update()
		--print('Adding BuddyFinder Fonts...')
		--surface.CreateFont(HUDIcon.FontExternalName, HUDIcon.Size, HUDIcon.FontWeight, HUDIcon.Antialias, HUDIcon.Italic, HUDIcon.FontInternalName)
		--surface.CreateFont(HUDText.FontExternalName, HUDText.Size, HUDText.FontWeight, HUDText.Antialias, HUDText.Italic, HUDText.FontInternalName)
	end
	hook.Add("Initialize", "InitScreenDims", InitScreenDims)

elseif SERVER then
	hook.Add( "PlayerSpawn", "BuddyFinderSpawnGiver", function( ply )
		timer.Simple( .5, function()
			if ( IsValid( ply ) and ply:Alive() ) then	
				ply:Give("util_buddyfinder")	
			end	
		end )
	end )

	resource.AddWorkshop( "534923023" )
	bf_debug_mode = false

	function GetBuddyFinder(	ply	)
		if ( ply != nil	) and ply:HasWeapon( "util_buddyfinder" ) then
			return ply:GetWeapon( "util_buddyfinder" )
		end
	end

	function CCDial(	ply, cmd, args)
		--ply will be the initiator
		--cmd will be bf_dial
		--args will be targetUID and requesting boolean
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:StartBuddyCall(args[1])
		end
	end
	concommand.Add("bf_dial", CCDial)

	function CCAck(	ply, cmd, args)
		--ply will be the recipient
		--cmd will be bf_ack
		--no args
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:AckBuddyFinder()
		end
	end
	concommand.Add("bf_ack", CCAck)

	function CCAnswer(	ply, cmd, args)
		--ply will be the recipient
		--cmd will be bf_answer
		--args 1 will be true or false
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:AnswerBuddyFinder(args[1])
		end
	end
	concommand.Add("bf_answer", CCAnswer)

	function CCTeleportLoc(	ply, cmd, args)
		if (args[4] != nil) then
			ply = ents.GetByIndex(args[4])
		end
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:SetTeleportLocation(args[1], args[2], args[3])
		end
	end
	concommand.Add("bf_settloc", CCTeleportLoc)

	function CCTestNotifier(	ply, cmd, args)
		umsg.Start("buddy_finder_hud_notify", ply	)
			umsg.Bool(args[1] == "true")
			umsg.String(args[2])
		umsg.End()
	end

	function CreateDebugBuddy(	ply	)
		BuddyFinder_DebugBuddy = ents.Create('v92_bfinder_buddy')
		BuddyFinder_DebugBuddy:SetOwner(	ply	)
		if (	ply != nil) then
			local trace = ply:GetEyeTrace()
			BuddyFinder_DebugBuddy:SetPos(trace.HitPos)
		else
			BuddyFinder_DebugBuddy:SetPos(Vector(0, 0, 0))
		end
		BuddyFinder_DebugBuddy:Spawn()
		BuddyFinder_DebugBuddy:Activate()
	end

	function DestroyDebugBuddy()
		BuddyFinder_DebugBuddy:Remove()
	end

	function CCResetUnit(	ply, cmd, args)
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:Remove()
			ply:Give( "util_buddyfinder" )
		end	
	end

	function CCToggleDebug(	ply, cmd, args)
		if bf_debug_mode then
			concommand.Remove("bf_test_notify")
			concommand.Remove("bf_reset_unit")
			bf_debug_mode = false
			if BuddyFinder_DebugBuddy:IsValid() then DestroyDebugBuddy() end
		else
			concommand.Add("bf_test_notify", CCTestNotifier)
			concommand.Add("bf_reset_unit", CCResetUnit)
			bf_debug_mode = true
			CreateDebugBuddy(	ply	)
		end
	end
	concommand.Add("bf_toggle_debug", CCToggleDebug)

	function CCPrivateMessage(	ply, cmd, args)
		local recvBuddy = GetBuddyFinder(	ply	)
		if (recvBuddy != nil) then
			recvBuddy:SendPM(args[1], args[2])
		end
	end
	concommand.Add("bf_pm", CCPrivateMessage)

end
