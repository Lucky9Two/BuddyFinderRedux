
AddCSLuaFile()

--	BuddyFinder Addon SWep code
--	Author: ancientevil
--	Contact: facepunch.com
--	Date: 29th May 2009
--	Purpose: The SWep - teleporting and funky business
--	Updated 2015-10-12 by V92

	
if (CLIENT) then
	local	_SELFENTNAME	= "util_buddyfinder"
	local	_INFONAME		= "Buddy Finder"
	SWEP.Category			= "92nd Dev Unit"
	SWEP.PrintName			= _INFONAME
	SWEP.Author   			= "V92/ancientevil"
	SWEP.Contact        	= "V92"
	SWEP.Purpose			= "Reduce commute time when looking for your friends on large maps.	Just call them with BuddyFinder and teleport to their location!"
	SWEP.Instructions		= "Fire to show contact list or answer incoming calls"
	SWEP.Slot 				= 5
	SWEP.SlotPos 			= 92
	SWEP.ViewModelFOV		= 70
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= false
	SWEP.BounceWeaponIcon	= false
	SWEP.WepSelectIcon 		= surface.GetTextureID("vgui/hud/" .. _SELFENTNAME )

	language.Add( _SELFENTNAME, _INFONAME )	
	killicon.Add( _SELFENTNAME, "vgui/entities/".. _SELFENTNAME , Color( 255, 255, 255 ) )
end

SWEP.Spawnable						= true
SWEP.AdminOnly						= false
SWEP.HoldType						= "slam"

SWEP.UseHands						= true
SWEP.ViewModel						= Model( "models/jessev92/weapons/buddyfinder_c.mdl" )
SWEP.WorldModel						= Model( "models/jessev92/weapons/buddyfinder_w.mdl" )

SWEP.Primary.Clipsize				= -1
SWEP.Primary.DefaultClip			= -1
SWEP.Primary.Automatic				= false
SWEP.Primary.Ammo					= "none"

SWEP.Secondary.Clipsize				= -1
SWEP.Secondary.DefaultClip			= -1
SWEP.Secondary.Automatic			= false
SWEP.Secondary.Ammo					= "none"

SWEP.BuddyRingTime					= 30
SWEP.NPCAnswerDelay					= 3
SWEP.NPCAcceptCall					= true
SWEP.TargetVarName					= "buddy_finder_target"
SWEP.BuddyFinderBusyVarName			= "buddy_finder_busy"
SWEP.BuddyFinderIncomingCallVarName	= "buddy_finder_incoming"
SWEP.TeleportSound					= Sound("ambient/machines/teleport3.wav")
SWEP.PreTeleportSound				= Sound("ambient/levels/labs/teleport_active_loop1.wav")
SWEP.PreTeleportSuckInSound			= Sound("ambient/levels/labs/teleportplyreblast_suckin1.wav")
SWEP.ContactsAppearSound			= Sound("npc/scanner/combat_scan5.wav")
SWEP.MenuButtonSound				= Sound("ui/buttonclick.wav")
SWEP.QueryAppearSound				= Sound("npc/dog/dogplylayfull3.wav")
SWEP.PMSound						= Sound("npc/scanner/scanner_scan4.wav")

BuddyFinderAnim						= {}
BuddyFinderAnim.DrawVM				= ACT_VM_DRAW
BuddyFinderAnim.Holster				= ACT_VM_HOLSTER
BuddyFinderAnim.Idle				= ACT_VM_IDLE
BuddyFinderAnim.DialIn				= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.DialOut				= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.AcceptIn			= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.AcceptOut			= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.DenyIn				= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.DenyOut				= ACT_VM_PRIMARYATTACK
BuddyFinderAnim.LaserBoxIn			= ACT_VM_PRIMARYATTACK_6
BuddyFinderAnim.LaserBoxIdle		= ACT_VM_PRIMARYATTACK_7
BuddyFinderAnim.LaserBoxOut			= ACT_VM_PRIMARYATTACK_8

