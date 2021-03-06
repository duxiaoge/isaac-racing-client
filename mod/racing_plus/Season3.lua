local Season3 = {}

-- Includes
local g = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Schoolbag = require("racing_plus/schoolbag")

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season3:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 3) challenge.")

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items, depending on the character
  if character == PlayerType.PLAYER_ISAAC then -- 0
    Schoolbag:Put(CollectibleType.COLLECTIBLE_MOVING_BOX, 4) -- 523
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523
  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    Schoolbag:Put(CollectibleType.COLLECTIBLE_HOW_TO_JUMP, 0) -- 282
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_HOW_TO_JUMP) -- 282
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    -- We need to touch it to lock in the Bookworm touch
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, 0, false) -- 34
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, 3) -- 34
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL) -- 34
  elseif character == PlayerType.PLAYER_EVE then -- 5
    Schoolbag:Put(CollectibleType.COLLECTIBLE_CANDLE, 110) -- 164
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CANDLE) -- 164
  elseif character == PlayerType.PLAYER_SAMSON then -- 6
    Schoolbag:Put(CollectibleType.COLLECTIBLE_MR_ME, 4) -- 527
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MR_ME) -- 527
  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VENTRICLE_RAZOR, 0) -- 396
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VENTRICLE_RAZOR) -- 396
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    Schoolbag:Put(CollectibleType.COLLECTIBLE_GLASS_CANNON, 110) -- 352
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GLASS_CANNON) -- 352
  end
end

-- Replace Blue Baby and The Lamb with custom bosses
function Season3:PostNewRoom()
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomType = g.r:GetType()
  local roomClear = g.r:IsClear()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  if stage ~= 10 and stage ~= 11 then
    return
  end

  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  if roomClear then
    return
  end

  -- Don't do anything if we have somehow gone the wrong direction
  -- (via We Need to Go Deeper!, Undefined, etc.)
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end
  if stageType == 1 and direction == 2 then -- Cathedral or The Chest
    return
  end
  if stageType == 0 and direction == 1 then -- Sheol or Dark Room
    return
  end

  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if (
      stageType == 1 -- Cathedral
      and entity.Type == EntityType.ENTITY_ISAAC -- 273
    ) then
      entity:Remove()
    elseif (
      stageType == 0 -- Sheol
      and entity.Type == EntityType.ENTITY_SATAN -- 84
    ) then
      entity:Remove()
    elseif (
      stageType == 1 -- The Chest
      and entity.Type == EntityType.ENTITY_ISAAC -- 102
    ) then
      entity:Remove()
    elseif (
      stageType == 0 -- Dark Room
      and entity.Type == EntityType.ENTITY_THE_LAMB -- 273
    ) then
      entity:Remove()
    end
  end

  -- Spawn the replacement boss
  if stage == 10 then
    local jrFetusType = Isaac.GetEntityTypeByName("Dr Fetus Jr")
    Isaac.Spawn(jrFetusType, 0, 0, g.r:GetCenterPos(), g.zeroVector, nil)
    Isaac.DebugString("Spawned Jr. Fetus (for season 3).")
  elseif stage == 11 then
    local mahalathType = Isaac.GetEntityTypeByName("Mahalath")
    Isaac.Spawn(mahalathType, 0, 0, g.r:GetCenterPos(), g.zeroVector, nil)
    Isaac.DebugString("Spawned Mahalath (for season 3).")
  end
end

return Season3
