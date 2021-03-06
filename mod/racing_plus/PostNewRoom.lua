local PostNewRoom = {}

-- Includes
local g = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")
local FastTravel = require("racing_plus/fasttravel")
local RacePostNewRoom = require("racing_plus/racepostnewroom")
local Speedrun = require("racing_plus/speedrun")
local SpeedrunPostNewRoom = require("racing_plus/speedrunpostnewroom")
local ChangeCharOrder = require("racing_plus/changecharorder")
local ChangeKeybindings = require("racing_plus/changekeybindings")
local Schoolbag = require("racing_plus/schoolbag")
local BossRush = require("racing_plus/bossrush")
local ChallengeRooms = require("racing_plus/challengerooms")
local Samael = require("racing_plus/samael")
local Sprites = require("racing_plus/sprites")

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function PostNewRoom:Main()
  -- Update some cached API functions to avoid crashing
  g.l = g.g:GetLevel()
  g.r = g.g:GetRoom()
  g.p = g.g:GetPlayer(0)
  g.seeds = g.g:GetSeeds()
  g.itemPool = g.g:GetItemPool()

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant

  Isaac.DebugString(
    "MC_POST_NEW_ROOM - " .. tostring(roomStageID) .. "." .. tostring(roomVariant) .. " "
    .. "(on stage " .. tostring(stage) .. ")"
  )

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewRoom gets called before the PostNewLevel and PostGameStarted callbacks)
  if (
    gameFrameCount == 0
    or g.run.currentFloor ~= stage
    or g.run.currentFloorType ~= stageType
  ) then
    -- Make an exception if we are using the "goto" command to go to a debug room
    if (
      g.run.goingToDebugRoom
      and roomStageID == 2
      and roomVariant == 0
    ) then
      g.run.goingToDebugRoom = false
    else
      return
    end
  end

  -- Don't enter the callback if we are planning on immediately reseeding the floor
  if FastTravel.reseed then
    Isaac.DebugString("Not entering the NewRoom() function due to an imminent reseed.")
    return
  end

  PostNewRoom:NewRoom()
end

function PostNewRoom:NewRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()

  Isaac.DebugString(
    "MC_POST_NEW_ROOM2 - " .. tostring(roomStageID) .. "." .. tostring(roomVariant) .. " "
    .. "(on stage " .. tostring(stage) .. ")"
  )

  -- Keep track of how many rooms we enter over the course of the run
  g.run.roomsEntered = g.run.roomsEntered + 1

  -- Reset the state of whether the room is clear or not
  -- (this is needed so that we don't get credit for clearing a room when
  -- bombing from a room with enemies into an empty room)
  g.run.currentRoomClearState = roomClear

  -- Check to see if we need to remove the heart container from a Strength card on Keeper
  -- (this has to be done before the resetting of the "g.run.usedStrength" variable)
  PostNewRoom:CheckRemoveKeeperHeartContainerFromStrength()

  -- Clear variables that track things per room
  g:InitRoom()

  -- Clear fast-clear variables that track things per room
  FastClear.buttonsAllPushed = false
  FastClear.roomInitializing = false
  -- (this is set to true when the room frame count is -1 and set to false here,
  -- where the frame count is 0)

  Samael:CheckHairpin() -- Check to see if we need to fix the Wraith Skull + Hairpin bug
  Schoolbag:PostNewRoom() -- Handle the Glowing Hour Glass mechanics relating to the Schoolbag
  BossRush:PostNewRoom()
  ChallengeRooms:PostNewRoom()
  -- Check to see if we need to respawn trapdoors / crawlspaces / beams of light
  FastTravel:CheckRoomRespawn()
  FastTravel:CheckNewFloor() -- Check if we are just arriving on a new floor
  FastTravel:CheckCrawlspaceMiscBugs() -- Check for miscellaneous crawlspace bugs

  PostNewRoom:CheckDrawEdenStartingItems()
  -- Remove the "More Options" buff if they have entered a Treasure Room
  PostNewRoom:CheckRemoveMoreOptions()
  PostNewRoom:CheckZeroHealth() -- Fix the bug where we don't die at 0 hearts
  PostNewRoom:CheckStartingRoom() -- Draw the starting room graphic
  PostNewRoom:CheckPostTeleportInvalidEntrance()
  PostNewRoom:CheckSatanRoom() -- Check for the Satan room
  PostNewRoom:CheckMegaSatanRoom() -- Check for Mega Satan on "Everything" races
  PostNewRoom:CheckScolexRoom() -- Check for all of the Scolex boss rooms
  PostNewRoom:CheckDepthsPuzzle() -- Check for the unavoidable puzzle room in the Dank Depths
  PostNewRoom:CheckEntities() -- Check for various NPCs
  -- Check to see if we need to respawn an end-of-race or end-of-speedrun trophy
  PostNewRoom:CheckRespawnTrophy()
  PostNewRoom:BanB1TreasureRoom() -- Certain formats ban the Treasure Room in Basement 1
  PostNewRoom:BanB1CurseRoom() -- Certain formats ban the Curse Room in Basement 1

  ChangeCharOrder:PostNewRoom() -- The "Change Char Order" custom challenge
  ChangeKeybindings:PostNewRoom() -- The "Change Keybindings" custom challenge
  RacePostNewRoom:Main() -- Do race related stuff
  SpeedrunPostNewRoom:Main() -- Do speedrun related stuff