--table of all possible outcomes from calling another buddyfinder
BuddyCallInfo						= {}
BuddyCallInfo.bciBusy				= {HUDNotify = "bfhnBusy", NextAction = "FinishCall"} --target is on another call
BuddyCallInfo.bciAccepted			= {HUDNotify = "bfhnAccepted", NextAction = "Warmup"} --target has allowed a teleport request or accepted a teleport offer
BuddyCallInfo.bciDenied				= {HUDNotify = "bfhnDenied", NextAction = "FinishCall"} --target had denied a teleport request or refused a teleport offer
BuddyCallInfo.bciTeleport			= {NextAction = "Teleport"} --teleport is go go go
BuddyCallInfo.bciOutgoing			= {HUDNotify = "bfhnOutgoing"}
BuddyCallInfo.bciSilentCancel		= {NextAction = "SilentCancel"}
BuddyCallInfo.bciIncoming			= {HUDNotify = "bfhnIncoming"} 

--console commands
BuddyFinderCC						= {}
BuddyFinderCC.Dial					= "bf_dial"
BuddyFinderCC.Ack					= "bf_ack"
BuddyFinderCC.Answer				= "bf_answer"
BuddyFinderCC.SetTLoc				= "bf_settloc"
BuddyFinderCC.PM					= "bf_pm"

BF_Umsg								= {}
BF_Umsg.ConnectCall					= "ConnectBuddyCall"

function SWEP:Initialize()
	self:SetWeaponHoldType("slam")
end

function SWEP:Holster()
	self:SendWeaponAnim( ACT_VM_HOLSTER )
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:SecondaryAttack()
	--reverse use - offer a player to come to you instead
	--1. animation
	--2. if placing a call,vgui player list popup
	--3. if receiving a call, dialog popup
	return false
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	return true
end

