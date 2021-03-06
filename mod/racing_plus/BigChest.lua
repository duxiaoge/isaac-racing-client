local BigChest = {}

-- Includes
local g = require("racing_plus/globals")
local FastTravel = require("racing_plus/fasttravel")
local Speedrun = require("racing_plus/speedrun")
local Season7 = require("racing_plus/season7")
local Sprites = require("racing_plus/sprites")

BigChest.action = "leave"
BigChest.checkpointPos = g.zeroVector

function BigChest:PostPickupInit(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomType = g.r:GetType()
  local centerPos = g.r:GetCenterPos()
  local roomSeed = g.r:GetSpawnSeed()
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("Big Chest detected.")

  -- Since the chest's position is not initialized yet in this callback,
  -- manually set it to the center of the room for use in subsequent functions
  pickup.Position = g.r:GetCenterPos()

  -- By default, leave the big chest there
  BigChest.action = "leave"
  BigChest.checkpointPos = centerPos

  -- Determine if we should replace the big chest with something else
  if stage == 10 then
    if (
      stageType == 0 -- 10.0 (Sheol)
      and g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) -- 328
    ) then
      BigChest.action = "down"
    elseif (
      stageType == 1 -- 10.1 (Cathedral)
      and g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) -- 327
    ) then
      BigChest.action = "up"
    end
  end

  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    BigChest:S1R9(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    BigChest:S1R14(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    BigChest:S2(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    BigChest:SpeedrunAlternate(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    BigChest:SpeedrunUp(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    BigChest:SpeedrunUp(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    BigChest:SpeedrunAlternate(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    BigChest:S7(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 8)") then
    BigChest:SpeedrunUp(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)") then
    BigChest:SpeedrunUp(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    BigChest:SVanilla(pickup)
  elseif g.raceVars.finished then
    BigChest.action = "victoryLap"
  elseif g.race.rFormat == "pageant" then
    BigChest:Pageant(pickup)
  elseif g.race.goal == "Blue Baby" and g.raceVars.started then
    BigChest:BlueBaby(pickup)
  elseif g.race.goal == "The Lamb" and g.raceVars.started then
    BigChest:TheLamb(pickup)
  elseif g.race.goal == "Mega Satan" and g.raceVars.started then
    BigChest:MegaSatan(pickup)
  elseif g.race.goal == "Hush" and g.raceVars.started then
    BigChest:Hush(pickup)
  elseif g.race.goal == "Delirium" and g.raceVars.started then
    BigChest:Delirium(pickup)
  elseif g.race.goal == "Boss Rush" and g.raceVars.started then
    BigChest:BossRush(pickup)
  elseif g.race.goal == "Everything" and g.raceVars.started then
    BigChest:Everything(pickup)
  elseif (
    stage == 10 and stageType == 0 -- Sheol
    and g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) -- 328
  ) then
    BigChest.action = "down" -- Leave the big chest there by default
  elseif (
    stage == 10 and stageType == 1 -- Cathedral
    and g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) -- 327
  ) then
    BigChest.action = "up" -- Leave the big chest there by default
  end

  -- Now that we know what to do with the big chest, do it
  if BigChest.action == "leave" then
    -- Set a flag so that we leave it alone on the next frame
    pickup.Touched = true
    Isaac.DebugString("Leaving the Big Chest there.")
  elseif BigChest.action == "up" then
    -- Delete the chest and replace it with a beam of light so that we can fast-travel normally
    pickup.SpawnerType = EntityType.ENTITY_PLAYER -- 1
    FastTravel:ReplaceHeavenDoor(pickup)
  elseif BigChest.action == "down" then
    -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
    FastTravel:ReplaceTrapdoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity
  elseif BigChest.action == "remove" then
    pickup:Remove()
    Isaac.DebugString("Removed the Big Chest.")
  elseif BigChest.action == "checkpoint" then
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      BigChest.checkpointPos,
      g.zeroVector,
      nil,
      CollectibleType.COLLECTIBLE_CHECKPOINT,
      roomSeed
    )
    Speedrun.spawnedCheckpoint = true
    Isaac.DebugString(
      "Spawned a Checkpoint at (" .. tostring(BigChest.checkpointPos.X) .. ", "
      .. tostring(BigChest.checkpointPos.Y) .. ")"
    )
    pickup:Remove()
  elseif BigChest.action == "trophy" then
    -- Spawn the end of race/speedrun trophy
    local position = g.r:GetCenterPos()
    if roomType == RoomType.ROOM_BOSSRUSH then -- 17
      -- In some Boss Rush rooms, the center of the room will be covered by rocks or pits
      position = g.r:FindFreePickupSpawnPosition(position, 1, true)
    end
    Isaac.Spawn(EntityType.ENTITY_RACE_TROPHY, 0, 0, position, g.zeroVector, nil)
    Isaac.DebugString("Spawned the end of race/speedrun trophy.")
    pickup:Remove()

    -- Keep track that we spawned it so that we can respawn it if the player re-enters the room
    g.run.trophy.spawned = true
    g.run.trophy.stage = stage
    g.run.trophy.roomIndex = roomIndex
    g.run.trophy.position = position
  elseif BigChest.action == "victoryLap" then
    -- Spawn a button for the Victory Lap feature
    -- We want to use a position from the "GridToPos()" function because otherwise the position
    -- can slightly shift if it does not align with the grid
    local position = g:GridToPos(6, 3)
    if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      position = g:GridToPos(6, 9)
    end

    g.run.buttons[#g.run.buttons + 1] = {
      type = "victory-lap",
      pos = position,
      roomIndex = roomIndex,
    }
    Isaac.GridSpawn(
      GridEntityType.GRID_PRESSURE_PLATE, -- 20
      0,
      g.run.buttons[#g.run.buttons].pos,
      true
    )
    Sprites:Init("victory-lap-button", "victory-lap-button")
    Isaac.DebugString("Spawned a Victory Lap button to replace a Big Chest.")
    pickup:Remove()
  end
end

function BigChest:S1R9(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 9 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:S1R14(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 14 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:S2(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 0 then -- Sheol
    -- The Negative is optional in this season
    BigChest.action = "down"
  elseif stage == 11 and stageType == 0 then -- Dark Room
    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:SpeedrunAlternate(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  -- Season 3 runs alternate between directions,
  -- so we need to make sure we only handle the intended direction
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end

  -- The Polaroid / The Negative is optional in this season
  if (
    stage == 10 and stageType == 1 -- Cathedral
    and direction == 1
  ) then
    BigChest.action = "up"
  elseif (
    stage == 10 and stageType == 0 -- Sheol
    and direction == 2
  ) then
    BigChest.action = "down"
  elseif (
    (stage == 11 and stageType == 1 and direction == 1) -- The Chest
    or (stage == 11 and stageType == 0 and direction == 2) -- Dark Room
  ) then
    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:SpeedrunUp(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- The Polaroid / The Negative is optional in this season
    BigChest.action = "up"
  elseif stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:S7(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()

  -- Season 7 runs must complete every goal
  -- The Polaroid / The Negative are not optional in this season
  if (
    (
      stage == 6
      and g:TableContains(Season7.remainingGoals, "Boss Rush")
    )
    or (
      stage == 8
      and g:TableContains(Season7.remainingGoals, "It Lives!")
    )
    or (
      stage == 9
      and g:TableContains(Season7.remainingGoals, "Hush")
    )
    or (
      stage == 11
      and roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX  -- -7
      and g:TableContains(Season7.remainingGoals, "Mega Satan")
    )
    or (
      stage == 11
      and roomIndexUnsafe ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
      and stageType == 1
      and g:TableContains(Season7.remainingGoals, "Blue Baby")
    )
    or (
      stage == 11
      and roomIndexUnsafe ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
      and stageType == 0
      and g:TableContains(Season7.remainingGoals, "The Lamb")
    )
    or (
      stage == 12
      and roomIndexUnsafe == g.run.customBossRoomIndex
      and g:TableContains(Season7.remainingGoals, "Ultra Greed")
    )
  ) then
    if Speedrun.charNum == 7 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end

  if stage == 6 then
    -- Prevent the bug where the Checkpoint can spawn over a pit
    BigChest.checkpointPos = g.r:FindFreePickupSpawnPosition(BigChest.checkpointPos, 0, true)
  elseif stage == 8 then
    -- Put the Checkpoint in the corner of the room so that it does not interfere with the path to
    -- the next floor
    BigChest.checkpointPos = g:GridToPos(1, 1)
  end
end

function BigChest:SVanilla(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 15 then
      BigChest.action = "trophy"
    else
      BigChest.action = "checkpoint"
    end
  end
end

function BigChest:Pageant(pickup)
  -- Local variables
  local stage = g.l:GetStage()

  if stage == 11 then -- The Chest or the Dark Room
    -- We want to delete all big chests on the Pageant Boy ruleset so that
    -- you don't accidently end your run before you can show off your build to the judges
    BigChest.action = "remove"
  end
end

function BigChest:BlueBaby(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if (
    stage == 11 and stageType == 1 -- The Chest
    and roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
  ) then
    BigChest.action = "trophy"
  end
end

function BigChest:TheLamb(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if (
    stage == 11 and stageType == 0 -- Dark Room
    and roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
  ) then
    BigChest.action = "trophy"
  end
end

function BigChest:Everything(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 1 then
    -- Cathedral goes to Sheol
    BigChest.action = "down"
  elseif stage == 10 and stageType == 0 then
    -- Sheol goes to The Chest
    BigChest.action = "up"
  elseif stage == 11 and stageType == 1 then -- 7
    -- The Chest goes to the Dark Room
    BigChest.action = "down"
  elseif stage == 11 and stageType == 0 then
    if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      BigChest.action = "remove"
    else
      BigChest.action = "trophy"
    end
  end
end

function BigChest:MegaSatan(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()

  if (
    stage == 11 -- The Chest or the Dark Room
    and roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
  ) then
    -- We want to delete the big chest after Blue Baby or The Lamb
    -- to remind the player that they have to go to Mega Satan
    BigChest.action = "remove"
  elseif (
    stage == 11 -- The Chest or the Dark Room
    and roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX -- -7
  ) then
    BigChest.action = "trophy"
  end
end

function BigChest:Hush(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 9 then
    BigChest.action = "trophy"
  end
end

function BigChest:Delirium(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 12 then
    BigChest.action = "trophy"
  end
end

function BigChest:BossRush(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 6 then
    BigChest.action = "trophy"
  end
end

return BigChest