end

-- Check to see if we need to remove the heart container from a Strength card on Keeper
-- (this has to be done before the resetting of the "g.run.usedStrength" variable)
function PostNewRoom:CheckRemoveKeeperHeartContainerFromStrength()
  -- Local variables
  local character = g.p:GetPlayerType()

  if (
    character == PlayerType.PLAYER_KEEPER -- 14
    and g.run.keeper.baseHearts == 4
    and g.run.usedStrength
  ) then
    g.run.keeper.baseHearts = 2
    g.p:AddMaxHearts(-2, true) -- Take away a heart container
    Isaac.DebugString(
      "Took away 1 heart container from Keeper (via a Strength card). (PostNewRoom)"
    )
  end
end

function PostNewRoom:CheckDrawEdenStartingItems()
  -- Show only the items in the starting room
  if g.run.roomsEntered >= 2 then
    Sprites:Init("eden-item1", 0)
    Sprites:Init("eden-item2", 0)
    return
  end

  local character = g.p:GetPlayerType()
  if character ~= PlayerType.PLAYER_EDEN then -- 9
    return
  end

  Sprites:Init("eden-item1", tostring(g.run.edenStartingItems[1]))
  Sprites:Init("eden-item2", tostring(g.run.edenStartingItems[2]))
end

-- Remove the "More Options" buff if they have entered a Treasure Room
function PostNewRoom:CheckRemoveMoreOptions()
  -- Local variables
  local roomType = g.r:GetType()

  if (
    g.run.removeMoreOptions == true
    and roomType == RoomType.ROOM_TREASURE -- 4
  ) then
    g.run.removeMoreOptions = false
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end
end

