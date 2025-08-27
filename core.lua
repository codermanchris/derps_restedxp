-- constants
local TENT_JUICE_FULL = "TENT JUICE FULL!"
local FIND_TENT = "FIND A TENT!"
local PLAYER = "player"
local TENT_JUICE_EMPTY_SOUND = "igQuestFailed"
local TENT_JUICE_FULL_SOUND = "LEVELUPSOUND"
local AUDIO_CHANNEL = "master"
local GAIN_TEXT = "Tent Juice: %.1f%% | Gain Rate: %.1f%%"
local LOSS_TEXT = "Tent Juice: %.1f%% | Last Kill: %.1f%%"
local TJ_TEXT = "Tent Juice: %.1f%%"

-- local members
local addonFrame = nil
local isVisible = true
local updateTimer = 0
local lastValue = 0
local lastMaxXp = 0

-- local functions
local function CreateAddonFrame()
    -- create frame
    addonFrame = CreateFrame("Frame", "Derps Rested XP", UIParent)    
    addonFrame:SetHeight(50)
	addonFrame:SetWidth(300)
    addonFrame:SetPoint("CENTER", UIParent)

    -- setup background
    addonFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile = true, tileSize = 10, edgeSize = 10,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    addonFrame:SetBackdropColor(0, 0, 0, 0.8)

    -- Make it draggable
    addonFrame:SetMovable(true)
    addonFrame:EnableMouse(true)
    addonFrame:RegisterForDrag("LeftButton")
    
    -- text label
    local text = addonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("CENTER", addonFrame, "CENTER")
    text:SetTextColor(1, 1, 1, 1)
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetText(FIND_TENT)

    -- frame events
    addonFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    
    addonFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    addonFrame:SetScript("OnUpdate", function()
        local self = this
        local elapsed = arg1

        -- init updateTimer
        if not self.updateTimer then
            self.updateTimer = 0
        end

        -- update elapsed time
        self.updateTimer = self.updateTimer + elapsed

        -- if we're passed one second we want to do some stuff
        if self.updateTimer >= 1 then
            -- get character xp information
            local currentXp = UnitXP(PLAYER)
            local maxXp = UnitXPMax(PLAYER)
            local restedXp = GetXPExhaustion()

            -- if the character levels, we don't want a huge jump in last kill %
            if (maxXp ~= lastMaxXp and lastMaxXp ~= 0) then
                -- init or new level
                maxXp = lastMaxXp
            end
            lastMaxXp = maxXp

            -- if the character has no rested xp
            if (restedXp or -1) == -1 then
                -- if we have a value change update the ui
                if (lastValue ~= 0) then
                    lastValue = 0

                    -- notify the player by sound
                    PlaySound(TENT_JUICE_EMPTY_SOUND, AUDIO_CHANNEL)

                    -- set the text label 
                    text:SetText(FIND_TENT)

                    -- we want to show the UI if it's not shown when we hit 0 rested
                    if (not isVisible) then
                        isVisible = true
                        self:Show()
                    end
                end
            else -- the user has rested xp

                -- caluclate rested xp percent
                local value = 100 * restedXp / maxXp

                -- if we have a value change update the ui
                if (lastValue ~= value) then
                    -- figure out the difference to display gain/loss rate
                    local difference = value - lastValue
                    lastValue = value

                    -- if we're at capacity tell the user
                    if (value >= 150) then
                        -- inform the user that the tent juice is full
                        text:SetText(TENT_JUICE_FULL)

                        --notify the user by sound
                        PlaySound(TENT_JUICE_FULL_SOUND, AUDIO_CHANNEL)
                    else

                        -- if we notice a big enough change show the player, in either direction
                        if (difference > 0.09 and difference ~= value) then
                            text:SetText(string.format(GAIN_TEXT, value, difference))
                        elseif (difference < 0.09 and difference ~= value) then
                            text:SetText(string.format(LOSS_TEXT, value, difference))
                        else -- don't show gain/last kill text - just show %
                            text:SetText(string.format(TJ_TEXT, value))
                        end
                    end
                end
            end

            -- clear the timer for the next iteration
            self.updateTimer = 0
        end
    end)
end

-- event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

-- event handler
eventFrame:SetScript("OnEvent", function()
    -- the addon is loaded so lets do some things    
	if (event == "ADDON_LOADED") then     
        -- create the addon frame before loading config
        CreateAddonFrame()

        -- get stored frame position
        DerpsDB = DerpsDB or {}
        DerpsDB.FramePos = DerpsDB.FramePos or { x = addonFrame:GetLeft(), y = addonFrame:GetTop() }

        -- if we need to, move the frame into the right position
        if (DerpsDB.FramePos ~= nil) then
            addonFrame:ClearAllPoints()
            addonFrame:SetPoint("CENTER", UIParent, "CENTER", DerpsDB.FramePos.x, DerpsDB.FramePos.y)
        end

        -- unregister the addon_loaded event as we don't care about receiving any more of these types of events
		this:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        -- store the frame position information if we can
        if (DerpsDB ~= nil) then
            DerpsDB.FramePos = {
                x = addonFrame:GetLeft(), 
                y = addonFrame:GetTop()
            }
        end        
	end
end)

-- handle slash command
local function TJCommandHandler(msg, editBox)
    isVisible = not isVisible

    if (isVisible) then
        addonFrame:Show()
    else
        addonFrame:Hide()
    end
end

SLASH_TJ1 = "/tj"
SlashCmdList["TJ"] = TJCommandHandler