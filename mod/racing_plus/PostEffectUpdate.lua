local PostEffectUpdate = {}

-- Note: Distance, SpawnerType, and SpawnerVariant are not initialized yet in this callback

-- Includes
local g          = require("racing_plus/globals")
local UseItem    = require("racing_plus/useitem")
local FastTravel = require("racing_plus/fasttravel")

-- EffectVariant.HEAVEN_LIGHT_DOOR (39)
function PostEffectUpdate:Effect39(effect)
  -- We cannot put this in the PostEffectInit callback because the position of the effect is not initialized yet
  FastTravel:ReplaceHeavenDoor(effect)
end

-- EffectVariant.DICE_FLOOR (76)
function PostEffectUpdate:Effect76(effect)
  -- We need to keep track of when the player uses a 5-pip Dice Room so that we can seed the floor appropriately
  if not g.run.diceRoomActivated and
     effect.SubType == 4 and -- 5-pip Dice Room
     g.p.Position:Distance(effect.Position) <= 75 then -- Determined through trial and error

    g.run.diceRoomActivated = true
    UseItem:Item127() -- Forget Me Now
  end
end

function PostEffectUpdate:Trapdoor(effect)
  FastTravel:CheckTrapdoorCrawlspaceOpen(effect)
  FastTravel:CheckTrapdoorEnter(effect, false) -- The second argument is "upwards"
end

function PostEffectUpdate:Crawlspace(effect)
  FastTravel:CheckTrapdoorCrawlspaceOpen(effect)
  FastTravel:CheckCrawlspaceEnter(effect)
end

function PostEffectUpdate:HeavenDoor(effect)
  FastTravel:CheckTrapdoorEnter(effect, true) -- The second argument is "upwards"
end

function PostEffectUpdate:TearPoof(effect)
  -- Change the green spash of Mysterious Liquid tears to blue
  -- (changing the color does not work in the PostEffectInit callback)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) then -- 13
    effect:SetColor(Color(1, 1, 20, 1, 0, 0, 0), 0, 0, false, false)
  end
end

function PostEffectUpdate:CrackTheSkyBase(effect)
  -- Local variables
  local data = effect:GetData()
  local sprite = effect:GetSprite()

  -- Spawn an actual Crack the Sky effect when the "Appear" animation is finished
  local spawnRealLight = false
  if sprite:IsFinished("DelayedAppear") then
    sprite:Play("Delayed", true)
    spawnRealLight = true
  end
  if spawnRealLight then
    g.run.spawningLight = true
    local light = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, -- 1000.19
                            data.CrackSkySpawnPosition, g.zeroVector,
                            data.CrackSkySpawnSpawner, 0, effect.InitSeed)
    g.run.spawningLight = false
    data.CrackSkyLinkedEffect = light

    -- Reduce the collision radius, which makes the hitbox in-line with the sprite
    light.Size = light.Size - 16
  end

  -- While the light exists, constantly set the base's position to the light
  if data.CrackSkyLinkedEffect and
     data.CrackSkyLinkedEffect:Exists() and
     (sprite:IsPlaying("Spotlight") or
      sprite:IsPlaying("Delayed")) then

    effect.Position = data.CrackSkyLinkedEffect.Position
    effect.Velocity = data.CrackSkyLinkedEffect.Velocity
  end

  -- Remove this once the animations are finished
  if sprite:IsFinished("Spotlight") or
     sprite:IsFinished("Delayed") then

    effect:Remove()
  end
end

return PostEffectUpdate