if CLIENT then

	SWEP.TargetList = {}

	SWEP.SoundObjects = {}

	--emit a sound when a button is pressed
	function SWEP:PressButton()
		self:EmitSound(self.MenuButtonSound)
	end

	--emit a sound when receiving or sending a PM
	function SWEP:MakePMSound()
		self:EmitSound(self.PMSound)
	end

	--incoming call dialog
	function SWEP:ShowIncomingCallDialog()
		local fromPlayerNick = self:GetNWString("caller_name")
		local frSimple = vgui.Create("DFrame")
		frSimple:SetSize(400, 100)
		frSimple:Center()
		frSimple:SetTitle("Buddy Finder - Incoming Call")
		frSimple:ShowCloseButton(false)
		function frSimple:Paint()
		draw.RoundedBox(8, 0, 0, self:GetWide(), self:GetTall(), Color(100, 100, 100, 200))
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawLine(0, 25, self:GetWide(), 25)
		end

		local lblQuestion = vgui.Create("DLabel", frSimple)
		lblQuestion:SetPos(30, 30)
		lblQuestion:SetText("Do you wish to allow "..fromPlayerNick.." to teleport to your location?")
		lblQuestion:SizeToContents()
		lblQuestion:Center()

		local btnAllow = vgui.Create("DButton", frSimple)
		btnAllow:SetText("Yes")
		btnAllow:SetPos(250, 68)
		btnAllow.DoClick = function()
		LocalPlayer():ConCommand(BuddyFinderCC.Answer.." ".."true")
		frSimple:Remove()
		end

		local btnDeny = vgui.Create("DButton", frSimple)
		btnDeny:SetText("No")
		btnDeny:SetPos(323, 68)
		btnDeny.DoClick = function()
		LocalPlayer():ConCommand(BuddyFinderCC.Answer.." ".."false")
		frSimple:Remove()
		end

		frSimple:MakePopup()
		self:EmitSound(self.QueryAppearSound)
	end

	--we have received a usermessage from the server
	--detailing our contact list - process it then
	--show the list dialog
	function SWEP:PopulateThenShowList(um)
		table.Empty(self.TargetList)
		local plyCount = um:ReadShort()
		for k = 1, plyCount do
		local targetName = um:ReadString()
		local targetID = um:ReadString()
		self.TargetList[targetName] = targetID
		end
		self:ShowPhonePlayerList()
	end

	--returns first value in selected lines and column
	function SWEP:GetSelectedColValue(listview, columnid)
		return listview:GetSelected()[1]:GetValue(columnid)
	end

	--start playing the warmup noise
	function SWEP:DoTeleportWarmup()
		if (self.SoundObjects.PreTeleport == nil) then
		self.SoundObjects.PreTeleport = CreateSound(LocalPlayer(), Sound(self.PreTeleportSound))
		end
		self.SoundObjects.PreTeleport:Play()	
	end

	--gradual reduction of the teleport effect
	function TeleportGlowEffect()
		DrawBloom( 0, ((LocalPlayer():GetNWInt("GlowEndTime") - CurTime())/ 5) * 0.75, 3, 3, 2, 3, 255, 255, 255 )
	end

	--the eye-blasting teleport effect
	function SWEP:TeleportGlow(activate)
		if (activate) then
		LocalPlayer():SetNWInt("GlowEndTime", CurTime() + 4)
		hook.Add("RenderScreenspaceEffects", "TeleportGlowEffect", TeleportGlowEffect)
		timer.Simple(4, function() self:TeleportGlow(false) end)
		else
		hook.Remove("RenderScreenspaceEffects", "TeleportGlowEffect")
		end
	end

	--stop the warmup noise and start the self-managing eye blast
	function SWEP:DoPreTeleport()
		self:TeleportGlow(true)
		self.SoundObjects.PreTeleport:Stop()	
	end

	--not yet used, but required to be here
	function SWEP:DoPostTeleport()
		
	end

	--the server says we have finished the call - make sure all sounds
	--have stopped playing
	function SWEP:DoFinishCall()
		--stop all sounds if they are still playing
		for k,v in pairs(self.SoundObjects) do
		v:Stop()
		end
	end

	--the private message quick message box/send
	function SWEP:SendPrivateMessage(playerName, playerSteamId)

		local frPM = vgui.Create("DFrame")
		frPM:SetSize(300, 100)
		frPM:SetTitle("Send Text Message to "..playerName)
		frPM:Center()

		local teMsg = vgui.Create("DTextEntry", frPM)
		teMsg:SetSize(240, 30)
		teMsg:Center()
		teMsg:AllowInput(true)

		local btnSend = vgui.Create("DButton", frPM)
		btnSend:SetPos(206, 70)
		btnSend:SetText("Send")

		local function SendPMToServer()
		local txtSend = teMsg:GetValue()
		if (txtSend != '') then		
			LocalPlayer():ConCommand(BuddyFinderCC.PM.." "..playerSteamId.."\""..txtSend.."\"")
			self:MakePMSound()
			frPM:Remove()
		end
		end

		teMsg.OnEnter = function() SendPMToServer() end
		btnSend.DoClick = function() SendPMToServer() end

		frPM:MakePopup()
		teMsg:RequestFocus()
		frPM:DoModal()
	end

	--the contact list menu
	function SWEP:ShowPhonePlayerList(requestingTeleport)
		local frDirectory = vgui.Create("DFrame")
		frDirectory:SetSize(500, 500)
		frDirectory:SetTitle("Buddy Finder - Contacts")
		frDirectory:Center()

		function frDirectory:Paint()
		draw.RoundedBox(8, 0, 0, self:GetWide(), self:GetTall(), Color(100, 100, 100, 200))
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawLine(0, 25, self:GetWide(), 25)
		end

		local lvTargets = vgui.Create("DListView", frDirectory)
		lvTargets:SetPos(30, 30)
		lvTargets:SetSize(440, 420)
		local colName = lvTargets:AddColumn("Name")
		local colSteamId = lvTargets:AddColumn("SteamID")
		local targetCount = 0
		for k,v in pairs(self.TargetList) do
		lvTargets:AddLine(k, v)
		targetCount = targetCount + 1
		end

		local btnDial = vgui.Create("DButton", frDirectory)
		btnDial:SetPos(406, 460)
		btnDial:SetText("Dial")
		btnDial.DoClick = function()
		if (targetCount > 0) then
			LocalPlayer():ConCommand(BuddyFinderCC.Dial.." "..self:GetSelectedColValue(lvTargets, colSteamId:GetColumnID()))
			frDirectory:Remove()
		else
			Dbg('No players to call')
		end
		end

		local btnPM = vgui.Create("DButton", frDirectory)
		btnPM:SetPos(30, 460)
		btnPM:SetText("P.M.")
		btnPM.DoClick = function()
		if (targetCount > 0) then
			self:PressButton()
			self:SendPrivateMessage(self:GetSelectedColValue(lvTargets, colName:GetColumnID()),
									self:GetSelectedColValue(lvTargets, colSteamId:GetColumnID()))
			frDirectory:Remove()
		else
			Dbg('No players to PM')
		end
		end

		lvTargets.OnRowSelected = function(selectedRow)
		btnDial:SetDisabled(selectedRow == nil)
		end

		lvTargets.DoDoubleClick = function()
		btnDial.DoClick()
		end

		lvTargets:SelectFirstItem()
		frDirectory:MakePopup()
		self:EmitSound(self.ContactsAppearSound)
	end

	--mute the click sound of primary attack
	function SWEP:PrimaryAttack()
		--mutes the click sound
	end