-- Check health (to fix the bug where we don't die at 0 hearts)
-- (this happens if Keeper uses Guppy's Paw or
-- when Magdalene takes a devil deal that grants soul/black hearts)
function PostNewRoom:CheckZeroHealth()
  -- Local variables
  local hearts = g.p:GetHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()

  if (
    hearts == 0
    and soulHearts == 0
    and boneHearts == 0
    and not g.run.seededSwap.swapping -- Make an exception if we are manually swapping health values
    and InfinityTrueCoopInterface == nil -- Make an exception if the True Co-op mod is on
  ) then
    g.p:Kill()
    Isaac.DebugString("Manually killing the player since they are at 0 hearts.")
  end
end

-- Racing+ re-implements the starting room graphic so that it will not interfere with other kinds of
-- graphics (some code is borrowed from Revelations / StageAPI)
function PostNewRoom:CheckStartingRoom()
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local centerPos = g.r:GetCenterPos()

  -- Only draw the graphic in the starting room of the first floor
  -- (and ignore Greed Mode, even though on vanilla the sprite will display in Greed Mode)
  if (
    g.run.startingRoomGraphics
    or g.g.Difficulty >= Difficulty.DIFFICULTY_GREED -- 2
    or stage ~= 1
    or roomIndex ~= g.l:GetStartingRoomIndex()
  ) then
    return
  end

  -- Spawn the custom "Floor Effect Creep" entity (1000.46.12545)
  local controlsEffect = Isaac.Spawn(
    EntityType.ENTITY_EFFECT,
    EffectVariant.PLAYER_CREEP_RED,
    12545, -- There is no "Isaac.GetEntitySubTypeByName()" function
    centerPos,
    g.zeroVector,
    nil
  ):ToEffect()
  controlsEffect.Timeout = 1000000
  local controlsSprite = controlsEffect:GetSprite()
  controlsSprite:Load("gfx/backdrop/controls.anm2", true)
  controlsSprite:Play("Idle")

  -- Always set the scale to 1 in case the player has an item like Lost Cork
  -- (otherwise, it will have a scale of 1.75)
  controlsEffect.Scale = 1

  -- On vanilla, the sprite is a slightly different color on the Burning Basement
  if stageType == StageType.STAGETYPE_AFTERBIRTH then
      controlsSprite.Color = Color(0.5, 0.5, 0.5, 1, 0, 0, 0)
  end
end

function PostNewRoom:CheckPostTeleportInvalidEntrance()
  if not g.run.usedTeleport then
    return
  end
  g.run.usedTeleport = false

  -- Local variables
  local roomShape = g.r:GetRoomShape()

  -- Don't bother fixing entrances in big room,
  -- as teleporting the player to a valid door can cause the camera to jerk in a buggy way
  if roomShape >= RoomShape.ROOMSHAPE_1x2 then -- 4
    return
  end

  -- Check to see if they are at an entrance
  local nextToADoor = false
  local firstDoorSlot
  local firstDoorPosition
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if (
      door ~= nil
      and door.TargetRoomType ~= RoomType.ROOM_SECRET -- 7
      and door.TargetRoomType ~= RoomType.ROOM_SUPERSECRET -- 8
    ) then
      if firstDoorSlot == nil then
        firstDoorSlot = i
        firstDoorPosition = Vector(door.Position.X, door.Position.Y)
      end
      if door.Position:Distance(g.p.Position) < 60 then
        nextToADoor = true
        break
      end
    end
  end

  -- Some rooms have no doors, like I AM ERROR rooms
  if not nextToADoor and firstDoorSlot ~= nil then
    -- They teleported to a non-existent entrance,
    -- so manually move the player next to the first door in the room
    -- We can't move them directly to the door position or they would just enter the loading zone
    -- Players always appear 40 units away from the door when entering a room,
    -- so calculate the offset based on the door slot
    local x = firstDoorPosition.X
    local y = firstDoorPosition.Y
    if (
      firstDoorSlot == DoorSlot.LEFT0 -- 0
      or firstDoorSlot == DoorSlot.LEFT1 -- 4
    ) then
      x = x + 40
    elseif (
      firstDoorSlot == DoorSlot.UP0 -- 1
      or firstDoorSlot == DoorSlot.UP1 -- 5
    ) then
      y = y + 40
    elseif (
      firstDoorSlot == DoorSlot.RIGHT0 -- 2
      or firstDoorSlot == DoorSlot.RIGHT1 -- 6
    ) then
      x = x - 40
    elseif (
      firstDoorSlot == DoorSlot.DOWN0 -- 3
      or firstDoorSlot == DoorSlot.DOWN1 -- 7
    ) then
      y = y - 40
    end

    -- Move the player
    local newPosition = Vector(x, y)
    g.p.Position = newPosition
    Isaac.DebugString("Manually moved a player to a door after an Undefined teleport.")

    -- Also move the familiars
    local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
    for _, familiar in ipairs(familiars) do
      familiar.Position = newPosition
    end
  end
end

-- Instantly spawn the first part of the fight
-- (there is an annoying delay before The Fallen and the leeches spawn)
function PostNewRoom:CheckSatanRoom()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed()
  local challenge = Isaac.GetChallenge()

  if roomClear then
    return
  end

  if roomStageID ~= 0 or roomVariant ~= 3600 then -- Satan
    return
  end

  -- In the season 3 speedrun challenge, there is a custom boss instead of Satan
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  -- Spawn 2x Kamikaze Leech (55.1) & 1x Fallen (81.0)
  -- 55.1 (Kamikaze Leech)
  local seed = roomSeed
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_LEECH, 1, g:GridToPos(5, 3), g.zeroVector, nil, 0, seed)
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_LEECH, 1, g:GridToPos(7, 3), g.zeroVector, nil, 0, seed)
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_FALLEN, 0, g:GridToPos(6, 3), g.zeroVector, nil, 0, seed)

  -- Prime the statue to wake up quicker
  local satans = Isaac.FindByType(EntityType.ENTITY_SATAN, -1, -1, false, false) -- 84
  for _, satan in ipairs(satans) do
    satan:ToNPC().I1 = 1
  end

  Isaac.DebugString("Spawned the first wave manually and primed the statue.")
