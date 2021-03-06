local Pills = {}

-- Includes
local g = require("racing_plus/globals")
local Season8 = require("racing_plus/season8")

function Pills:PostRender()
  -- This feature is disabled if the Single Player Co-op Babies mod is enabled
  -- (the pills text will overlap with the baby descriptions)
  if SinglePlayerCoopBabies ~= nil then
    return
  end

  -- This feature is disabled in season 7 speedruns
  -- (the pills text will overlap with the remaining goals)
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- Only show pill identification if the user is pressing tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if not tabPressed then
    return
  end

  -- Don't do anything if we have not taken any pills yet
  if #g.run.pills == 0 then
    return
  end

  local x = 80
  local baseY = 97
  for i = 9, 12 do -- Avoid overflow on the bottom if we identify a lot of pills
    if #g.run.pills >= i then
      baseY = baseY - 20
    end
  end
  local totalPillsInPool = 13
  if RacingPlusRebalancedVersion ~= nil then
    totalPillsInPool = 4
  end
  local string = (
    "Pills identified: " .. tostring(#g.run.pills) .. " / " .. tostring(totalPillsInPool)
  )
  g.font:DrawString(string, x - 10, baseY - 9 + 20, g.kcolor, 0, true)
  baseY = baseY + 20
  for i, pillEntry in ipairs(g.run.pills) do
    -- Show the pill sprite
    local y = baseY + (20 * i)
    local pos = Vector(x, y)
    pillEntry.sprite:RenderLayer(0, pos)

    -- Show the pill effect as text
    string = g.itemConfig:GetPillEffect(pillEntry.effect).Name
    if string == "Feels like I'm walking on sunshine!" then
      string = "Walking on sunshine!"
    end
    g.font:DrawString(string, x + 15, y - 9, g.kcolor, 0, true)
  end
end

function Pills:CheckPHD()
  if g.run.PHDPills then
    -- We have already converted bad pill effects this run
    return
  end

  -- Check for the PHD / Virgo
  if (
    not g.p:HasCollectible(CollectibleType.COLLECTIBLE_PHD) -- 75
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_VIRGO) -- 303
  ) then
    return
  end

  g.run.PHDPills = true
  Isaac.DebugString("Converting bad pill effects.")

  -- Change the text for any identified pills
  for _, pillEntry in ipairs(g.run.pills) do
    if pillEntry.effect == PillEffect.PILLEFFECT_BAD_TRIP then -- 1
      pillEntry.effect = PillEffect.PILLEFFECT_BALLS_OF_STEEL -- 2
    elseif pillEntry.effect == PillEffect.PILLEFFECT_HEALTH_DOWN then -- 6
      pillEntry.effect = PillEffect.PILLEFFECT_HEALTH_UP -- 7
    elseif pillEntry.effect == PillEffect.PILLEFFECT_RANGE_DOWN then -- 11
      pillEntry.effect = PillEffect.PILLEFFECT_RANGE_UP -- 12
    elseif pillEntry.effect == PillEffect.PILLEFFECT_SPEED_DOWN then -- 13
      pillEntry.effect = PillEffect.PILLEFFECT_SPEED_UP -- 14
    elseif pillEntry.effect == PillEffect.PILLEFFECT_TEARS_DOWN then -- 15
      pillEntry.effect = PillEffect.PILLEFFECT_TEARS_UP -- 16
    elseif pillEntry.effect == PillEffect.PILLEFFECT_LUCK_DOWN then -- 17
      pillEntry.effect = PillEffect.PILLEFFECT_LUCK_UP -- 18
    elseif pillEntry.effect == PillEffect.PILLEFFECT_PARALYSIS then -- 22
      pillEntry.effect = PillEffect.PILLEFFECT_PHEROMONES -- 24
    elseif pillEntry.effect == PillEffect.PILLEFFECT_WIZARD then -- 27
      pillEntry.effect = PillEffect.PILLEFFECT_POWER -- 36
    elseif pillEntry.effect == PillEffect.PILLEFFECT_ADDICTED then -- 29
      pillEntry.effect = PillEffect.PILLEFFECT_PERCS -- 28
    elseif pillEntry.effect == PillEffect.PILLEFFECT_RETRO_VISION then -- 37
      pillEntry.effect = PillEffect.PILLEFFECT_SEE_FOREVER -- 23
    elseif pillEntry.effect == PillEffect.PILLEFFECT_X_LAX then -- 39
      pillEntry.effect = PillEffect.PILLEFFECT_SOMETHINGS_WRONG -- 40
    elseif pillEntry.effect == PillEffect.PILLEFFECT_IM_EXCITED then -- 42
      pillEntry.effect = PillEffect.PILLEFFECT_IM_DROWSY -- 41
    end
  end

  Season8:PHD()
end

return Pills