end

if SERVER then

	SWEP.Weight =	0
	SWEP.AutoSwichTo =	false
	SWEP.AutoSwichFrom =	false

	--if the owner is an NPC then we call an alternate routine as
	--the NPC doesn't have a clientside
	function SWEP:SafeCallOnClient(routine, params)
		if (self:GetOwner() == NULL) then
		return	
		elseif (self:GetOwner():IsNPC()) then
		self:NPCCallOnClient(routine, params)
		else
		self:CallOnClient(routine, params)
		end
	end

	--the first thing we do is tidy up - just in case
	function SWEP:Initialize()
		self:FinishCall()
	end

	--returns true if this BuddyFinder is busy
	--can also set this property
	function SWEP:BuddyFinderBusy(isBusy)
		if (isBusy == nil) then
		return self:GetNWBool(self.BuddyFinderBusyVarName)
		else
		self:SetNWBool(self.BuddyFinderBusyVarName, isBusy)
		end
	end

	--I am unsure as to whether this is working properly or not
	--but this should fade the tunnels out
	function SWEP:FadeFunc(tunnel)
		local fadeval = tunnel:GetKeyValues().renderamt
		if (fadeval == nil) then
		fadeval = 255
		end
		tunnel:SetKeyValue("rendermode", RENDERMODE_TRANSTEXTURE)
		tunnel:SetKeyValue("renderamt", tostring(fadeval - 25))
	end

	--after a few seconds, the tunnels remove themselves
	function SWEP:DelayedTunnelRemove(tunnel)
		timer.Create("FadeOut", 0.25, 10, function() self:FadeFunc(tunnel) end)
		timer.Simple(4, function() tunnel:Remove() end)
	end

	--creates/plays and automatically cleans up... the tunnel effects
	function SWEP:TunnelEffect(	ply	)
		local tunnel = ents.Create('prop_dynamic')
		//tunnel:SetModel('models/props_combine/stasisvortex.mdl')
		tunnel:SetModel('models/effects/vol_light128x128.mdl')
		--tunnel:SetPos(	ply:GetPos() + tunnel:BoundingRadius() * Vector(0, 0, 1))
		tunnel:SetPos(	ply:GetPos() + tunnel:BoundingRadius() * Vector(0, 0, 128))
		tunnel:SetOwner(	ply	)
		tunnel:DrawShadow(false)
		tunnel:Spawn()
		ply:EmitSound(self.TeleportSound)
		self:DelayedTunnelRemove(tunnel)
	end

	--jump to the destination, triggering handlers as we go
	function SWEP:DoTeleport(destination)
		local ply = self:GetOwner()
		self:DoPreTeleport()
		ply:SetVelocity(Vector(0, 0, 0))
		ply:SetLocalVelocity(Vector(0, 0, 0))
		ply:ViewPunch(Angle(-5,0,0)) --Vector(-5, 0, 0))
		ply:SetPos(destination)
		self:DoPostTeleport()
	end

	--tell the clientside to start pre-teleport sound and video effects
	--this also spawns a self-managing tunnel effect
	function SWEP:DoPreTeleport()
		local ply = self:GetOwner()
		self:TunnelEffect(	ply	)
		self:SafeCallOnClient("DoPreTeleport", "")
	end

	--tell the clientside to start post-teleport sound and video effects
	--this also spawns a self-managing tunnel effect
	function SWEP:DoPostTeleport()
		local ply = self:GetOwner()
		self:TunnelEffect(	ply	)
		self:SafeCallOnClient("DoPostTeleport", "")
		self:BuddyFinderBusy(false)
	end

	--tell the clientside to start warmup sound and video effects
	function SWEP:DoTeleportWarmup()
		self:SafeCallOnClient("DoTeleportWarmup", "")
	end

	--send the "rang out" message back to the player calling
	function SWEP:BuddyRangOut()
		self:NotifyIncomingCallHUD(false)
		self:SendBuddyCallInfo(BuddyCallInfo.bciBusy, self.Caller)
		self:FinishCall()
	end

	--enable or disable the incoming call blinking HUD icon
	function SWEP:NotifyIncomingCallHUD(enable)
		self:SendHUDNotification(enable, BuddyCallInfo.bciIncoming)
	end

	--spawn the laser box and allow it to be moved about by the 
	--direction the user is facing
	function SWEP:StartSelectPoint()
		self:BuddyAnim(BuddyFinderAnim.LaserBoxIdle, false)
		if (self.LaserBox == nil) then
		self.LaserBox = ents.Create("v92_bfinder_tpg")
		if !self.LaserBox:IsValid() then
			print('LaserBox IS NOT VALID!')
		end
		self.LaserBox:SetOwner(self:GetOwner())
		self.LaserBox:DrawShadow(false)
		self.LaserBox:SetPos(self:GetOwner():GetPos())
		self.LaserBox:Spawn()
		Dbg('LaserBox spawned')
		end
	end

	--return true if the buddy finder is on a call
	function SWEP:HasIncomingCall()
		return (self.Caller != nil)
	end

	--tie up all loose ends
	function SWEP:FinishCall()
		self:SafeCallOnClient("DoFinishCall", "")
		--terminate the call on the caller's end too
		if (self.Caller != nil) then
		self:SendBuddyCallInfo(BuddyCallInfo.bciSilentCancel, self.Caller)
		end
		self.Caller = nil
		self:BuddyFinderBusy(false)	
	end

	--set the buddyfinder animation, if a button was pressed then make a sound
	--also able to specify a routine to call when done - if none specified then
	--the swep returns to the idle animation
	function SWEP:BuddyAnim(anim, pressedButton, callWhenDone)
		Dbg('Animating: '..tostring(anim))
		if pressedButton then
		self:SafeCallOnClient("PressButton", "")
		end
		self:SendWeaponAnim(anim)
		if (callWhenDone != nil) then
		timer.Simple(self:SequenceDuration(), function() callWhenDone() end)
		elseif (anim != BuddyFinderAnim.LaserBoxIdle) then
		timer.Simple(self:SequenceDuration(), function() self:AnimReturnToIdle() end)
		end	
	end

	function SWEP:NPCCallOnClient(routine, params)
		--if we need to handle client style routines for the NPC
		--we do it here (not yet needed)
	end

	--revert buddyfinder animation to idle
	function SWEP:AnimReturnToIdle()
		self:SendWeaponAnim(BuddyFinderAnim.Idle)
	end

	--after the animation is played, the answer is sent to the callee
	function SWEP:DelayedAnswer(accepted)
		if accepted then
		--play the new laser placement out action	 
		self:SendBuddyCallInfo(BuddyCallInfo.bciAccepted, self.Caller)
		self:BuddyAnim(BuddyFinderAnim.LaserBoxIn, false, function() self:StartSelectPoint() end)
		else
		--play the deny out action
		self:BuddyAnim(BuddyFinderAnim.DenyOut, true)
		self:SendBuddyCallInfo(BuddyCallInfo.bciDenied, self.Caller)
		self:FinishCall()
		end
	end

	--called once we have decided whether to accept or deny the caller
	function SWEP:AnswerBuddyFinder(accepted)
		if accepted == "true" then
		--play the accept action
		self:BuddyAnim(BuddyFinderAnim.AcceptIn, false, function() self:DelayedAnswer(true) end)
		else
		--play the deny action
		self:BuddyAnim(BuddyFinderAnim.DenyIn, false, function() self:DelayedAnswer(false) end)
		end
	end

	--called when the NPC answers the buddyfinder
	function SWEP:NPCAnswer()
		self:DelayedAnswer(self.NPCAcceptCall)
		self.NPCAcceptCall = not self.NPCAcceptCall --toggle	
	end

	--send a pm to another player
	function SWEP:SendPM(toSteamId, msg)
		local recvBuddy = GetBuddyFinder(player.GetByUniqueID(toSteamId))
		if (recvBuddy != nil) then
		recvBuddy:PrintPM(self:GetOwner(), msg)
		end
	end

	--a private message has been received so we print it in the
	--chat area immediately
	function SWEP:PrintPM(fromply, msg)
		self:GetOwner():PrintMessage(HUD_PRINTTALK, fromply:Nick().."{PM}: "..msg)
		self:SafeCallOnClient("MakePMSound", "")
	end

	--sends a HUD notification to the client screen
	function SWEP:SendHUDNotification(start, notification)
		if (self:GetOwner() == NULL) or (self:GetOwner():IsNPC()) then
		return
		end
		umsg.Start("buddy_finder_hud_notify", self:GetOwner())
		umsg.Bool(start)
		if (start) then
		umsg.String(notification.HUDNotify)
		end
		umsg.End()
	end

	--feedback, sent from the buddyfinder we are calling
	function SWEP:ReceiveBuddyCallInfo(callInfo, teleportVector)
		Dbg(tostring(self:GetOwner())..' received call info '..tostring(callInfo))
		--if at this point the ringing timer is still going, stop it
		timer.Stop("BuddyRinging")
		local hudnotify = callInfo.HUDNotify
		--if this call info requires a hud notification then 
		--send a message to the client to do so
		if (hudnotify != nil) then
		self:SendHUDNotification(true, callInfo)
		end
		local nextAction = callInfo.NextAction
		--if this call requires an action to be taken other than
		--finishing up everything then we do it here
		if (nextAction != nil) then
		if (nextAction == "Warmup") then
			self:DoTeleportWarmup()
		elseif (nextAction == "Teleport") then
			self:DoTeleport(teleportVector)
		else
			self:FinishCall() --the silent cancel will trigger this
		end
		end
	end

	--the final piece of the puzzle, provided by the laser box
	function SWEP:SetTeleportLocation(tox, toy, toz)
		self:SendBuddyCallInfo(BuddyCallInfo.bciTeleport, self.Caller, Vector(tox, toy, toz))
		self.LaserBox = nil
		self:FinishCall()
	end

	--returns true if the owner of this weapon is an NPC
	function SWEP:NPCMode()
		local theowner = self:GetOwner()
		return (theowner != nil) and (theowner != NULL) and (theowner:IsNPC())
	end

	--a call is incoming - received here
	function SWEP:ReceiveBuddyCall(	ply	)
		Dbg('Receiving a call from '..tostring(	ply))
		if self:BuddyFinderBusy() then
		self:SendBuddyCallInfo(BuddyCallInfo.bciBusy, ply	)
		Dbg('Sent busy tone')
		else
		Dbg('Ringing')
		self:BuddyFinderBusy(true)
		self.Caller = ply
		self:SetNWString("caller_name", ply:Nick())
		self:NotifyIncomingCallHUD(true)
		timer.Create("BuddyRinging", self.BuddyRingTime, 1, function() self:BuddyRangOut() end)
		if self:NPCMode() then
			timer.Create("NPCAnswer", self.NPCAnswerDelay, 1, function() self:NPCAnswer() end)
		end
		end
	end

	--send information about the call to the caller
	function SWEP:SendBuddyCallInfo(callInfo, toCaller, tableInfo)
		local callerBuddy = GetBuddyFinder(toCaller)
		if (callerBuddy != nil) then
		callerBuddy:ReceiveBuddyCallInfo(callInfo, tableInfo)
		return true
		else
		return false
		end
	end

	--after the animation, continue placing the call
	function SWEP:DelayedMakeBuddyCall(toBuddy)
		self:BuddyAnim(BuddyFinderAnim.DialOut, true)
		if (toBuddy != nil) then	
		self:SendHUDNotification(true, BuddyCallInfo.bciOutgoing)
		toBuddy:ReceiveBuddyCall(self:GetOwner())
		else
		self:BuddyFinderBusy(false)
		end
	end

	--start the process of calling another buddy finder
	function SWEP:StartBuddyCall(toPlayerSteamID)
		if self:BuddyFinderBusy() then
		Dbg('Cant make call - unit is busy')
		return
		end
		self:BuddyFinderBusy(true)
		local toply = self:GetOwner()
		if (string.Left(toPlayerSteamID, 3) == 'NPC') then
		toply = ents.GetByIndex(string.Right(toPlayerSteamID, string.len(toPlayerSteamID) - 3))
		elseif (toPlayerSteamID != "me") then
		toply = player.GetByUniqueID(toPlayerSteamID)
		end
		local toBuddy = GetBuddyFinder(toply)
		self:BuddyAnim(BuddyFinderAnim.DialIn, false, function() self:DelayedMakeBuddyCall(toBuddy) end)
	end

	function SWEP:RemoveInvalidPlayers(playerTbl)
		local validPlayers = {}	
		for k, v in pairs(playerTbl) do
			if ( v != self:GetOwner() )
				and v:HasWeapon( "util_buddyfinder" ) then
				table.insert(validPlayers, v )
			end
		end
		return validPlayers
	end

	--sends a usermessage with all player details
	function SWEP:PopulatePhonePlayerList()
		local allPlayers = table.Copy(player.GetAll())
		local npcs = ents.FindByClass('npc_*')	

		--if we are debugging then we also include 
		--all NPCs
		if bf_debug_mode then
		table.Merge(allPlayers, npcs)
		end

		--remove players without buddy finders
		--if not in debug mode, remove the local player and players without buddyfinders
		allPlayers = self:RemoveInvalidPlayers(allPlayers)
		
		umsg.Start("PopulatePhonePlayerList", self:GetOwner())
		umsg.Short(table.Count(allPlayers))
		for k, v in pairs(allPlayers) do
		if v:IsNPC() then
			umsg.String(v:GetClass())
			umsg.String('NPC'..v:EntIndex())
		else
			umsg.String(v:Nick())
			umsg.String(v:UniqueID())
		end
		end
		umsg.End()
	end

	--after the animation, acknowledge that we have picked up the phone
	function SWEP:DelayedPickup()
		self:SendHUDNotification(false) --turn off the ring
		self:SafeCallOnClient("ShowIncomingCallDialog", "")
		self:BuddyAnim(BuddyFinderAnim.DialOut, true)
	end

	--after the animation, populate the phone list and send it via umessage
	function SWEP:DelayedContacts()
		self:PopulatePhonePlayerList()
		self:BuddyAnim(BuddyFinderAnim.DialOut, true)
	end

	--once the animation is played, destroy the laser box which sends out the coords
	function SWEP:DoPlaceBox()
		self:BuddyAnim(BuddyFinderAnim.LaserBoxOut, true)
		self.LaserBox:Remove()
	end

	function SWEP:PrimaryAttack()
		--if we are in teleport point select mode then we work differently
		--animation pressing a button on the phone model
		if (self.LaserBox != nil) then
			--play the dial/pickup action
			Dbg('Attack: Teleport')
			self:DoPlaceBox()
		elseif self:HasIncomingCall() then
			--play the dial/pickup action
			Dbg('Attack: Answer')
			self:BuddyAnim(BuddyFinderAnim.DialIn, false, function() self:DelayedPickup() end)
		else
			--play the dial/pickup action
			Dbg('Attack: Dial')
			self:BuddyAnim(BuddyFinderAnim.DialIn, false, function() self:DelayedContacts() end) 
		end
	end

	--tidy up
	function SWEP:OnRemove()
		self:SendHUDNotification(false)
		self:FinishCall() 
		--should fix the aimpos spam
		if (self.LaserBox != nil) then
			self.LaserBox:Remove()
		end
	end

end