end

-- Check to see if we are entering the Mega Satan room so we can update the floor tracker and
-- prevent cheating on the "Everything" race goal
function PostNewRoom:CheckMegaSatanRoom()
  -- Local variables
  local roomIndex = g:GetRoomIndex()

  -- Check to see if we are entering the Mega Satan room
  if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  -- Emulate reaching a new floor, using a custom floor number of 13 (The Void is 12)
  Isaac.DebugString('Entered the Mega Satan room.')

  -- Check to see if we are cheating on the "Everything" race goal
  if g.race.goal == "Everything" and not g.run.killedLamb then
    -- Do a little something fun
    g.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1) -- 267
    for i = 1, 20 do
      local pos = g.r:FindFreePickupSpawnPosition(g.p.Position, 50, true)
      -- Use a value of 50 to spawn them far from the player
      local monstro = Isaac.Spawn(EntityType.ENTITY_MONSTRO, 0, 0, pos, g.zeroVector, nil)
      monstro.MaxHitPoints = 1000000
      monstro.HitPoints = 1000000
    end
  end
end

function PostNewRoom:CheckScolexRoom()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed()
  local challenge = Isaac.GetChallenge()

  -- We don't need to modify Scolex if the room is already cleared
  if roomClear then
    return
  end

  -- We only need to check for rooms from the "Special Rooms" STB
  if roomStageID ~= 0 then
    return
  end

  -- Don't do anything if we are not in one of the Scolex boss rooms
  -- (there are no Double Trouble rooms with Scolexes)
  if (
    roomVariant ~= 1070
    and roomVariant ~= 1071
    and roomVariant ~= 1072
    and roomVariant ~= 1073
    and roomVariant ~= 1074
    and roomVariant ~= 1075
  ) then
    return
  end

  if (
    g.race.rFormat == "seeded"
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)")
  ) then
     -- Since Scolex attack patterns ruin seeded races, delete it and replace it with two Frails
    -- (there are 10 Scolex entities)
    local scolexes = Isaac.FindByType(EntityType.ENTITY_PIN, 1, -1, false, false) -- 62.1 (Scolex)
    for _, scolex in ipairs(scolexes) do
      scolex:Remove() -- This takes a game frame to actually get removed
    end

    local seed = roomSeed
    for i = 1, 2 do
      -- We don't want to spawn both of them on top of each other since that would make them behave
      -- a little glitchy
      local pos = g.r:GetCenterPos()
      if i == 1 then
        pos.X = pos.X - 150
      elseif i == 2 then
        pos.X = pos.X + 150
      end
      -- Note that pos.X += 200 causes the hitbox to appear too close to the left/right side,
      -- causing damage if the player moves into the room too quickly
      seed = g:IncrementRNG(seed)
      local frail = g.g:Spawn(EntityType.ENTITY_PIN, 2, pos, g.zeroVector, nil, 0, seed)
      -- It will show the head on the first frame after spawning unless we hide it
      frail.Visible = false
      -- The game will automatically make the entity visible later on
    end
    Isaac.DebugString("Spawned 2 replacement Frails for Scolex.")
  end
end

-- Prevent unavoidable damage in a specific room in the Dank Depths
function PostNewRoom:CheckDepthsPuzzle()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local gridSize = g.r:GetGridSize()

  -- We only need to check if we are in the Dank Depths
  if stage ~= 5 and stage ~= 6 then
    return
  end
  if stageType ~= 2 then
    return
  end

  if (
    roomVariant ~= 41
    and roomVariant ~= 10041 -- (flipped)
    and roomVariant ~= 20041 -- (flipped)
    and roomVariant ~= 30041 -- (flipped)
  ) then
    return
  end

  -- Scan the entire room to see if any rocks were replaced with spikes
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 17
        -- Remove the spikes
        gridEntity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

        -- Originally, we would add a rock here with:
        -- "Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, gridEntity.Position, true) -- 17"
        -- However, this results in invisible collision persisting after the rock is killed
        -- This bug can probably be subverted by waiting a frame for the spikes to fully despawn,
        -- but then having rocks spawn "out of nowhere" would look glitchy,
        -- so just remove the spikes and don't do anything else
        Isaac.DebugString("Removed spikes from the Dank Depths bomb puzzle room.")
      end
    end
  end
