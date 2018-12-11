--BuddyFinder Addon shared debug entity code
--Author: ancientevil
--Contact: facepunch.com
--Date: 6th June 2009
--Purpose: Buddy the test dummy

AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_gmodentity"

if SERVER then

	ENT.bnpc = nil

	function ENT:NPCHasWeapon(weaponname)
		if (weaponname == "util_buddyfinder") then
			return true
		else
			return false
		end
	end


	function ENT:NPCFire(input, param, delay)
		print('ping!')
		self.BaseClass:Fire(input, param, delay)
		if (input == "use") then
		self.Following = not self.Following
		if self.Following then
			self.NPC:SetSchedule(SCHED_INTERACTION_MOVE_TO_PARTNER) 
		else
			self.NPC:SetSchedule(SCHED_INTERACTION_WAIT_FOR_PARTNER) 
		end
		end
	end

	function ENT:NPCGetWeapon(weaponname)
		if (weaponname == "util_buddyfinder") then
		return self:GetActiveWeapon()
		end
	end

	/*---------------------------------------------------------
		 Name: Initialize
	---------------------------------------------------------*/
	function ENT:Initialize()
		self.Owner = self.Entity:GetOwner()

		--our crash test buddy
		self.bnpc = ents.Create('npc_barney')
		self.bnpc:SetOwner(self)
		self.bnpc:SetPos(self.Entity:GetPos())
		local Angles = self.Owner:GetAngles() 
			Angles.pitch = 0 
			Angles.roll = 0 
			Angles.yaw = Angles.yaw + 180 
		self.bnpc:SetAngles(Angles) 
		self.bnpc:SetKeyValue("spawnflags", SF_NPC_FADE_CORPSE || SF_NPC_ALWAYSTHINK )
		self.bnpc:CapabilitiesAdd(CAP_USE_WEAPONS)
		self.bnpc.HasWeapon = self.NPCHasWeapon
		self.bnpc.GetWeapon = self.NPCGetWeapon
		self.bnpc.Fire = self.NPCFire
		self.bnpc:Spawn()
		self.bnpc:Activate()
		self.bnpc:DropToFloor()
		self.bnpc:Give("util_buddyfinder")

		self.bnpc:GetActiveWeapon():SetOwner(self.bnpc)
	end

	function ENT:OnRemove()
		self.bnpc:Remove()
	end
end
