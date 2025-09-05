local _G = _G or getfenv(0)
local HealComm = AceLibrary("HealComm-1.0")
local AceEvent = AceLibrary("AceEvent-2.0")
local roster = AceLibrary("RosterLib-2.0")

local frames = {
	["player"] = PlayerFrameHealthBar,
	["target"] = TargetFrameHealthBar,
	["party1"] = PartyMemberFrame1HealthBar,
	["party2"] = PartyMemberFrame2HealthBar,
	["party3"] = PartyMemberFrame3HealthBar,
	["party4"] = PartyMemberFrame4HealthBar,
}

local function onHeal(unit, frameID)
	local frame = frameID or frames[unit]
	local healed = HealComm:getHeal(UnitName(unit))
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

	if ( healed > 0 and frame:IsShown() ) then
		health = health + healed
		if health > maxHealth then
			health = maxHealth
		end
		local healthWidth = frame:GetWidth() * (health / maxHealth)
		frame.incHeal:SetWidth(healthWidth)
		frame.incHeal:Show()
	else
		frame.incHeal:Hide()
	end
end

local function onEvent(unitname)
	if UnitName("target") == unitname then
		onHeal("target")
	end
	local unitobj = roster:GetUnitObjectFromName(unitname)
	if not unitobj or not unitobj.unitid then
		return
	end
	if UnitIsUnit("player", unitobj.unitid) then
		onHeal("player")
	else
		for i=1, 4 do
			if UnitIsUnit("party"..i, unitobj.unitid) then
				onHeal("party"..i)
			end
		end
	end
	if UnitInRaid("player") then
		local header = GROUP.." "..unitobj.subgroup
		local classheader = UnitClass(unitobj.unitid)
		local frame, unitframe
		for i=1, NUM_RAID_PULLOUT_FRAMES do
			frame = _G["RaidPullout"..i.."Name"]
			if frame:GetText() == header or frame:GetText() == classheader then
				frame = _G["RaidPullout"..i]
				for z=1, frame.numPulloutButtons do
					unitframe = _G[frame:GetName().."Button"..z]
					if unitframe.unit == unitobj.unitid then
						onHeal(unitobj.unitid, _G[unitframe:GetName().."HealthBar"])
					end
				end
			end
		end
	end
end

local function TargetChanged()
	onHeal("target")
end

AceEvent:RegisterEvent("HealComm_Healupdate", onEvent)
AceEvent:RegisterEvent("PLAYER_TARGET_CHANGED", TargetChanged)
AceEvent:RegisterEvent("UNIT_HEALTH", function()
	if frames[arg1] then
		onHeal(arg1)
	end
end)

local old_RaidPullout_Update = RaidPullout_Update
function RaidPullout_Update(pullOutFrame)
	old_RaidPullout_Update(pullOutFrame)
	if ( not pullOutFrame ) then
		pullOutFrame = this
	end
	local healthBar
	for i=1, pullOutFrame.numPulloutButtons do
		healthBar = _G[pullOutFrame:GetName().."Button"..i.."HealthBar"]
		if not healthBar.incheal then
			healthBar.incHeal = CreateFrame("StatusBar", pullOutFrame:GetName().."Button"..i.."IncHealBar", healthBar)
			healthBar.incHeal:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			healthBar.incHeal:SetMinMaxValues(0, 1)
			healthBar.incHeal:SetValue(1)
			healthBar.incHeal:SetStatusBarColor(0, 1, 0, 0.6)
			healthBar.incHeal:SetPoint("TOPLEFT", healthBar)
			healthBar.incHeal:SetHeight(healthBar:GetHeight())
			healthBar.incHeal:SetFrameLevel(healthBar:GetFrameLevel() - 1)
		end
	end
end

for unit, healthBar in pairs(frames) do
	local parent = healthBar:GetParent()
	healthBar.incHeal = CreateFrame("StatusBar", parent:GetName().."IncHealBar", parent)
	healthBar.incHeal:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	healthBar.incHeal:SetMinMaxValues(0, 1)
	healthBar.incHeal:SetValue(1)
	healthBar.incHeal:SetStatusBarColor(0, 1, 0, 0.5)
	healthBar.incHeal:SetPoint("TOPLEFT", healthBar)
	healthBar.incHeal:SetHeight(healthBar:GetHeight())
	healthBar.incHeal:SetFrameLevel(healthBar:GetFrameLevel() - 1)
end