end

-- Check for various NPCs all at once
-- (we want to loop through all of the entities in the room only for performance reasons)
function PostNewRoom:CheckEntities()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomClear = g.r:IsClear()
  local roomShape = g.r:GetRoomShape()
  local roomSeed = g.r:GetSpawnSeed()
  local character = g.p:GetPlayerType()

  local subvertTeleport = false
  local pinFound = false
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if (
      entity.Type == EntityType.ENTITY_GURDY -- 36
      or entity.Type == EntityType.ENTITY_MOM -- 45
      or entity.Type == EntityType.ENTITY_MOMS_HEART -- 78 (this includes It Lives!)
    ) then
      subvertTeleport = true
      if entity.Type == EntityType.ENTITY_MOM then -- 45
        g.run.forceMomStomp = true
      end
    elseif (
      entity.Type == EntityType.ENTITY_SLOTH -- Sloth (46.0) and Super Sloth (46.1)
      or entity.Type == EntityType.ENTITY_PRIDE -- Pride (52.0) and Super Pride (52.1)
    ) then
      -- Replace all Sloths / Super Sloths / Prides / Super Prides with a new one that has an
      -- InitSeed equal to the room
      -- (we want the card drop to always be the same if there happens to be more than one in the
      -- room; in vanilla the type of card that drops depends on the order you kill them in)
      g.g:Spawn(
        entity.Type,
        entity.Variant,
        entity.Position,
        entity.Velocity,
        entity.Parent,
        entity.SubType,
        roomSeed
      )
      entity:Remove()
    elseif entity.Type == EntityType.ENTITY_PIN then -- 62
      pinFound = true
    elseif (
      entity.Type == EntityType.ENTITY_THE_HAUNT -- 260
      and entity.Variant == 0
    ) then
      -- Speed up the first Lil' Haunt attached to a Haunt (1/3)
      -- Later on this frame, the Lil' Haunts will spawn and have their state altered
      -- in the "PostNPCInit:Main()" function
      -- We will mark to actually detach one of them one frame from now
      -- (or two of them, if there are two Haunts in the room)
      g.run.speedLilHauntsFrame = gameFrameCount + 1

      -- We also need to check for the black champion version of The Haunt,
      -- since both of his Lil' Haunts should detach at the same time
      if entity:ToNPC():GetBossColorIdx() == 17 then
        g.run.speedLilHauntsBlack = true
      end
    elseif (
      entity.Type == EntityType.ENTITY_PITFALL -- 291
      and entity.Variant == 1 -- Suction Pitfall
      and roomClear
    ) then
      -- Prevent the bug where if Suction Pitfalls do not complete their "Disappear" animation by
      -- the time the player leaves the room, they will re-appear the next time the player enters
      -- the room (even though the room is already cleared and they should be gone)
      entity:Remove()
      Isaac.DebugString("Removed a buggy stray Suction Pitall.")
    end
  end

  -- Subvert the disruptive teleportation from Gurdy, Mom, Mom's Heart, and It Lives
  if (
    subvertTeleport
    and not roomClear
    and roomShape == RoomShape.ROOMSHAPE_1x1 -- 1
    -- (there are Double Trouble rooms with Gurdy but they don't cause a teleport)
  ) then
     g.run.teleportSubverted = true

    -- Make the player invisible or else it will show them on the teleported position for 1 frame
    -- (we can't just move the player here because the teleport occurs after this callback finishes)
    g.run.teleportSubvertScale = g.p.SpriteScale
    g.p.SpriteScale = g.zeroVector
    -- (we actually move the player on the next frame in the "PostRender:CheckSubvertTeleport()"
    -- function)

    -- Also make the familiars invisible
    -- (for some reason, we can use the "Visible" property instead of
    -- resorting to "SpriteScale" like we do for the player)
    local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
    for _, familiar in ipairs(familiars) do
      familiar.Visible = false
    end

    -- If we are The Soul, the Forgotten body will also need to be teleported
    -- However, if we change its position manually,
    -- it will just warp back to the same spot on the next frame
    -- Thus, just manually switch to the Forgotten to avoid this bug
    if character == PlayerType.PLAYER_THESOUL then -- 17
      g.run.switchForgotten = true
    end

    Isaac.DebugString("Subverted a position teleport (1/2).")
  end

  -- If Pin is in the room, cause a rumble as a warning for deaf players
  if pinFound then
    g.g:ShakeScreen(20)
    Isaac.DebugString("Pin detected; shaking the screen.")
  end
end

-- Check to see if we need to respawn an end-of-race or end-of-speedrun trophy
function PostNewRoom:CheckRespawnTrophy()
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local stage = g.l:GetStage()

  if (
    g.run.trophy.spawned == false
    or g.run.trophy.stage ~= stage
    or g.run.trophy.roomIndex ~= roomIndex
  ) then
    return
  end

  -- Don't respawn the trophy if we already touched it and finished a race or speedrun
  if g.raceVars.finished or Speedrun.finished then
    return
  end

  -- We are re-entering a room where a trophy spawned (which is a custom entity),
  -- so we need to respawn it
  Isaac.Spawn(EntityType.ENTITY_RACE_TROPHY, 0, 0, g.run.trophy.position, g.zeroVector, nil)
  Isaac.DebugString("Respawned the end of race / speedrun trophy.")
end

function PostNewRoom:BanB1TreasureRoom()
  if not PostNewRoom:CheckBanB1TreasureRoom() then
    return
  end

  -- Delete the doors to the Basement 1 treasure room, if any
  -- (this includes the doors in a Secret Room)
  -- (we must delete the door before changing the minimap, or else the icon will remain)
  local roomIndex = g.l:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, RNG()) -- 4
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil and door.TargetRoomIndex == roomIndex then
      g.r:RemoveDoor(i)
      Isaac.DebugString("Removed the Treasure Room door on B1.")
    end
  end

  -- Delete the icon on the minimap
  -- (this has to be done on every room, because it will reappear)
  local roomDesc
  if MinimapAPI == nil then
    roomDesc = g.l:GetRoomByIdx(roomIndex)
    roomDesc.DisplayFlags = 0
    g.l:UpdateVisibility() -- Setting the display flag will not actually update the map
  else
    roomDesc = MinimapAPI:GetRoomByIdx(roomIndex)
    if roomDesc ~= nil then
      roomDesc:Remove()
    end
  end
end

function PostNewRoom:CheckBanB1TreasureRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  return (
    stage == 1
    and (
      g.race.rFormat == "seeded"
      or challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)")
      or (challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") and Speedrun.charNum >= 2)
      or challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)")
      or challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
    )
  )
