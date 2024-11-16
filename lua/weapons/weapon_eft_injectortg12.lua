if CLIENT then 
    SWEP.WepSelectIcon = surface.GetTextureID( "vgui/hud/vgui_TG12" )
	SWEP.BounceWeaponIcon = true 
    SWEP.DrawWeaponInfoBox = true
end

SWEP.PrintName = "xTG-12 Antidote"
SWEP.Author = "Craft_Pig"
SWEP.Purpose = 
[[
Treats Poison
Gives Wither -5HP over 60s
]]
SWEP.Category = "EFT"
SWEP.Category1 = "EFT"
SWEP.Category2 = "Stimulants"

SWEP.ViewModelFOV = 85
SWEP.ViewModel = "models/weapons/sweps/eft/injector/v_meds_injector.mdl"
SWEP.WorldModel = "models/weapons/sweps/eft/injector/w_meds_injector.mdl"
SWEP.UseHands = true
SWEP.DrawCrosshair = false 

SWEP.Spawnable = true
SWEP.Slot = 5
SWEP.SlotPos = 7
SWEP.DrawAmmo = true

SWEP.SwayScale = 0.15
SWEP.BobScale = 0.75

SWEP.Primary.Ammo = "tg12"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

SWEP.MaxHeal = 0

local INI_SEF = false
local ID_WEAPON = "weapon_eft_injectortg12"
local ID_PRIMARYAMMO = "tg12"

function SWEP:Initialize()
    self:SetHoldType("slam")
	
	local FilePathSEF = "lua/SEF/SEF_Functions.lua"
    if file.Exists(FilePathSEF, "GAME") then
        INI_SEF = true
    else
        INI_SEF = false
    end
end 

function SWEP:Deploy()
    local owner = self:GetOwner() 
	
	self.IniAnimBandage = 0
	self.AnimTimes = 0
	self.IniHeal = 0
	
	self:SendWeaponAnim(ACT_VM_IDLE)
	
	timer.Simple(0.05, function()
        if IsValid(self) and IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                vm:SetSkin(13) 
            end
        end
    end)
	
	if owner:GetAmmoCount(self.Primary.Ammo) == 0 then owner:StripWeapon(ID_WEAPON) end
	if GetConVar("cl_eftmeds_quick"):GetBool() then
		self:PrimaryAttack()
	end
	return true
end

function SWEP:Heal(owner)
	local owner = self:GetOwner() 
	
	if IsValid(self) then
		if IsValid(owner) and SERVER and owner:GetActiveWeapon():GetClass() == ID_WEAPON then -- Heal logic
			if INI_SEF == true then
				owner:ApplyEffect("Wither", 60, 1, 12)
				owner:RemoveEffect("Poison")
			end
			
			owner:RemoveAmmo(1, ID_PRIMARYAMMO)  
			
		end
	end
	
	if GetConVar("cl_eftmeds_quick"):GetBool() and SERVER then -- End
		timer.Simple(0.033, function()
			if owner:GetAmmoCount(ID_PRIMARYAMMO) == 0 then owner:StripWeapon(ID_WEAPON) end
			owner:SelectWeapon(owner:GetPreviousWeapon())
		end)
	else
		self:Deploy()
	end
end

function SWEP:PrimaryAttack()
    local owner = self.Owner

    if owner:GetAmmoCount(self.Primary.Ammo) == 0 then return end
	if self.IniAnimBandage == 1 or self.IniAnimSyringe == 1 or self.IniAnimPills == 1 then return end
	
	self:SendWeaponAnim(ACT_VM_RECOIL1)
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	self.IniAnimBandage = 1
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
	if self.IniAnimBandage == 1 and self.IdleTimer <= CurTime() then -- Bandage Sequence
		self.IniAnimBandage = 0
		self:Heal(owner)
	end
end

function SWEP:Holster()
	return true
end

function SWEP:PostDrawViewModel( vm )
    local attachment = vm:GetAttachment(1)
    if attachment then
        self.vmcamera = vm:GetAngles() - attachment.Ang
    else
        self.vmcamera = Angle(0, 0, 0) 
    end
end

function SWEP:CalcView( ply, pos, ang, fov )
	self.vmcamera = self.vmcamera or Angle(0, 0, 0)  
    return pos, ang + self.vmcamera, fov
end

if CLIENT then -- Worldmodel offset
	local WorldModel = ClientsideModel(SWEP.WorldModel)

	WorldModel:SetSkin(13)
	WorldModel:SetNoDraw(true)

	function SWEP:DrawWorldModel()
		local owner = self:GetOwner()

		if (IsValid(owner)) then
			local offsetVec = Vector(3, -1, 2)
			local offsetAng = Angle(-180, 0, 0)
			
			local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if !boneid then return end

			local matrix = owner:GetBoneMatrix(boneid)
			if !matrix then return end

			local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

			WorldModel:SetPos(newPos)
			WorldModel:SetAngles(newAng)

            WorldModel:SetupBones()
		else
			
			WorldModel:SetPos(self:GetPos())
			WorldModel:SetAngles(self:GetAngles())
			self:DrawModel()
		end

		WorldModel:DrawModel()

	end
end