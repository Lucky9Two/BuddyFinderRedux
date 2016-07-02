--BuddyFinder Addon shared laserbox entity code
--Author: ancientevil
--Contact: facepunch.com
--Date: 29th May 2009
--Purpose: Draws a laser dimension box for buddyfinder

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity" 

--we are a 32x32x72 box
--human player hull + 1 padding
--with origin at 0,0,0
ENT.MinExt = Vector(-16.5, -16.5, 0)
ENT.MaxExt = Vector(16.5, 16.5, 73)

if CLIENT then

	local Laser = Material( "cable/redlaser" )

	--laser draw help
	function ENT:DrawLaser(fromVec, toVec)
		render.DrawBeam(fromVec, toVec, 5, 0, 0, Color( 255, 255, 255, 255 ) )
	end

	--draw the laser placement box
	function ENT:Draw() 
		local LowTopLeft, HiBottomRight = self.Entity:WorldSpaceAABB()
		local LowTopRight		= Vector(HiBottomRight.x, LowTopLeft.y, LowTopLeft.z)
		local LowBottomLeft	= Vector(LowTopLeft.x, HiBottomRight.y, LowTopLeft.z)
		local LowBottomRight = Vector(LowTopRight.x, HiBottomRight.y, LowTopRight.z)
		local HiTopLeft			= Vector(LowTopLeft.x, LowTopLeft.y, HiBottomRight.z)
		local HiTopRight		 = Vector(LowTopRight.x, HiTopLeft.y, HiTopLeft.z)
		local HiBottomLeft	 = Vector(HiTopLeft.x, LowBottomLeft.y, HiTopLeft.z)
		
		render.SetMaterial(Laser)

		--box
		
		--diags
		self:DrawLaser(LowTopLeft, HiBottomRight)
		self:DrawLaser(LowBottomRight, HiTopLeft)
		self:DrawLaser(LowTopRight, HiBottomLeft)
		self:DrawLaser(LowBottomLeft, HiTopRight)	

		--prism

		--lower pane
		self:DrawLaser(LowTopLeft, LowTopRight)
		self:DrawLaser(LowTopRight, LowBottomRight)
		self:DrawLaser(LowBottomRight, LowBottomLeft)
		self:DrawLaser(LowBottomLeft, LowTopLeft)
		--upper pane
		self:DrawLaser(HiTopLeft, HiTopRight)
		self:DrawLaser(HiTopRight, HiBottomRight)
		self:DrawLaser(HiBottomRight, HiBottomLeft)
		self:DrawLaser(HiBottomLeft, HiTopLeft)
		--side lines
		self:DrawLaser(HiTopLeft, LowTopLeft)
		self:DrawLaser(HiTopRight, LowTopRight)
		self:DrawLaser(HiBottomLeft, LowBottomLeft)
		self:DrawLaser(HiBottomRight, LowBottomRight)
		
	end

	--yes, this is translucent
	function ENT:IsTranslucent()
		return true
	end

end

if SERVER then

	--set up the basic details of the laser box
	function ENT:Initialize()
		Dbg('LaserBox ENT:Initialize()')
		local ply = self.Entity:GetOwner()
		self.Entity:SetSolid(SOLID_NONE)
		self.Entity:SetMoveType(MOVETYPE_NONE)
		self.Entity:PhysicsInitBox(self.MinExt, self.MaxExt)
		self.Entity:SetCollisionBounds(self.MinExt, self.MaxExt)
		self.Entity:DrawShadow(false)
		--if the owner is an NPC then we add a self-destruct timer that
		--will automatically allow us to teleport (for debugging with buddy)
		if (ply != nil) 
		and (ply != NULL)
		and (ply:IsNPC()) then
		self.NPCMode = true
		timer.Create("Self-destruct", 3, 1, function() self:Remove() end)
		else
		self.NPCMode = false
		end 
		Dbg('LaserBox ENT:Initialize()^')
	end

	--originally this code was in the cl_init.lua and was much smoother
	--but for now I have moved it to the server because I found that client
	--code is only executed when the player is in a set range
	function ENT:Think()
		local ply = self.Entity:GetOwner()
		if (ply == nil) or (ply == NULL) then
		return
		end
		--for an NPC, we stand 50 units diagonally from them
		if self.NPCMode then
		self.Entity:SetPos(ply:GetPos() + Vector(50, 50, 0))
		self.Entity:NextThink(CurTime() + 0.1)
		return
		else
		--this positions the laser box for the player
		local pos = ply:GetShootPos()
		local tracedata = {}
		tracedata.start = pos
		tracedata.endpos = pos + (ply:GetAimVector() * 300)
		tracedata.filter = {ply, self.Entity}
		local trace = util.TraceLine(tracedata)
		self.Entity:SetPos(trace.HitPos)
		self.Entity:NextThink(CurTime() + 0.1)
		end
	end

	--removing the laser box sends out teleport locations
	--if the sender has a buddy finder
	function ENT:OnRemove()
		Dbg('LaserBox ENT:OnRemove()')
		local pos = self.Entity:GetPos()
		local bf = GetBuddyFinder(self.Entity:GetOwner())
		bf:SetTeleportLocation(pos.x, pos.y, pos.z)
		Dbg('LaserBox ENT:OnRemove()^')
	end

end