end

function PostNewRoom:BanB1CurseRoom()
  if not PostNewRoom:CheckBanB1CurseRoom() then
    return
  end

  -- Delete the doors to the Basement 1 curse room, if any
  -- (this includes the doors in a Secret Room)
  -- (we must delete the door before changing the minimap, or else the icon will remain)
  local roomIndex
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    -- We check for "door.TargetroomType" instead of "door.TargetRoomIndex" because it leads to bugs
    if door ~= nil and door.TargetRoomType == RoomType.ROOM_CURSE then -- 10
      g.r:RemoveDoor(i)
      roomIndex = door.TargetRoomIndex
      Isaac.DebugString("Removed the Curse Room door on B1.")
    end
  end
  if roomIndex == nil then
    return
  end

  -- Delete the icon on the minimap
  -- (this has to be done on every room, because it will reappear)
  local roomDesc
  if MinimapAPI == nil then
    roomDesc = g.l:GetRoomByIdx(roomIndex)
    roomDesc.DisplayFlags = 0
    g.l:UpdateVisibility() -- Setting the display flag will not actually update the map
  else
    roomDesc = MinimapAPI:GetRoomByIdx(roomIndex)
    if roomDesc ~= nil then
      roomDesc:Remove()
    end
  end
end

function PostNewRoom:CheckBanB1CurseRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  return (
    stage == 1
    and challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
  )
end

return PostNewRoom
