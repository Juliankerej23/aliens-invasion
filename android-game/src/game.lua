-- Aliens Invasion LÖVE 2D — v38 upvalue-safe refactor + APK behavior/store/animation/level correction
M = {}
Combat = require("src.combat")
W,H = 576,320
state="menu"
difficulty=2
level=1
player=nil
playerDeathTimer=0
playerAction="idle"
playerActionT=0
buildingOpenT=0
enemies,bullets,fx,loot,players={}, {}, {}, {}, {}
remotePlayer=nil
remoteInput={left=false,right=false,fire=false,melee=false,weapon=1,face=-1,seq=0}
remoteAmmo=75
remoteMoney=0
remoteDiamonds=0
stepClock=0
netMode="LOCAL"
netInput={left=false,right=false,fire=false,melee=false,weapon=1,face=1}
netSendClock=0
touch={}
images,ui,audio={}, {}, {}
anim={}
weapons={}
weaponPrices={}
bg=nil;menubg=nil;logo=nil;gameover=nil
font12=nil;font16=nil;font22=nil
worldX=0
camX=0
WORLD_W=1680
WORLD_END=1680
CAMERA_TARGET_X=286
CAMERA_SMOOTH=18.0
CAMERA_LOOKAHEAD=0
CAMERA_MIN_X=0
CAMERA_MAX_X=nil
BUILDING_X=214
PLAYER_START_X=286
PLAYER_GROUND_Y=230
ROAD_Y=261
ROAD_DETAIL_Y=268
ALIEN_SPAWN_DURATION=0.72
ALIEN_SPAWN_DEPTH=48

-- v28 calibration was measured against the supplied gameplay photos after
-- perspective-rectifying them to the native 576x320 game viewport.
CAL={
  playerX=286, playerY=230,
  groundY=263,
  cBuilding={x=214, c00y=112, c01y=31, c02y=104, doorX=291, doorY=163},
  cTip={x=248,y=70}, cArrow={x=304,y=124},
  aTipOffsetX=42, aTipY=84, aArrowOffsetX=148, aArrowY=124,
  lifeOffsetX=-33, lifeOffsetY=-85,
  controls={leftX=26,rightX=132,meleeX=443,fireX=516, y=252},
  cactus={x=50,y=218}
}
TUTORIAL_TIME=7.0
spawnClock=0
kills=0
money=0
diamonds=0
ammo=75
lives=5
enemyAttackClock=0
levelTier=0
boss=nil
buildingSoundCd=0
activeBuildingKind=nil
activeBuildingX=nil
buildingOpen={a=0,b=0,c=0}
roadDecorSeed=0
tutorialTimer=0
tutorialSeen=false
levelClearTimer=0
levelClearPending=false
helpFromMenu=false
storeCursor=1
storeScroll=0
storeCamX=0
storePlayer={x=55,y=252,face=1,anim=0,walking=false,intro=0,done=false}
syncStoreScroll=nil
meleeWeaponIndex=1
ownedWeapons={}
meleeOwned=1
storeItems={}
meleePrices={0,60,120}
ip="192.168.1.1"
musicSource=nil
musicState=nil
sfxSerial=0
sfxPools={
  shoot={"zm_sfx00.ogg","zm_sfx03.ogg","zm_sfx12.ogg","zm_sfx0f.ogg"},
  melee={"zm_sfx13.ogg","zm_sfx14.ogg","zm_sfx15.ogg"},
  hit={"zm_sfx04.ogg","zm_sfx05.ogg","zm_sfx16.ogg"},
  damage={"zm_sfx06.ogg","zm_sfx17.ogg"},
  death={"zm_sfx09.ogg","zm_sfx10.ogg"},
  pickup={"zm_sfx0a.ogg","zm_sfx18.ogg"},
  enemy={"zm_sfx0c.ogg","zm_sfx19.ogg"},
  enemyShoot={"zm_sfx0f.ogg","zm_sfx12.ogg"},
  misc={"zm_sfx0c.ogg","zm_sfx19.ogg"},
  boss={"zm_sfx1a.ogg","zm_boss00attack.ogg"},
}

-- Explicit mapping keeps every original gameplay SFX reachable.
soundForWeapon={
  [1]="zm_sfx00.ogg",
  [2]="zm_sfx03.ogg",
  [3]="zm_sfx12.ogg",
  [4]="zm_sfx13.ogg",
  [5]="zm_sfx14.ogg",
  [6]="zm_sfx15.ogg",
  [7]="zm_sfx16.ogg",
  [8]="zm_sfx17.ogg",
  [9]="zm_sfx0f.ogg",
  [10]="zm_sfx19.ogg",
}

playFile=nil;playSfx=nil

-- Every gameplay SFX from the APK is routed through an explicit event. The
-- exact original Java call sites are not available, so this keeps the original
-- files intact and gives each one a stable gameplay role rather than inventing audio.
eventSound={
  step={"zm_sfx17.ogg","zm_sfx18.ogg"},
  weaponSwitch={"zm_click.ogg","zm_sfx19.ogg"},
  melee={"zm_sfx13.ogg","zm_sfx14.ogg","zm_sfx15.ogg"},
  hit={"zm_sfx04.ogg","zm_sfx05.ogg","zm_sfx16.ogg"},
  damage={"zm_sfx06.ogg","zm_sfx17.ogg"},
  death={"zm_sfx09.ogg","zm_sfx10.ogg"},
  pickup={"zm_sfx0a.ogg","zm_sfx18.ogg"},
  enemy={"zm_sfx0c.ogg","zm_sfx19.ogg"},
  enemyShoot={"zm_sfx0f.ogg","zm_sfx12.ogg"},
  boss={"zm_sfx1a.ogg","zm_boss00attack.ogg"},
  explosion={"a_gboom.ogg"},
}
eventSerial={}
enemyEventSound={
  [1]={hit={"zm_sfx04.ogg","zm_sfx05.ogg"},damage={"zm_sfx06.ogg"},death={"zm_sfx09.ogg"},attack={"zm_sfx0c.ogg"}},
  [2]={hit={"zm_sfx05.ogg","zm_sfx16.ogg"},damage={"zm_sfx17.ogg"},death={"zm_sfx10.ogg"},attack={"zm_sfx19.ogg"}},
  [3]={hit={"zm_sfx16.ogg","zm_sfx14.ogg"},damage={"zm_sfx17.ogg","zm_sfx06.ogg"},death={"zm_sfx10.ogg","zm_sfx09.ogg"},attack={"zm_sfx12.ogg"}},
}
function playEnemyEvent(e,kind,volume)
  local cfg=enemyEventSound[e and e.typ or 1]
  local pool=cfg and cfg[kind]
  if not pool or #pool==0 then return playEvent(kind,volume) end
  e.soundSeq=(e.soundSeq or 0)+1
  playFile(pool[((e.soundSeq-1)%#pool)+1],volume or .8)
end
function playEvent(kind,volume)
  local pool=eventSound[kind]
  if not pool then return playSfx(kind,volume) end
  eventSerial[kind]=(eventSerial[kind] or 0)+1
  local name=pool[((eventSerial[kind]-1)%#pool)+1]
  playFile(name,volume or .8)
end

function playFile(name,volume)
  local src=audio[name]
  if not src then return end
  local use=src
  if src.clone then
    local ok,c=pcall(src.clone,src)
    if ok and c then use=c end
  end
  use:setLooping(false)
  use:setVolume(volume or 0.9)
  pcall(love.audio.play,use)
end

function playClick(volume)
  local src=audio["zm_click.ogg"]
  if src then src:setLooping(false); src:setVolume(volume or 0.8); pcall(love.audio.play,src) end
end

function playExplosion(volume)
  local src=audio["a_gboom.ogg"]
  if src then src:setLooping(false); src:setVolume(volume or 0.9); pcall(love.audio.play,src) end
end

function playSfx(kind,volume)
  local pool=sfxPools[kind] or sfxPools.misc
  if not pool or #pool==0 then return end
  sfxSerial=sfxSerial+1
  local name=pool[((sfxSerial-1)%#pool)+1]
  local src=audio[name]
  if not src then return end
  local use=src
  if src.clone then
    local ok,c=pcall(src.clone,src)
    if ok and c then use=c end
  end
  use:setLooping(false)
  use:setVolume(volume or 0.9)
  pcall(love.audio.play,use)
end

function updateMusic(target)
  if musicState==target then return end
  if musicSource then pcall(musicSource.stop,musicSource) end
  musicSource=nil; musicState=target
  local name=(target=="menu" and "zm_menu.ogg") or (target=="game" and "zm_bginstage.ogg")
  if name and audio[name] then
    musicSource=audio[name]
    musicSource:setLooping(true)
    musicSource:setVolume(0.55)
    pcall(love.audio.play,musicSource)
  end
end


function loadDir(dir,bucket,loader)
  for _,n in ipairs(love.filesystem.getDirectoryItems(dir)) do
    local ok,o=pcall(loader,dir.."/"..n)
    if ok and o then bucket[n]=o end
  end
end

function frames(prefix)
  local names={}
  for _,n in ipairs(love.filesystem.getDirectoryItems("assets/images")) do
    if n:sub(1,#prefix)==prefix then names[#names+1]=n end
  end
  table.sort(names)
  local out={}
  for _,n in ipairs(names) do
    local ok,o=pcall(love.graphics.newImage,"assets/images/"..n)
    if ok then out[#out+1]=o end
  end
  return out
end

function pick(a,t,fps)
  if not a or #a==0 then return nil end
  return a[(math.floor(t*fps)%#a)+1]
end

function drawSprite(img,x,y,flip,s)
  if not img then return end
  s=s or 1
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(img,x,y,0,flip and -s or s,s,img:getWidth()/2,img:getHeight()/2)
end

function img(name)
  return images[name] or ui[name]
end

function drawDigitString(x,y,value,prefix,scale,gap)
  local s=tostring(math.max(0,math.floor(value or 0)))
  scale=scale or 1
  gap=gap or 0
  local cx=x
  for i=1,#s do
    local d=tonumber(s:sub(i,i))
    -- Digit assets are named act_num0000..0009 (and act_num0100..0109),
    -- so the prefix already contains the first three digits of the asset id.
    local n=string.format("%s%d.PNG",prefix,d)
    local im=img(n)
    if im then
      love.graphics.draw(im,cx,y,0,scale,scale)
      cx=cx+im:getWidth()*scale+gap
    end
  end
end

function buildStoreItems()
  -- The APK store contains the nine firearm upgrades (gun01..gun0c).
  -- gun00/pistol is the starting weapon and is intentionally NOT a purchase.
  -- 010d/010e are the two melee upgrades, followed by +life and the fire item.
  storeItems={
    {img="act_store0100.png",kind="weapon",id=2,price=40,label="ARMA 2"},
    {img="act_store0101.png",kind="weapon",id=3,price=80,label="ARMA 3"},
    {img="act_store0102.png",kind="weapon",id=4,price=120,label="ARMA 4"},
    {img="act_store0103.png",kind="weapon",id=5,price=180,label="ARMA 5"},
    {img="act_store0104.png",kind="weapon",id=6,price=260,label="ARMA 6"},
    {img="act_store0105.png",kind="weapon",id=7,price=360,label="ARMA 7"},
    {img="act_store0106.png",kind="weapon",id=8,price=500,label="ARMA 8"},
    {img="act_store0107.png",kind="weapon",id=9,price=700,label="ARMA 9"},
    {img="act_store0108.png",kind="weapon",id=10,price=900,label="ARMA 10"},
    {img="act_store0109.png",kind="ammo",amount=20,price=15,label="MUNICION"},
    {img="act_store010a.png",kind="ammo",amount=20,price=15,label="MUNICION"},
    {img="act_store010b.png",kind="ammo",amount=25,price=15,label="MUNICION"},
    {img="act_store010c.png",kind="diamonds",amount=5,price=20,label="+5 DIAMANTES"},
    {img="act_store010d.png",kind="melee",level=2,price=60,label="MACHETE II"},
    {img="act_store010e.png",kind="melee",level=3,price=120,label="MACHETE III"},
    {img="act_store010f.png",kind="life",amount=1,price=100,label="+1 VIDA"},
    {img="act_store0200.png",kind="fireball",amount=3,price=45,label="+3"},
  }
end

function weaponOwned(id)
  return ownedWeapons[id] == true
end

function purchaseStoreItem(index)
  local it=storeItems[index]
  if not it then return false end
  if it.kind=="weapon" then
    if weaponOwned(it.id) then
      player.weapon=it.id
      playClick(.35)
      return true
    end
    if money<it.price then playEvent("damage",.32); return false end
    money=money-it.price
    ownedWeapons[it.id]=true
    player.weapon=it.id
    ammo=math.max(ammo,25)
    playEvent("pickup",.72)
    return true
  elseif it.kind=="melee" then
    if meleeOwned>=it.level then return true end
    if money<it.price then playEvent("damage",.32); return false end
    money=money-it.price
    meleeOwned=it.level
    meleeWeaponIndex=meleeOwned
    playEvent("pickup",.72)
    return true
  elseif money<it.price then
    playEvent("damage",.32); return false
  end
  money=money-it.price
  if it.kind=="ammo" then
    ammo=math.min(99,ammo+(it.amount or 20))
  elseif it.kind=="diamonds" then
    diamonds=math.min(99,diamonds+(it.amount or 5))
  elseif it.kind=="life" then
    lives=math.min(9,lives+(it.amount or 1))
  elseif it.kind=="fireball" then
    ammo=math.min(99,ammo+(it.amount or 3)*3)
  end
  playEvent("pickup",.72)
  return true
end

function drawHealthBar(x,y,hp,maxhp)
  local back=img("act_life00.PNG")
  local fill=img("act_life01.PNG")
  if back then love.graphics.draw(back,math.floor(x),math.floor(y)) end
  if fill then
    local frac=math.max(0,math.min(1,(hp or 0)/(maxhp or 100)))
    -- Do not use love.graphics.setScissor here: scissor coordinates are framebuffer
    -- based and the Android presentation scale made the yellow fill disappear.
    -- Scaling the original yellow strip from its left edge reveals the original red
    -- background as health is lost, exactly like the APK bar.
    love.graphics.draw(fill,math.floor(x+2),math.floor(y+2),0,frac,1)
  end
end

function allowedAlienType()
  -- The original progression introduces the alien identities by stage:
  -- stage 1 = purple (A), stage 2 = brown (B), stage 3 = green (C).
  -- Later stages can combine the identities already introduced.
  if level<=1 then return 1 end
  if level==2 then return 2 end
  if level==3 then return 3 end
  local r=math.random()
  if r<.34 then return 1 elseif r<.67 then return 2 else return 3 end
end

function beginNextLevel()
  level=level+1
  levelTier=math.floor((level-1)/3)
  enemies={}; bullets={}; fx={}; loot={}; boss=nil
  levelClearPending=false; levelClearTimer=0
  worldX=0; camX=0
  player.x=PLAYER_START_X; player.hp=player.maxhp; player.dead=false
  player.walking=false; playerAction="idle"; playerActionT=0; player.shootAnim=0; player.meleeCd=0
  spawnClock=2.2
  state="playing"
  updateMusic("game")
end

function beginStore()
  state="store"
  storeCursor=1
  storeScroll=0
  storeCamX=0
  storePlayer={x=55,y=252,face=1,anim=0,walking=true,intro=.70,done=false}
  syncStoreScroll()
  playClick(.85)
end

function updateStore(dt)
  local dx=0
  if love.keyboard.isDown("left","a") or touch.left then dx=dx-1 end
  if love.keyboard.isDown("right","d") or touch.right then dx=dx+1 end
  if storePlayer.intro>0 then
    storePlayer.intro=math.max(0,storePlayer.intro-dt)
    dx=1
  end
  storePlayer.walking=(dx~=0)
  if dx~=0 then
    storePlayer.x=math.max(40,math.min(1055,storePlayer.x+150*dt))
    storePlayer.face=dx>0 and 1 or -1
    storePlayer.anim=storePlayer.anim+dt
  end
  local target=storePlayer.x-220
  storeCamX=storeCamX+(math.max(0,math.min(528,target))-storeCamX)*(1-math.exp(-14*dt))
  if storePlayer.x>=1045 and not storePlayer.done then
    storePlayer.done=true
    beginNextLevel()
  end
end

function reset()
  ownedWeapons={}
  ownedWeapons[1]=true
  meleeOwned=1
  meleeWeaponIndex=1
  player={id=0,x=PLAYER_START_X,y=PLAYER_GROUND_Y,face=1,hp=100,maxhp=100,anim=0,fireCd=0,meleeCd=0,shootAnim=0,hitFlash=0,weapon=1,walking=false,hurtKick=0}
  playerAction="idle"; playerActionT=0
  enemies={}
  bullets={}
  fx={}
  loot={}
  players={}
  remotePlayer=nil
  remoteInput={left=false,right=false,fire=false,melee=false,weapon=1,face=-1,seq=0}
  remoteAmmo=75; remoteMoney=0; remoteDiamonds=0
  stepClock=0
  tutorialTimer=tutorialSeen and 0 or TUTORIAL_TIME
  levelClearTimer=0
  levelClearPending=false
  storeScroll=0
  netInput={left=false,right=false,fire=false,melee=false,weapon=1,face=1}
  netSendClock=0
  boss=nil
  playerDeathTimer=0
  buildingOpenT=0
  buildingSoundCd=0
  activeBuildingKind=nil; activeBuildingX=nil
  buildingOpen={a=0,b=0,c=0}
  worldX=0
  camX=0
  spawnClock=4.0
  enemyAttackClock=1.1
  kills=0
  money=0
  diamonds=0
  ammo=75
  lives=5
  level=1
  levelTier=0
  state="playing"
  player.walking=false; player.meleeCd=0; player.shootAnim=0; player.hitFlash=0; playerAction="idle"; playerActionT=0
  -- First encounter: one purple alien entering from the right, as in the reference.
  enemies[#enemies+1]={id=1,typ=1,x=510,y=PLAYER_GROUND_Y,hp=2,maxhp=2,spd=29,t=0,anim=0,attack=0,attackCd=1.15,attackPhase=0,attackKind=nil,meleeCd=0,hitFlash=0,deathT=0,deathFrame=0,dead=false,side=1,specialT=0,damage=10,spawnT=ALIEN_SPAWN_DURATION,spawnDuration=ALIEN_SPAWN_DURATION}
  fx[#fx+1]={x=510,y=PLAYER_GROUND_Y-18,t=.55,maxT=.55,kind=14,frames={anim.halo},scale=.82,frameT=0,frame=0,vx=0,vy=0}
  updateMusic("game")
end

function addFx(x,y,kind,frameset,duration,scale)
  fx[#fx+1]={x=x,y=y,t=duration or .32,maxT=duration or .32,kind=kind or 1,frames=frameset,scale=scale or 1,frameT=0,frame=0,vx=math.random(-45,45),vy=math.random(-55,5)}
end

function spawnEnemy()
  local typ=allowedAlienType()
  -- After the first scripted encounter, aliens can emerge from either side.
  -- This keeps the opening reference intact while making later waves symmetrical.
  local side=(#enemies==0 and level==1 and 1) or (math.random()<.5 and -1 or 1)
  local tier=math.floor((level-1)/3)
  local baseHp=(typ==1 and 2) or (typ==2 and 3) or 5
  local hp=math.max(1,math.floor(baseHp*(1+0.35*tier)+0.5))
  local baseSpeed=25+typ*4
  local speed=baseSpeed+tier*5
  local damage=10+typ*2+tier*4
  local x=side>0 and math.min(WORLD_W+55,player.x+300+math.random(0,45)) or math.max(-55,player.x-300-math.random(0,35))
  enemies[#enemies+1]={
    id=#enemies+1,typ=typ,x=x,y=PLAYER_GROUND_Y,hp=hp,maxhp=hp,spd=speed,t=math.random()*3,anim=math.random()*2,
    attack=0,attackCd=1.0+math.random()*1.1-math.min(.28,tier*.05),attackPhase=0,attackKind=nil,meleeCd=0,hitFlash=0,deathT=0,deathFrame=0,dead=false,side=side,specialT=0,damage=damage,levelTier=tier,spawnT=ALIEN_SPAWN_DURATION,spawnDuration=ALIEN_SPAWN_DURATION
  }
end

function setPlayerAction(name,duration)
  playerAction=name or "idle"
  playerActionT=duration or .24
end

function killEnemy(e, killerOwner)
  if e.dead then return end
  e.dead=true
  e.deathT=0
  e.attackPhase=0
  e.hitFlash=0
  e.killer=killerOwner or 0
  local ds=e.typ==1 and anim.aDeath or e.typ==2 and anim.bDeath or anim.cDeath
  addFx(e.x,e.y,8,ds,.62,1.0)
  addFx(e.x,e.y,2,anim.enemyBloodBig,.48,1.0)
  playEnemyEvent(e,"death",0.8)
end

function melee()
  if state~="playing" or player.meleeCd>0 or player.dead then return end
  player.meleeCd=.48
  player.shootAnim=.16
  setPlayerAction("melee",.48)
  playSfx("melee",0.8)
  local hit=false
  local meleeDamage=2+(meleeWeaponIndex or 1)
  for i=#enemies,1,-1 do
    local e=enemies[i]
    local dx=e.x-player.x
    if dx*player.face>0 and math.abs(dx)<82 and math.abs(e.y-player.y)<55 then
      e.hp=e.hp-meleeDamage
      e.hitFlash=.18; e.attackPhase=0
      addFx(e.x,e.y,2,(#anim.enemyBloodAlt>0 and anim.enemyBloodAlt[math.random(#anim.enemyBloodAlt)] or anim.enemyBlood),.42,.9); playEvent("hit",0.75); hit=true
      if e.hp<=0 then killEnemy(e,0) end
    end
  end
  if anim.chopper and #anim.chopper>0 then
    local idx=math.max(1,math.min(3,meleeWeaponIndex or 1))
    local set=anim.chopper[idx]
    addFx(player.x+player.face*34,player.y-24,12,set,.30,.62)
  elseif not hit then addFx(player.x+player.face*42,player.y-22,5) end
end

function startBoss()
  if boss then return end
  boss={x=720,y=178,hp=80,maxhp=80,t=0,fire=1.2,phase=0,hitFlash=0,stone=0,face=-1}
  playEvent("boss",0.9)
end

function updateWorld(dt,net)
  local dx=0
  local isClient = net and net.isClient and net.isClient()
  local isHost = net and net.isHost and net.isHost()
  if isClient then
    -- Convert current local controls into a compact network intent.
    netInput.left=touch.left or love.keyboard.isDown("left","a")
    netInput.right=touch.right or love.keyboard.isDown("right","d")
    netInput.fire=touch.fire or love.keyboard.isDown("space")
    netInput.melee=touch.melee or love.keyboard.isDown("z")
    if netInput.left then dx=dx-1 end
    if netInput.right then dx=dx+1 end
  else
    if love.keyboard.isDown("left","a") or touch.left then dx=dx-1 end
    if love.keyboard.isDown("right","d") or touch.right then dx=dx+1 end
  end
  if player.dead then dx=0 end
  player.walking=(dx~=0)
  if dx~=0 then
    player.x=player.x+dx*155*dt
    player.face=dx>0 and 1 or -1
  end
  if isClient then
    netInput.weapon=player.weapon
    player.weapon=netInput.weapon or player.weapon
    if netInput.fire then ammo=Combat.fire(state,player,ammo,weapons,weaponOwned,setPlayerAction,bullets,anim,addFx,fx,soundForWeapon,playFile) end
    if netInput.melee then melee() end
  else
    if love.keyboard.isDown("space") or touch.fire then ammo=Combat.fire(state,player,ammo,weapons,weaponOwned,setPlayerAction,bullets,anim,addFx,fx,soundForWeapon,playFile) end
    if love.keyboard.isDown("z") or touch.melee then melee() end
  end
  -- Original-style side scrolling: the cowboy has a small dead zone and the
  -- scenery glides smoothly underneath him.  This is deliberately not a hard
  -- camera lock, which is what caused the earlier builds to look unlike the photos.
  player.x=math.max(55,math.min(WORLD_W-55,player.x))
  -- v28 camera calibration: keep the cowboy at the same left-of-center
  -- screen coordinate used by the reference photos. This makes the building
  -- and enemies slide past him instead of changing their apparent scale or
  -- vertical alignment.
  local targetCam=player.x-CAMERA_TARGET_X
  local maxCam=math.max(0,WORLD_W-W)
  targetCam=math.max(0,math.min(maxCam,targetCam))
  local blend=1-math.exp(-CAMERA_SMOOTH*dt)
  camX=camX+(targetCam-camX)*blend
  player.fireCd=math.max(0,player.fireCd-dt)
  playerActionT=math.max(0,playerActionT-dt)
  if playerActionT<=0 and playerAction~="idle" and not player.dead and not player.walking then playerAction="idle" end
  player.meleeCd=math.max(0,(player.meleeCd or 0)-dt)
  player.shootAnim=math.max(0,(player.shootAnim or 0)-dt)
  player.hitFlash=math.max(0,(player.hitFlash or 0)-dt)
  player.hurtKick=(player.hurtKick or 0)*(math.max(0,1-dt*8))
  if math.abs(player.hurtKick)>0.05 and not player.dead then player.x=math.max(55,math.min(WORLD_W-55,player.x+player.hurtKick*dt)) end
  buildingSoundCd=math.max(0,buildingSoundCd-dt)
  buildingOpenT=math.max(0,(buildingOpenT or 0)-dt)
  for k,v in pairs(buildingOpen) do buildingOpen[k]=math.max(0,v-dt) end
  if player.dead then
    playerDeathTimer=math.max(0,playerDeathTimer-dt)
    if playerDeathTimer<=0 then
      if lives>0 then
        player.dead=false; player.hp=player.maxhp; player.x=math.max(120,player.x-55); player.hitFlash=0; playerAction="idle"; playerActionT=0
        playEvent("pickup",0.55)
      else
        state="gameover"
      end
    end
  end
  if math.abs(player.x-410)<78 and buildingSoundCd<=0 then
    buildingSoundCd=2.5
    playFile("zm_sfx19.ogg",0.38)
  end
  player.anim=player.anim+dt
  if player.walking then
    stepClock=stepClock-dt
    if stepClock<=0 then
      -- Very short original SFX; keep it quiet so it never masks the weapon sounds.
      playEvent("step",0.22)
      stepClock=.30
    end
  else
    stepClock=0
  end
  tutorialTimer=math.max(0,tutorialTimer-dt)
  worldX=worldX+dt*(player.walking and 28 or 18)

  if isClient then
    -- The client only predicts its own movement/fire animation. Shared world state comes from host snapshots.
    netSendClock=netSendClock-dt
    if netSendClock<=0 and net and net.sendInput then
      net.sendInput(player.x,player.y,player.face,netInput.fire,player.weapon,netInput.left,netInput.right,netInput.melee)
      netSendClock=0.05
    end
  end

  if isClient then
    -- Client predicts only its own movement; the host remains authoritative for the shared world.
    for i=#fx,1,-1 do
      local p=fx[i]; p.x=p.x+p.vx*dt; p.y=p.y+p.vy*dt; p.t=p.t-dt; p.frameT=p.frameT+dt
      if p.frames and #p.frames>0 then p.frame=math.floor((p.frameT/(p.maxT/#p.frames))) end
      if p.t<=0 then table.remove(fx,i) end
    end
    return
  end

  -- Server-side player 2 simulation. The client sends intent, not authoritative coordinates.
  if remotePlayer then
    local rdx=0
    if remoteInput.left then rdx=rdx-1 end
    if remoteInput.right then rdx=rdx+1 end
    if rdx~=0 then
      remotePlayer.x=math.max(55,math.min(WORLD_W-55,remotePlayer.x+rdx*155*dt))
      remotePlayer.face=rdx>0 and 1 or -1
      remotePlayer.walking=true
      remotePlayer.anim=(remotePlayer.anim or 0)+dt
    else
      remotePlayer.walking=false
    end
    remotePlayer.fireCd=math.max(0,(remotePlayer.fireCd or 0)-dt)
    remotePlayer.meleeCd=math.max(0,(remotePlayer.meleeCd or 0)-dt)
    remotePlayer.shootAnim=math.max(0,(remotePlayer.shootAnim or 0)-dt)
    if remoteInput.fire and remotePlayer.fireCd<=0 and remoteAmmo>0 then
      remotePlayer.fireCd=.22; remotePlayer.shootAnim=.20; remoteAmmo=remoteAmmo-1
      local w=weapons[remoteInput.weapon] or weapons[1]
      bullets[#bullets+1]={x=remotePlayer.x+remotePlayer.face*42,y=remotePlayer.y-25,vx=remotePlayer.face*w.speed,life=1.2,dmg=w.damage,owner=1,weapon=remoteInput.weapon}
      addFx(remotePlayer.x+remotePlayer.face*40,remotePlayer.y-25,4); playFile(soundForWeapon[remoteInput.weapon] or "zm_sfx00.ogg",0.68)
    end
    if remoteInput.melee and remotePlayer.meleeCd<=0 then
      remotePlayer.meleeCd=.48; remotePlayer.shootAnim=.16
      playSfx("melee",0.65)
      for i=#enemies,1,-1 do
        local e=enemies[i]; local dx=e.x-remotePlayer.x
        if dx*remotePlayer.face>0 and math.abs(dx)<78 and math.abs(e.y-remotePlayer.y)<55 then
          e.hp=e.hp-2; addFx(e.x,e.y,2,anim.enemyBlood,.42,.9); playSfx("hit",0.6)
          if e.hp<=0 then killEnemy(e,1) end
        end
      end
    end
  end

  -- Pickups: the APK has diamond artwork; ammo/cash are represented with the
  -- same original HUD iconography. They float, expire, and are collected by touch.
  for i=#loot,1,-1 do
    local q=loot[i]
    q.y=q.y+(q.vy or 0)*dt; q.vy=(q.vy or 0)+55*dt
    q.t=q.t-dt
    if math.abs(q.x-player.x)<42 and math.abs(q.y-player.y)<58 then
      if q.kind=="diamond" then diamonds=diamonds+1
      elseif q.kind=="ammo" then ammo=math.min(99,ammo+(q.amount or 8))
      elseif q.kind=="cash" then money=money+(q.amount or 10) end
      playEvent("pickup",0.82)
      addFx(q.x,q.y-12,4,anim.muzzle,.18,.42)
      table.remove(loot,i)
    elseif q.t<=0 then
      table.remove(loot,i)
    end
  end

  spawnClock=spawnClock-dt
  if spawnClock<=0 and not boss then
    -- Keep the opening composition close to the reference; later enemies enter one at a time.
    if #enemies < math.min(3,1+math.floor(level/2)) then spawnEnemy() end
    spawnClock=math.max(1.8,3.2-difficulty*.18-level*.03)
  end

  -- APK flow: reaching the end of the current level stops the action, shows
  -- the original LEVEL CLEARED artwork, and then opens the built-in store.
  -- We do not advance the level until the player leaves the store.
  local reachedLevelEnd=(player.x>=WORLD_END-70)
  if reachedLevelEnd and not levelClearPending then
    -- No new enemies are created once the cowboy reaches the end of the road.
    spawnClock=9999
    for i=#enemies,1,-1 do table.remove(enemies,i) end
    bullets={}
    loot={}
    boss=nil
    levelClearPending=true
    levelClearTimer=1.55
  elseif not levelClearPending and kills>=15*level then
    -- Compatibility fallback for builds/tests that finish the wave before the road end.
    levelClearPending=true
    levelClearTimer=1.55
    spawnClock=9999
    for i=#enemies,1,-1 do table.remove(enemies,i) end
    bullets={}
    loot={}
    boss=nil
  end
  if levelClearPending then
    levelClearTimer=math.max(0,levelClearTimer-dt)
    if levelClearTimer<=0 and state=="playing" then
      beginStore()
    end
  end

  for i=#bullets,1,-1 do
    local b=bullets[i]
    b.x=b.x+b.vx*dt
    b.y=b.y+(b.vy or 0)*dt
    b.life=b.life-dt
    b.frameT=(b.frameT or 0)+dt
    local remove=b.life<=0
    if not remove and not b.enemy then
      for j=#enemies,1,-1 do
        local e=enemies[j]
        if (b.x-e.x)^2+(b.y-e.y)^2<1700 then
          e.hp=e.hp-b.dmg
          e.hitFlash=.16
          e.attackPhase=0
          if e.hp>0 and math.random()<.18 then e.specialT=.30 end
          addFx(e.x,e.y,2,(#anim.enemyBloodAlt>0 and anim.enemyBloodAlt[math.random(#anim.enemyBloodAlt)] or anim.enemyBlood),.42,.9)
          playEvent("hit",0.65)
          if e.hp<=0 then killEnemy(e,b.owner or 0) end
          if (b.pierce or 0)>0 then b.pierce=b.pierce-1 else remove=true end
          if remove then break end
        end
      end
      if boss and not remove and (b.x-boss.x)^2+(b.y-boss.y)^2<3200 then
        boss.hp=boss.hp-b.dmg
        boss.hitFlash=.12
        if anim.bossBlood and #anim.bossBlood>0 then addFx(boss.x+math.random(-35,35),boss.y-35+math.random(-20,25),2,{anim.bossBlood[math.random(#anim.bossBlood)]},.24,.6) end
        addFx(boss.x,boss.y,2)
        remove=true
        if boss.hp<=0 then money=money+100;boss=nil;playExplosion(0.95) end
      end
    end
    if remove then table.remove(bullets,i) end
  end

  -- Enemy AI reconstructed from the APK screenshots: aliens do NOT fire.
  -- They close the distance, play the original 020x attack frames and bite/slash
  -- the cowboy at point blank range.  The hit produces the original blood animation.
  for _,e in ipairs(enemies) do
    e.hitFlash=math.max(0,(e.hitFlash or 0)-dt)
    e.specialT=math.max(0,(e.specialT or 0)-dt)
    if (e.spawnT or 0)>0 then
      e.spawnT=math.max(0,e.spawnT-dt)
      e.attackPhase=0
      e.attackCd=math.max(e.attackCd,0.55)
    end
    if e.dead then
      e.deathT=(e.deathT or 0)+dt
    elseif e.attackPhase and e.attackPhase>0 then
      e.attackPhase=e.attackPhase+dt
      -- Damage lands late in the 4-frame attack, not immediately when the alien touches.
      if e.attackPhase>=.34 and not e.attackHit then
        local dist=math.abs(player.x-e.x)
        if dist<82 and not player.dead then
          e.attackHit=true
          local dmg=e.damage or (10+e.typ*2)
          player.hp=math.max(0,player.hp-dmg)
          player.hitFlash=.22
          player.hurtKick=(player.x>=e.x and 1 or -1)*12
          setPlayerAction("hurt",.22)
          local bloodSet=anim.playerBlood or {}
          if #bloodSet>0 then
            addFx(player.x+(player.x>=e.x and -7 or 7),player.y-30,3,bloodSet,.48,.92)
          end
          playEnemyEvent(e,"damage",.82)
          if player.hp<=0 then
            player.hp=0
            player.dead=true
            lives=math.max(0,lives-1)
            playerDeathTimer=.72
            playEvent("death",.9)
          end
        end
      end
      if e.attackPhase>=.52 then
        e.attackPhase=0
        e.attackKind=nil
        e.attackHit=false
        e.attackCd=1.05+math.random()*1.15-math.min(.25,(e.levelTier or 0)*.04)
      end
    elseif (e.spawnT or 0)<=0 and e.attackCd<=0 then
      local dist=math.abs(player.x-e.x)
      if dist<84 and not player.dead then
        e.attackPhase=.001
        e.attackKind="melee"
        e.attackHit=false
        e.attack=0
        playEnemyEvent(e,"attack",.58)
      else
        e.attackCd=.22
      end
    end
  end

  for i=#enemies,1,-1 do
    local e=enemies[i]
    e.t=e.t+dt;e.anim=e.anim+dt
    if e.dead then
      if e.deathT>=.62 then
        kills=kills+1
        if e.killer==1 and remotePlayer then
          remotePlayer.kills=(remotePlayer.kills or 0)+1
          remoteMoney=remoteMoney+10
        else
          money=money+10
        end
        local roll=math.random()
        if roll<.22 then
          loot[#loot+1]={x=e.x,y=e.y,t=6,kind="diamond",vy=-20}
        elseif roll<.42 then
          loot[#loot+1]={x=e.x+math.random(-10,10),y=e.y,t=6,kind="ammo",amount=8+e.typ*3,vy=-16}
        elseif roll<.58 then
          loot[#loot+1]={x=e.x+math.random(-10,10),y=e.y,t=6,kind="cash",amount=10+e.typ*5,vy=-12}
        end
        local g=e.typ==1 and anim.aGib or e.typ==2 and anim.bGib or anim.cGib
        if g and #g>0 then
          for _,im in ipairs(g) do
            fx[#fx+1]={x=e.x+math.random(-12,12),y=e.y-25+math.random(-18,8),t=.55,maxT=.55,kind=9,frames={im},scale=1,frameT=0,frame=0,vx=math.random(-35,35),vy=math.random(-70,-25)}
          end
        end
        if math.random()<.35 then playExplosion(0.55) end
        table.remove(enemies,i)
      end
    else
      if (e.spawnT or 0)>0 then
        e.x=e.x
      elseif e.attackPhase and e.attackPhase>0 then
        e.x=e.x
      else
        local toward=(player.x>e.x and 1 or -1)
        e.x=e.x+toward*e.spd*dt
      end
      e.y=PLAYER_GROUND_Y+math.sin(e.t*3)*.08
      e.attack=e.attack+dt
      if e.x<-90 or e.x>WORLD_W+90 then
        table.remove(enemies,i)
      end
    end
  end

  -- No alien projectiles: the APK aliens are melee-only.

  if boss then
    boss.t=boss.t+dt
    boss.hitFlash=math.max(0,(boss.hitFlash or 0)-dt)
    boss.fire=boss.fire-dt
    boss.stone=math.max(0,(boss.stone or 0)-dt)
    local dx=player.x-boss.x
    boss.face=dx<0 and -1 or 1
    if math.abs(dx)>150 then boss.x=boss.x+(dx>0 and 1 or -1)*10*dt end
    if boss.fire<=0 then
      boss.fire=1.7
      boss.phase=.001
      boss.stone=0.28
    end
    if boss.phase>0 then
      boss.phase=boss.phase+dt
      if boss.phase>=.34 then
        local dir=player.x>=boss.x and 1 or -1
        bullets[#bullets+1]={x=boss.x+dir*52,y=boss.y-55,vx=dir*230,vy=(player.y-boss.y)*.08,life=2.3,dmg=12,enemy=true,kind="boss",frameT=0}
        addFx(boss.x+dir*50,boss.y-48,4,anim.muzzle,.18,.8)
        for _,im in ipairs(anim.bossDust or {}) do addFx(boss.x+math.random(-45,45),boss.y+math.random(0,18),13,{im},.32,.55) end
        playEvent("boss",.88)
        boss.phase=0
      end
    end
  end

  for i=#fx,1,-1 do
    local p=fx[i]
    p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.t=p.t-dt; p.frameT=p.frameT+dt
    if p.frames and #p.frames>0 then p.frame=math.floor((p.frameT/(p.maxT/#p.frames))) end
    if p.t<=0 then table.remove(fx,i) end
  end

  if net and net.isHost and net.isHost() then
    netSendClock=netSendClock-dt
    if netSendClock<=0 then
      local s={"3",tostring(level),string.format("P,0,%.1f,%.1f,%d,%d,%d,%d,%d,%d",player.x,player.y,player.face,player.hp,player.weapon,kills,ammo,money,diamonds)}
      if remotePlayer then
        s[#s+1]=string.format("P,1,%.1f,%.1f,%d,%d,%d,%d,%d,%d",remotePlayer.x,remotePlayer.y,remotePlayer.face,remotePlayer.hp or 100,remotePlayer.weapon or 1,remotePlayer.kills or 0,remoteAmmo,remoteMoney,remoteDiamonds)
      end
      for _,e in ipairs(enemies) do
        s[#s+1]=string.format("E,%d,%.1f,%.1f,%d,%d",e.typ,e.x,e.y,e.hp,e.dead and 1 or 0)
      end
      for _,b in ipairs(bullets) do
        if not b.enemy then s[#s+1]=string.format("B,%.1f,%.1f,%.1f",b.x,b.y,b.vx) end
      end
      net.broadcast(table.concat(s,";"))
      netSendClock=0.05
    end
  end
end

function M.load()
  love.graphics.setDefaultFilter("linear","linear")
  font12=love.graphics.newFont(12);font16=love.graphics.newFont(16);font22=love.graphics.newFont(22)
  loadDir("assets/images",images,love.graphics.newImage)
  loadDir("assets/ui",ui,love.graphics.newImage)
  loadDir("assets/audio",audio,function(p)return love.audio.newSource(p,"static")end)
  for _,src in pairs(audio) do pcall(src.setVolume,src,0.9) end
  local function direct(path)
    local ok,im=pcall(love.graphics.newImage,path)
    return ok and im or nil
  end
  bg=direct("assets/ui/scr_gamelayer00.png") or img("scr_gamelayer00.png")
  menubg=direct("assets/ui/scr_menuback.png") or img("scr_menuback.png")
  logo=direct("assets/ui/act_menu0100.png") or img("act_menu0100.png")
  gameover=direct("assets/ui/act_gameover00.png") or img("act_gameover00.png")
  -- Exact building from the reference screenshots: C set + closed C door.
  anim.house={
    img("act_house_c00.PNG"),img("act_house_c01.PNG"),img("act_house_c02.PNG")
  }
  anim.houseDoor=frames("act_house_door_c")
  anim.houseDoorA=frames("act_house_door_a")
  anim.houseDoorB=frames("act_house_door_b")

  anim.player=frames("act_main_pistol_l")
  anim.playerBody=frames("act_main_l_000")
  anim.playerGun=frames("act_gun00_l_000")
  anim.playerGuns={}
  anim.playerGunFire={}
  anim.playerGunAlt={}
  for _,g in ipairs({"00","01","02","03","04","05","06","07","08","0c"}) do
    anim.playerGuns[#anim.playerGuns+1]=frames("act_gun"..g.."_l_000")
    anim.playerGunFire[#anim.playerGunFire+1]=frames("act_gun"..g.."_l_010")
    anim.playerGunAlt[#anim.playerGunAlt+1]=frames("act_gun"..g.."_l_020")
  end
  anim.a=frames("act_npca_l_000")
  anim.b=frames("act_npcb_l_000")
  anim.c=frames("act_npcc_l_000")
  anim.aR=frames("act_npca_r_000")
  anim.bR=frames("act_npcb_r_000")
  anim.cR=frames("act_npcc_r_000")
  anim.aAttack=frames("act_npca_l_020")
  anim.bAttack=frames("act_npcb_l_020")
  anim.cAttack=frames("act_npcc_l_020")
  anim.aAttackR=frames("act_npca_r_020")
  anim.bAttackR=frames("act_npcb_r_020")
  anim.cAttackR=frames("act_npcc_r_020")
  anim.aHurt=frames("act_npca_l_010")
  anim.bHurt=frames("act_npcb_l_010")
  anim.cHurt=frames("act_npcc_l_010")
  anim.aHurtR=frames("act_npca_r_010")
  anim.bHurtR=frames("act_npcb_r_010")
  anim.cHurtR=frames("act_npcc_r_010")
  anim.aDeath=frames("act_npca_l_030")
  anim.bDeath=frames("act_npcb_l_030")
  anim.cDeath=frames("act_npcc_l_030")
  anim.aGib=frames("act_npca_l_040")
  anim.bGib=frames("act_npcb_l_040")
  anim.cGib=frames("act_npcc_l_040")
  anim.aSpecial=frames("act_npca_l_050")
  anim.bSpecial=frames("act_npcb_l_050")
  anim.cSpecial=frames("act_npcc_l_050")
  anim.aSpecialR=frames("act_npca_r_050")
  anim.bSpecialR=frames("act_npcb_r_050")
  anim.cSpecialR=frames("act_npcc_r_050")
  anim.npcShadow=img("act_npcshadow00.PNG")
  anim.halo=img("act_halo00.PNG")
  for _,typ in ipairs({"a","b","c"}) do
    anim[typ.."Tail"]={}
    for _,side in ipairs({"l","r"}) do
      anim[typ.."Tail"..side:upper()]= {
        idle=frames("act_npctail"..typ.."_"..side.."_000"),
        hurt=frames("act_npctail"..typ.."_"..side.."_010"),
        attack=frames("act_npctail"..typ.."_"..side.."_020"),
        death=frames("act_npctail"..typ.."_"..side.."_030"),
        gib=frames("act_npctail"..typ.."_"..side.."_040"),
        special=frames("act_npctail"..typ.."_"..side.."_050")
      }
    end
  end
  anim.laser=frames("act_laser")
  anim.gunLightning=frames("act_gunlignting_l")
  anim.chopper={frames("act_chopper00_l"),frames("act_chopper01_l"),frames("act_chopper02_l")}
  anim.fireball=frames("act_fireball01")
  anim.playerShoot=frames("act_main_l_01")
  anim.playerDeath=frames("act_main_l_050")
  anim.playerMelee=frames("act_main_l_020")
  anim.playerAction3=frames("act_main_l_030")
  anim.playerAction4=frames("act_main_l_040")
  anim.playerAction6=frames("act_main_l_060")
  anim.playerMeleeR=frames("act_main_r_020")
  anim.playerAction3R=frames("act_main_r_030")
  anim.playerAction4R=frames("act_main_r_040")
  anim.playerAction6R=frames("act_main_r_060")
  anim.playerGun=frames("act_gun00_l_000")
  anim.playerArmIdle=frames("act_leadarm_l_000")
  anim.playerArm=frames("act_leadarm_l_010")
  anim.playerArmMelee=frames("act_leadarm_l_020")
  anim.muzzle=frames("act_gunlignting_l")
  anim.shell=frames("act_shell")
  anim.enemyBlood=frames("act_bloode1")
  anim.enemyBloodAlt={frames("act_bloode2"),frames("act_bloodb"),frames("act_bloodc"),frames("act_bloodd"),frames("act_bloodf")}
  anim.enemyBloodBig=frames("act_bloodf")
  anim.playerBlood=frames("act_blooda1")
  anim.bossBody={img("act_boss0001.PNG"),img("act_boss0001.PNG")}
  anim.bossDust=frames("act_boss00_dust")
  anim.bossBlood=frames("act_boss00blood")
  anim.bossStone=frames("act_boss00stone")
  anim.roadA={img("act_road_a00.PNG"),img("act_road_a01.PNG"),img("act_road_a02.PNG"),img("act_road_a03.PNG")}
  anim.roadB={img("act_road_b00.PNG"),img("act_road_b01.PNG")}
  anim.roadDecor={img("act_road_a04.PNG"),img("act_road_a05.PNG"),img("act_road_a06.PNG"),img("act_road_a07.PNG"),img("act_road_b02.PNG"),img("act_road_b03.PNG"),img("act_road_b04.PNG"),img("act_road_b05.PNG")}
  anim.mounds={img("act_mound00.PNG"),img("act_mound01.PNG"),img("act_mound02.PNG"),img("act_mound03.PNG"),img("act_mound04.PNG")}
  anim.lighting={a={img("act_lighting_a00.PNG"),img("act_lighting_a01.PNG"),img("act_lighting_a02.PNG")},b={img("act_lighting_b00.PNG"),img("act_lighting_b01.PNG")},c={img("act_lighting_c00.PNG"),img("act_lighting_c01.PNG"),img("act_lighting_c02.PNG")}}

  -- Weapon families are the actual APK gun groups (00,01,02,03,04,05,06,07,08,0c).
  -- Their visual identity comes from the original sprites; the timings below keep the
  -- gameplay distinct without replacing any original artwork.
  weapons={
    {name="Pistol",        damage=1,speed=500,cooldown=.28,burst=1,sound="zm_sfx00.ogg",kind="bullet"},
    {name="Gold Pistol",   damage=2,speed=560,cooldown=.31,burst=1,sound="zm_sfx03.ogg",kind="bullet"},
    {name="Twin Shot",     damage=2,speed=540,cooldown=.38,burst=2,spread=.022,sound="zm_sfx12.ogg",kind="pellet",life=.9},
    {name="Shotgun",       damage=3,speed=510,cooldown=.58,burst=4,spread=.055,sound="zm_sfx13.ogg",kind="pellet",life=.8},
    {name="Heavy Shotgun", damage=4,speed=560,cooldown=.62,burst=3,spread=.04,sound="zm_sfx14.ogg",kind="heavy",life=1.0},
    {name="Alien Rifle",   damage=3,speed=690,cooldown=.20,burst=1,sound="zm_sfx15.ogg",kind="bullet"},
    {name="Assault Rifle", damage=3,speed=720,cooldown=.14,burst=1,sound="zm_sfx16.ogg",kind="bullet"},
    {name="Minigun",       damage=2,speed=760,cooldown=.085,burst=1,sound="zm_sfx17.ogg",kind="bullet"},
    {name="Plasma",        damage=7,speed=860,cooldown=.25,burst=1,sound="zm_sfx0f.ogg",kind="laser",life=1.45,pierce=1},
    {name="Laser",         damage=10,speed=980,cooldown=.42,burst=1,sound="zm_sfx19.ogg",kind="laser",life=1.35,pierce=2},
  }
  weaponPrices={0,40,80,120,180,260,360,500,700,900}
  buildStoreItems()
end

function storeItemsCount() return 17 end
syncStoreScroll=function()
  -- The original shelf is 1104px wide. The logical gameplay viewport is 576px,
  -- so the shelf itself scrolls while the selected object remains in the center.
  local first=math.max(1,math.min(storeCursor-7,10))
  storeScroll=(first-1)*100
end

function M.update(dt,net)
  if state=="playing" then
    updateWorld(dt,net)
    updateMusic("game")
  elseif state=="store" then
    updateMusic("menu")
    updateStore(dt)
  elseif state=="menu" or state=="settings" or state=="lan" then
    updateMusic("menu")
  elseif state=="pause" then
    -- Pause keeps the stage music stopped, matching the original pause overlay.
    updateMusic(nil)
  elseif state=="gameover" then
    updateMusic(nil)
  end
  for i=#loot,1,-1 do
    local q=loot[i]; q.t=q.t-dt
    if q.t<=0 then table.remove(loot,i) end
  end
end

function drawWorld()
  love.graphics.setColor(1,1,1,1)

  -- Parallax sky: the moon/cloud layer drifts more slowly than the road, as in the
  -- reference photos where the player remains centered while the buildings slide.
  if bg then
    local par=camX*0.12
    local bw,bh=bg:getWidth(),bg:getHeight()
    for x=-bw*2-par,bw*2-par,bw do
      love.graphics.draw(bg,x,0,0,W/bw,245/bh)
    end
  else
    love.graphics.setColor(.06,.05,.14,1);love.graphics.rectangle('fill',0,0,W,245)
  end

  local function sx(x) return x-camX end

  -- Buildings are placed as complete original sprite sets in world space.
  -- The first encounter matches photo 1 (the grey C building), while the next
  -- encounter matches photo 2 (the purple PUB A building). A B building follows
  -- farther into the level so the world does not repeat the same facade.
  local buildings={
    {x=BUILDING_X,kind="c"},
    {x=820,kind="a"},
    {x=1330,kind="b"},
  }
  local tip=img('act_housetip00.PNG'); local arrow=img('act_housetip01.PNG')
  local function doorFrame(kind)
    local t=buildingOpen[kind] or 0
    local set=(kind=="c" and anim.houseDoor) or (kind=="a" and anim.houseDoorA) or anim.houseDoorB
    if not set or #set==0 then return nil end
    local progress=math.max(0,math.min(1,t/.36))
    local idx=math.min(#set,math.floor((1-progress)*(#set-1))+1)
    return set[idx]
  end
  for _,bd in ipairs(buildings) do
    local bx=bd.x
    if bd.kind=="c" then
      local h0,h1,h2=img('act_house_c00.PNG'),img('act_house_c01.PNG'),img('act_house_c02.PNG')
      if h0 then love.graphics.draw(h0,sx(bx-76),CAL.cBuilding.c00y) end
      if h1 then love.graphics.draw(h1,sx(bx),CAL.cBuilding.c01y) end
      if h2 then love.graphics.draw(h2,sx(bx+192),CAL.cBuilding.c02y) end
      local lc=anim.lighting.c
      if lc[1] then love.graphics.draw(lc[1],sx(bx+20),158) end
      if lc[3] then love.graphics.draw(lc[3],sx(bx+164),158) end
      if (buildingOpen.c or 0)>0 and lc[2] then love.graphics.draw(lc[2],sx(bx+58),92) end
      local door=doorFrame("c")
      if door then love.graphics.draw(door,sx(CAL.cBuilding.doorX),CAL.cBuilding.doorY) end
      local doorCenter=CAL.cBuilding.doorX+39
      if math.abs(player.x-doorCenter)<88 then
        if tip then love.graphics.draw(tip,sx(CAL.cTip.x),CAL.cTip.y) end
        if arrow then love.graphics.draw(arrow,sx(CAL.cArrow.x),CAL.cArrow.y) end
      end
    elseif bd.kind=="a" then
      local h0,h1,h2=img('act_house_a00.PNG'),img('act_house_a01.PNG'),img('act_house_a02.PNG')
      if h0 then love.graphics.draw(h0,sx(bx),8) end
      if h1 then love.graphics.draw(h1,sx(bx-17),125) end
      if h2 then love.graphics.draw(h2,sx(bx-40),207) end
      local la=anim.lighting.a
      if la[1] then love.graphics.draw(la[1],sx(bx+35),159) end
      if la[3] then love.graphics.draw(la[3],sx(bx+185),159) end
      if (buildingOpen.a or 0)>0 and la[2] then love.graphics.draw(la[2],sx(bx+82),84) end
      local door=doorFrame("a")
      if door then love.graphics.draw(door,sx(bx+108),136) end
      local doorCenter=bx+150
      if math.abs(player.x-doorCenter)<92 then
        if tip then love.graphics.draw(tip,sx(bx+CAL.aTipOffsetX),CAL.aTipY) end
        if arrow then love.graphics.draw(arrow,sx(bx+CAL.aArrowOffsetX),CAL.aArrowY) end
      end
    else
      local h0,h1,h2=img('act_house_b00.PNG'),img('act_house_b01.PNG'),img('act_house_b02.PNG')
      if h0 then love.graphics.draw(h0,sx(bx),95) end
      if h1 then love.graphics.draw(h1,sx(bx-8),160) end
      if h2 then love.graphics.draw(h2,sx(bx+338),235) end
      local lb=anim.lighting.b
      if lb[1] then love.graphics.draw(lb[1],sx(bx+44),148) end
      if lb[1] then love.graphics.draw(lb[1],sx(bx+180),148) end
      if (buildingOpen.b or 0)>0 and lb[2] then love.graphics.draw(lb[2],sx(bx+85),112) end
      local door=doorFrame("b")
      if door then love.graphics.draw(door,sx(bx+135),130) end
    end
  end
  -- Original road layers: top seam + alternating 68px slabs, then sparse foreground decorations.
  local roadTop=img("act_road_a00.PNG")
  local roadAlt=img("act_road_a01.PNG") or img("act_road_b01.PNG")
  local road1=img("act_road_a02.PNG")
  local road2=img("act_road_a03.PNG")
  if roadTop then
    local rw=roadTop:getWidth()
    local first=-((camX%rw)+rw)
    for x=first,W+rw,rw do love.graphics.draw(roadTop,x,ROAD_Y) end
  end
  if roadAlt then
    local rw=roadAlt:getWidth()
    local first=-((camX%rw)+rw)
    for x=first,W+rw,rw do love.graphics.draw(roadAlt,x,ROAD_Y+1) end
  end
  if road1 and road2 then
    local rw=road1:getWidth()
    local first=-((camX%(rw*2))+rw*2)
    local idx=0
    for x=first,W+rw,rw do love.graphics.draw(idx%2==0 and road1 or road2,x,ROAD_DETAIL_Y); idx=idx+1 end
  elseif road1 then
    local rw=road1:getWidth()
    for x=-rw,W+rw,rw do love.graphics.draw(road1,x,ROAD_DETAIL_Y) end
  end

  -- Foreground props are world-anchored so they move with the buildings, not with the HUD.
  local props={
    {x=CAL.cactus.x,im=img("act_road_a04.PNG"),y=CAL.cactus.y},{x=170,im=img("act_road_a05.PNG"),y=217},
    {x=285,im=img("act_road_a06.PNG"),y=223},{x=520,im=img("act_road_a07.PNG"),y=282},
    {x=700,im=img("act_road_b02.PNG"),y=215},{x=930,im=img("act_road_b03.PNG"),y=221},
    {x=1110,im=img("act_road_b04.PNG"),y=218},{x=1500,im=img("act_road_b05.PNG"),y=282}
  }
  for _,pr in ipairs(props) do
    if pr.im then
      local px=sx(pr.x)
      if px>-140 and px<W+140 then love.graphics.draw(pr.im,px,pr.y) end
    end
  end
  local moundList={{x=355,i=1},{x=610,i=2},{x=1010,i=3},{x=1250,i=4},{x=1620,i=5}}
  for _,m in ipairs(moundList) do
    local im=anim.mounds[m.i]
    if im then love.graphics.draw(im,sx(m.x),281) end
  end

  -- Enemy projectiles use the APK's fireball frames: a flame while flying and
  -- the three original impact rings when the shot reaches the player.
  for _,b in ipairs(bullets) do
    if b.enemy then
      local dir=b.vx<0 and -1 or 1
      if b.kind=="boss" and anim.bossStone and #anim.bossStone>0 then
        local stone=anim.bossStone[(math.floor((b.frameT or 0)*8)%#anim.bossStone)+1]
        if stone then drawSprite(stone,sx(b.x),b.y,dir<0,.55) end
      else
        local ex=img("act_fireball0000.PNG")
        if ex then
          local pulse=.58+.08*math.sin((b.frameT or 0)*22)
          drawSprite(ex,sx(b.x),b.y,dir<0,pulse)
        end
      end

    end
  end

  -- Actors share the same road baseline.  Shadows and the complete original
  -- action families are drawn here so the aliens no longer look like a single
  -- static sprite.
  for _,e in ipairs(enemies) do
    local spawnP=1-math.max(0,math.min(1,(e.spawnT or 0)/(e.spawnDuration or ALIEN_SPAWN_DURATION)))
    -- Ease-out rise: the body starts under the road and settles onto the baseline.
    local eased=1-(1-spawnP)*(1-spawnP)
    local drawY=e.y+(1-eased)*ALIEN_SPAWN_DEPTH
    local ex=sx(e.x)
    if (e.spawnT or 0)>0 and anim.halo then
      local sp=math.max(0,math.min(1,1-(e.spawnT/(e.spawnDuration or ALIEN_SPAWN_DURATION))))
      local haloScale=.45+.55*sp
      love.graphics.setColor(1,1,1,.9*(1-.35*sp))
      drawSprite(anim.halo,ex,e.y+7,false,haloScale)
      love.graphics.setColor(1,1,1,1)
    end
    if anim.npcShadow then
      love.graphics.setColor(1,1,1,0.82)
      love.graphics.draw(anim.npcShadow,ex,drawY+8,0,0.82,0.55,anim.npcShadow:getWidth()/2,anim.npcShadow:getHeight()/2)
    else
      love.graphics.setColor(0,0,0,.18)
      love.graphics.ellipse("fill",ex,drawY+4,24,5)
    end
    love.graphics.setColor(1,1,1,1)
    local facingRight=e.x<player.x
    local aa=(e.typ==1 and (facingRight and anim.aR or anim.a)) or (e.typ==2 and (facingRight and anim.bR or anim.b)) or (facingRight and anim.cR or anim.c)
    local body
    if e.dead then
      local ds=e.typ==1 and anim.aDeath or e.typ==2 and anim.bDeath or anim.cDeath
      body=pick(ds,e.deathT,10)
    elseif (e.specialT or 0)>0 then
      local ds=(e.typ==1 and (facingRight and anim.aSpecialR or anim.aSpecial)) or (e.typ==2 and (facingRight and anim.bSpecialR or anim.bSpecial)) or (facingRight and anim.cSpecialR or anim.cSpecial)
      body=pick(ds,.30-(e.specialT or 0),8) or pick(aa,e.anim,8)
    elseif e.attackPhase and e.attackPhase>0 then
      local ds=(e.typ==1 and (facingRight and anim.aAttackR or anim.aAttack)) or (e.typ==2 and (facingRight and anim.bAttackR or anim.bAttack)) or (facingRight and anim.cAttackR or anim.cAttack)
      body=pick(ds,e.attackPhase,8)
    elseif e.hitFlash and e.hitFlash>0 then
      local ds=(e.typ==1 and (facingRight and anim.aHurtR or anim.aHurt)) or (e.typ==2 and (facingRight and anim.bHurtR or anim.bHurt)) or (facingRight and anim.cHurtR or anim.cHurt)
      body=pick(ds,.16-(e.hitFlash or 0),10) or pick(aa,e.anim,8)
    else
      body=pick(aa,e.anim,8)
    end
    if e.hitFlash and e.hitFlash>0 then love.graphics.setColor(1,.35,.35,1) end
    local key=e.typ==1 and "a" or e.typ==2 and "b" or "c"
    local sideKey=facingRight and "R" or "L"
    local tailSet=anim[key.."Tail"..sideKey]
    local tailState="idle"
    if e.dead then tailState="death" elseif e.attackPhase and e.attackPhase>0 then tailState="attack" elseif e.hitFlash and e.hitFlash>0 then tailState="hurt" elseif e.specialT and e.specialT>0 then tailState="special" end
    local tail=tailSet and tailSet[tailState] or nil
    local bodyFlip=false
    -- The APK ships explicit L/R body and tail families. v36 selected the right
    -- family and then mirrored it again, which reversed the alien and separated
    -- the tail. Keep the source orientation and attach the tail at the rear hip.
    if (e.spawnT or 0)>0 then love.graphics.setScissor(0,0,W,ROAD_Y+1) end
    if tail and #tail>0 then
      local tailX=ex+(facingRight and -15 or 15)
      local tailY=drawY+15
      drawSprite(pick(tail,e.anim,10),tailX,tailY,false,1)
    end
    drawSprite(body,ex,drawY,bodyFlip,1)
    if (e.spawnT or 0)>0 then love.graphics.setScissor() end
    love.graphics.setColor(1,1,1,1)
    if not e.dead then
      drawHealthBar(ex-34,drawY-85,e.hp,e.maxhp)
    end
  end

  local psx=sx(player.x)
  love.graphics.setColor(1,1,1,1)
  local body
  -- The APK has a dedicated pistol stance containing the correctly assembled
  -- cowboy. Do not add leadarm on top of it: leadarm is a detached overlay used
  -- by the original renderer and was the source of the floating arm in v36.
  if player.dead then
    body=pick(anim.playerDeath,playerDeathTimer and (.72-playerDeathTimer) or 0,10)
  elseif playerAction=="melee" then
    local set=player.face>0 and anim.playerMelee or anim.playerMelee
    body=pick(set,.48-player.meleeCd,12) or img('act_main_l_0200.PNG')
  elseif playerAction=="hurt" then
    body=pick(anim.playerAction4,.22-playerActionT,10) or img('act_main_l_0000.PNG')
  elseif player.weapon==1 and not player.walking then
    body=pick(anim.player,.0+player.anim,8) or img('act_main_pistol_l00.PNG')
  elseif player.walking then
    body=pick(anim.playerBody,player.anim,10)
  else
    body=img('act_main_l_0000.PNG')
  end
  if body then drawSprite(body,psx,player.y,player.face<0,1) end

  local gunIdle=anim.playerGuns[player.weapon] or anim.playerGun
  local gunFire=anim.playerGunFire[player.weapon] or gunIdle
  local gunSet=(player.shootAnim>0 and gunFire) or gunIdle
  local gun=not player.dead and (pick(gunSet,.20-player.shootAnim,12) or gunSet[1] or img('act_gun00_l_0000.PNG')) or nil
  if gun then
    -- Gun sprites already contain their forearm/hand. The measured attachment
    -- point keeps the hand on the cowboy's weapon grip without a second arm.
    local gunX=psx+player.face*20
    local gunY=player.y+25-(player.shootAnim>0 and 1 or 0)
    love.graphics.draw(gun,gunX,gunY,0,player.face,1,28,17)
  end

  if player.hitFlash and player.hitFlash>0 then
    love.graphics.setColor(1,.18,.18,.22)
    love.graphics.rectangle('fill',psx-40,player.y-70,80,85)
    love.graphics.setColor(1,1,1,1)
  end

  if remotePlayer then
    local rsx=sx(remotePlayer.x)
    local rb=(remotePlayer.shootAnim or 0)>0 and pick(anim.playerShoot,.2-(remotePlayer.shootAnim or 0),10) or (remotePlayer.walking and pick(anim.playerBody,remotePlayer.anim or 0,8) or img('act_main_l_0000.PNG'))
    if rb then drawSprite(rb,rsx,remotePlayer.y,remotePlayer.face<0,1) end
    local rarm=pick(anim.playerArm,(remotePlayer.shootAnim or 0)>0 and (.20-(remotePlayer.shootAnim or 0)) or (remotePlayer.anim or 0),10)
    if rarm then love.graphics.draw(rarm,rsx+remotePlayer.face*14,remotePlayer.y+8,0,remotePlayer.face,1,rarm:getWidth()/2,rarm:getHeight()/2) end
    local rgset=((remotePlayer.shootAnim or 0)>0 and anim.playerGunFire[remotePlayer.weapon or 1]) or anim.playerGuns[remotePlayer.weapon or 1] or anim.playerGun
    local rg=rgset and (pick(rgset,.2-(remotePlayer.shootAnim or 0),12) or rgset[1]) or img('act_gun00_l_0000.PNG')
    if rg then
      love.graphics.draw(rg,rsx+remotePlayer.face*14,remotePlayer.y+17,0,remotePlayer.face,1,45,27)
    end
    local rhp=remotePlayer.hp or 100
    love.graphics.setColor(1,1,1,1)
    local rx=math.floor(rsx+CAL.lifeOffsetX); local ry=remotePlayer.y+CAL.lifeOffsetY
    drawHealthBar(rx,ry,rhp,100)
  end

  for _,q in ipairs(loot) do
    local qx=sx(q.x)
    local bob=math.sin(love.timer.getTime()*7+q.x)*3
    if q.kind=="diamond" then
      local d=img('act_diamond01.PNG') or img('act_diamond00.PNG')
      if d then love.graphics.draw(d,qx-d:getWidth()/2,q.y-35+bob) end
    elseif q.kind=="ammo" then
      local names={"act_store0109.png","act_store010a.png","act_store010b.png","act_store010c.png"}
      local d=img(names[(q.ammoType or 1)])
      if d then love.graphics.draw(d,qx-d:getWidth()/2,q.y-32+bob,0,.58,.58) end
    elseif q.kind=="cash" then
      local d=img('act_num010a.PNG')
      if d then love.graphics.draw(d,qx-d:getWidth()/2,q.y-28+bob,0,.9,.9) end
    elseif q.kind=="weapon" then
      local icons={"act_weaponicon0000.PNG","act_weaponicon0001.PNG","act_weaponicon0004.PNG","act_weaponicon0006.PNG","act_weaponicon0002.PNG","act_weaponicon0003.PNG","act_weaponicon0005.PNG","act_weaponicon0007.PNG","act_weaponicon0008.PNG","act_weaponicon0009.PNG"}
      local d=img(icons[q.weapon or 1])
      if d then love.graphics.draw(d,qx-d:getWidth()/2,q.y-30+bob,0,.50,.50) end
    end
  end

  if boss then
    local bs=img("act_boss0000.PNG")
    if bs then love.graphics.setColor(1,1,1,.78); love.graphics.draw(bs,sx(boss.x),boss.y+35); love.graphics.setColor(1,1,1,1) end
    local bb=pick(anim.bossBody,boss.t,2) or img('act_boss0001.PNG')
    local pulse=1+math.sin(boss.t*5)*.015
    if boss.hitFlash and boss.hitFlash>0 then love.graphics.setColor(1,.35,.35,1) end
    drawSprite(bb,sx(boss.x),boss.y,boss.face<0,pulse)
    love.graphics.setColor(1,1,1,1)
    local barW=110
    love.graphics.setColor(0,0,0,.55); love.graphics.rectangle('fill',sx(boss.x)-barW/2,boss.y-150,barW,7)
    love.graphics.setColor(1,.18,.12,1); love.graphics.rectangle('fill',sx(boss.x)-barW/2,boss.y-150,barW*math.max(0,boss.hp/boss.maxhp),7)
    love.graphics.setColor(1,1,1,1)
  end

  for _,b in ipairs(bullets) do
    if not b.enemy then
      local wx=b.weapon or 1
      if wx==10 and anim.gunLightning and #anim.gunLightning>0 then
        local im=anim.gunLightning[(math.floor((b.frameT or 0)*18)%#anim.gunLightning)+1]
        if im then drawSprite(im,sx(b.x),b.y,b.vx<0,.48) end
      elseif wx==9 and anim.laser and #anim.laser>0 then
        local im=anim.laser[(math.floor((b.frameT or 0)*18)%#anim.laser)+1]
        if im then drawSprite(im,sx(b.x),b.y,b.vx<0,.48) end
      else
        love.graphics.setColor(1,1,.7,1)
        love.graphics.rectangle('fill',sx(b.x),b.y,9,2)
      end
    end
  end

  for _,p in ipairs(fx) do
    local aa=math.max(0,p.t/(p.maxT or .32))
    local px=sx(p.x)
    if p.frames and #p.frames>0 then
      local idx=math.min(#p.frames,(p.frame or 0)+1)
      local im=p.frames[idx]
      if im then drawSprite(im,px,p.y,false,p.scale or 1) end
    elseif p.kind==4 then
      love.graphics.setColor(1,.85,.25,aa); love.graphics.circle('fill',px,p.y,3+10*(1-aa))
    elseif p.kind==5 then
      love.graphics.setColor(1,.95,.45,aa); love.graphics.setLineWidth(4); love.graphics.line(px-8,p.y-8,px+8,p.y+8); love.graphics.line(px+8,p.y-8,px-8,p.y+8)
    else
      love.graphics.setColor(1,.22,.05,aa); love.graphics.circle('fill',px,p.y,3+8*(1-aa))
    end
  end
end
function drawHUD()
  love.graphics.setColor(1,1,1,1)

  if ui["act_menu040c.png"] then love.graphics.draw(ui["act_menu040c.png"],20,16,0,1.05,1.05) end

  local kill=img("act_num000e.PNG")
  if kill then love.graphics.draw(kill,20,70) end
  drawDigitString(69,70,kills,"act_num000",1,0)

  -- Ammo box: the original empty slot with the bullet and white count.
  local slot=img("act_weaponicon0008.PNG")
  if slot then love.graphics.draw(slot,510,7) end
  local weaponIcons={"act_weaponicon0000.PNG","act_weaponicon0001.PNG","act_weaponicon0004.PNG","act_weaponicon0006.PNG","act_weaponicon0002.PNG","act_weaponicon0003.PNG","act_weaponicon0005.PNG","act_weaponicon0007.PNG","act_weaponicon0008.PNG","act_weaponicon0009.PNG"}
  local bulletIcon=img(weaponIcons[player.weapon] or weaponIcons[1])
  if bulletIcon then love.graphics.draw(bulletIcon,519,12,0,.58,.58) end
  drawDigitString(546,40,ammo,"act_num000",.82,0)

  -- Player life bar: the APK uses the same 68x13 life strip above the cowboy
  -- and above enemies. It is intentionally visible in gameplay and in the tutorial.
  drawHealthBar(player.x-camX-34,player.y-85,player.hp,player.maxhp)

  -- Original dollar and diamond HUD.
  local dollar=img("act_num010a.PNG")
  if dollar then love.graphics.draw(dollar,510,68) end
  drawDigitString(540,68,money,"act_num010",1,0)

  local diamond=img("act_diamond01.PNG")
  if diamond then love.graphics.draw(diamond,540,98) end
  drawDigitString(570,99,diamonds,"act_num010",1,0)

  local cowboy=img("act_num000d.PNG")
  if cowboy then love.graphics.draw(cowboy,28,292) end
  drawDigitString(58,292,lives,"act_num000",1,0)
  local levelLabel=img("act_num000c.PNG")
  if levelLabel then love.graphics.draw(levelLabel,458,292) end
  drawDigitString(525,292,level,"act_num000",1,0)

  if levelClearTimer>0 then
    local gc=img("act_gamepass00.PNG")
    if gc then love.graphics.draw(gc,(W-gc:getWidth())/2,18) end
  end

  -- The APK ships the complete tutorial as act_help00.PNG. v28 uses that exact
  -- 576x320 artwork instead of reconstructing the red circles/text with fonts.

end
function drawControls()
  love.graphics.setColor(1,1,1,1)
  local function btn(normal,pressed,x,y)
    local im=(pressed and img(pressed)) or img(normal)
    if im then love.graphics.draw(im,x,y) end
  end
  btn("act_ctrlbtn00.PNG","act_ctrlbtn01.PNG",CAL.controls.leftX,CAL.controls.y)
  btn("act_ctrlbtn02.PNG","act_ctrlbtn03.PNG",CAL.controls.rightX,CAL.controls.y)
  btn("act_ctrlbtn06.PNG","act_ctrlbtn07.PNG",CAL.controls.meleeX,CAL.controls.y)
  btn("act_ctrlbtn04.PNG","act_ctrlbtn05.PNG",CAL.controls.fireX,CAL.controls.y)
  -- The APK also has two fire-button effect frames; keep them subtle while pressed.
  if touch.fire then
    local im=img("act_ctrlbtn0100.PNG") or img("act_ctrlbtn0101.PNG")
    if im then love.graphics.draw(im,510,258,0,.55,.55) end
  end
end
function drawMenu()
  love.graphics.setColor(1,1,1,1)
  if menubg then love.graphics.draw(menubg,0,0,0,W/menubg:getWidth(),H/menubg:getHeight())
  else love.graphics.clear(.015,.012,.02,1) end
  if logo then love.graphics.draw(logo,(W-logo:getWidth())/2,22) end
  local function center(name,y)
    local im=img(name); if im then love.graphics.draw(im,(W-im:getWidth())/2,y) end
  end
  center("act_menu0400.png",145)
  center("act_menu0402.png",190)
  center("act_menu0102.png",235)
  local gear=img("act_menu0404.png"); local help=img("act_menu0406.png")
  if gear then love.graphics.draw(gear,438,247) end
  if help then love.graphics.draw(help,505,247) end
end

function drawPause()
  drawWorld(); drawHUD(); drawControls()
  love.graphics.setColor(0,0,0,.42); love.graphics.rectangle("fill",0,0,W,H)
  love.graphics.setColor(1,1,1,1)
  local resume=img("act_menu0402.png"); local menu=img("act_menu040a.png")
  if resume then love.graphics.draw(resume,(W-resume:getWidth())/2,112) end
  if menu then love.graphics.draw(menu,(W-menu:getWidth())/2,162) end
  local gear=img("act_menu0404.png"); local help=img("act_menu0406.png")
  if gear then love.graphics.draw(gear,235,220) end
  if help then love.graphics.draw(help,300,220) end
end

function M.draw(net)
  -- The APK's extracted art is authored on a 576x320 scene, but its Android
  -- gameplay viewport is a wide 2400x1080-style native landscape aspect (the phone
  -- screenshots are ~2.22:1 after the system bars are removed).  v29 used a
  -- 1280x720 window, so Android had to stretch that scene vertically into a
  -- different target geometry.  v34 keeps the game logic at the original extracted 576x320 scene; Android handles the physical display surface.
  -- All game coordinates remain in the original 576x320 art space; only the
  -- final presentation scale changes.
  local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
  local scale=math.min(sw/W,sh/H)
  local offsetX=(sw-W*scale)*0.5
  local offsetY=(sh-H*scale)*0.5
  love.graphics.push()
  love.graphics.translate(offsetX,offsetY)
  love.graphics.scale(scale,scale)
  love.graphics.setColor(1,1,1,1)
  if state=="menu" then
    drawMenu()
  elseif state=="pause" then
    drawPause()
  elseif state=="settings" then
    if menubg then love.graphics.draw(menubg,0,0,0,W/menubg:getWidth(),H/menubg:getHeight()) end
    local st=img("act_menu0300.png"); if st then love.graphics.draw(st,(W-st:getWidth())/2,88) end
    local diff=img(difficulty==1 and "act_menu0301.png" or difficulty==2 and "act_menu0303.png" or "act_menu0302.png")
    if diff then love.graphics.draw(diff,(W-diff:getWidth())/2,145) end
    local dlabel=img("act_menu0304.png"); if dlabel then love.graphics.draw(dlabel,(W-dlabel:getWidth())/2,178) end
    local music=img("act_menu0305.png"); local sound=img("act_menu0306.png")
    if music then love.graphics.draw(music,145,215) end
    if sound then love.graphics.draw(sound,315,215) end
    local on=img("act_menu0307.png"); if on then love.graphics.draw(on,185,250) end
    local off=img("act_menu0308.png"); if off then love.graphics.draw(off,355,250) end
    local back=img("act_menu040a.png"); if back then love.graphics.draw(back,(W-back:getWidth())/2,282) end
  elseif state=="help" then
    local help=img("act_help00.PNG")
    if help then love.graphics.draw(help,0,0) else love.graphics.clear(0.05,0.05,0.08,1) end
  elseif state=="lan" then
    if menubg then love.graphics.draw(menubg,0,0,0,W/menubg:getWidth(),H/menubg:getHeight()) end
    if logo then love.graphics.draw(logo,(W-logo:getWidth())/2,8) end
    love.graphics.setFont(font22);love.graphics.printf("MULTIJUGADOR LAN",0,145,W,"center")
    love.graphics.setFont(font16);love.graphics.printf("H = HOST    J = JOIN",0,190,W,"center")
    love.graphics.printf("IP: "..ip,0,220,W,"center")
    love.graphics.setFont(font12);love.graphics.printf("ESC = volver",0,250,W,"center")
  elseif state=="store" then
    local sb=img("act_storebk00.PNG")
    if sb then
      love.graphics.draw(sb,-storeCamX,0)
    else
      love.graphics.clear(.04,.05,.08,1)
    end

    -- The APK store is an actual shelf, not a single centered preview.
    -- Keep its 1104x320 background and place the original item art in the
    -- eight visible price slots. Horizontal arrows cycle through the complete
    -- set of weapon + utility objects extracted from the APK.
    if #storeItems==0 then buildStoreItems() end
    local selected=storeItems[storeCursor] or storeItems[1]
    local first=math.max(1,math.min(storeCursor-7,10))
    for idx=first,math.min(#storeItems,first+7) do
      local item=storeItems[idx]
      local slotX=230+(idx-1)*100-storeCamX
      if slotX>-70 and slotX<W+70 then
        local im=img(item.img)
        if im then
          love.graphics.draw(im,slotX-im:getWidth()/2,76-im:getHeight()/2)
        end
        love.graphics.setFont(font12)
        love.graphics.printf("$"..item.price,slotX-32,108,64,"center")
        if idx==storeCursor then
          love.graphics.setLineWidth(3)
          love.graphics.rectangle("line",slotX-45,38,90,76)
          love.graphics.setLineWidth(1)
        end
      end
    end

    -- The cowboy physically enters the shop and remains there until the player
    -- walks all the way to the right exit. This is the level-to-store transition
    -- used by the original game flow instead of the v36 instant level advance.
    local storePx=storePlayer.x-storeCamX
    local storeBody=storePlayer.walking and pick(anim.playerBody,storePlayer.anim,10) or img('act_main_l_0000.PNG')
    if storeBody then drawSprite(storeBody,storePx,storePlayer.y,storePlayer.face<0,1) end
    love.graphics.setColor(1,1,1,1)

    -- Selected object / purchase behavior.
    local simg=img(selected.img)
    if simg then love.graphics.draw(simg,275-simg:getWidth()/2,170-simg:getHeight()/2,0,1.25,1.25) end
    love.graphics.setFont(font16)
    local label=selected.label or "OBJETO"
    love.graphics.printf(label,135,205,280,"center")
    local available=(selected.kind=="weapon" and weaponOwned(selected.id)) or (selected.kind=="melee" and meleeOwned>=selected.level)
    local buy=img((selected.price==0 or available) and "act_store000b.png" or "act_store000c.png")
    if buy then love.graphics.draw(buy,265,238) end
    love.graphics.setFont(font16)
    love.graphics.printf("DINERO: $"..tostring(money),15,285,180,"left")
    love.graphics.setFont(font12)
    love.graphics.printf("< > elegir   ENTER/TAP comprar   ABAJO continuar",320,292,240,"center")
  elseif state=="gameover" then
    drawWorld();drawHUD();drawControls()
    love.graphics.setColor(0,0,0,.5);love.graphics.rectangle("fill",0,0,W,H)
    if gameover then love.graphics.draw(gameover,123,78) end
    local died=img("act_gameover0100.png"); local cont=img("act_gameover0101.png"); local more=img("act_gameover0103.png")
    if died then love.graphics.draw(died,(W-died:getWidth())/2,135) end
    if cont then love.graphics.draw(cont,145,238) end
    if more then love.graphics.draw(more,355,240) end
  else
    drawWorld();drawHUD();drawControls()
    if state=="playing" and tutorialTimer>0 then
      local help=img("act_help00.PNG")
      if help then love.graphics.setColor(1,1,1,1); love.graphics.draw(help,0,0) end
    end
  end
  love.graphics.pop()
end

function M.keypressed(k,net)
  if tutorialTimer>0 and state=="playing" then tutorialTimer=0; tutorialSeen=true end
  if state=="pause" then
    if k=="return" or k=="space" then state="playing"; playClick(0.8)
    elseif k=="escape" then state="playing"
    elseif k=="o" then reset(); state="store"; playClick(0.8) end
  elseif state=="menu" then
    if k=="return" or k=="space" then reset(); playClick(0.8)
    elseif k=="s" then state="settings"; playClick(0.8)
    elseif k=="l" then state="lan"; playClick(0.8)
    elseif k=="o" then reset(); storeCursor=1; syncStoreScroll(); state="store"; playClick(0.8)
    elseif k=="h" then state="help"; playClick(0.8) end
  elseif state=="settings" then
    if k=="left" or k=="right" then difficulty=difficulty%3+1
    elseif k=="escape" then state="menu" end
  elseif state=="help" then
    if k=="escape" or k=="return" or k=="space" then state="menu" end
  elseif state=="lan" then
    if k=="h" then if net.host() then reset() end
    elseif k=="j" then if net.join(ip) then reset() end
    elseif k=="escape" then state="menu" end
  elseif state=="store" then
    if #storeItems==0 then buildStoreItems() end
    if k=="up" then storeCursor=math.max(1,storeCursor-8); syncStoreScroll()
    elseif k=="down" then storeCursor=math.min(#storeItems,storeCursor+8); syncStoreScroll()
    elseif k=="return" or k=="space" then
      purchaseStoreItem(storeCursor)
    end
  elseif state=="gameover" then
    if k=="return" or k=="space" then reset() elseif k=="escape" then state="menu" end
  elseif k=="escape" then state="pause"; playClick(0.8)
  elseif k>="1" and k<="9" then
    local wid=tonumber(k)
    if weaponOwned(wid) then player.weapon=wid; playEvent("weaponSwitch",0.35) else playEvent("damage",0.25) end
  elseif k=="0" then
    if weaponOwned(10) then player.weapon=10; playEvent("weaponSwitch",0.35) else playEvent("damage",0.25) end
  end
end

function enterBuilding()
  if state~="playing" or player.dead then return end
  local candidates={{x=BUILDING_X,kind="c",door=BUILDING_X+96},{x=820,kind="a",door=970},{x=1330,kind="b",door=1465}}
  local best=nil; local bestDist=9999
  for _,b in ipairs(candidates) do
    local d=math.abs(player.x-b.door)
    if d<bestDist then bestDist=d;best=b end
  end
  if best and bestDist<100 then
    activeBuildingKind=best.kind; activeBuildingX=best.x
    setPlayerAction("enter",.36)
    buildingOpen[best.kind]=.36
    buildingOpenT=.36
    tutorialTimer=0; tutorialSeen=true
    playClick(.75)
    playEvent("weaponSwitch",.55)
  end
end

function M.androidBack(net)
  if state == "pause" then
    state = "playing"
  elseif state == "menu" then
    love.event.quit()
  elseif state == "playing" or state == "settings" or state == "help" or state == "lan" or state == "store" then
    state = "menu"
  elseif state == "gameover" then
    state = "menu"
  end
end

function M.touchpressed(id,x,y,dx,dy,p,net)
  if tutorialTimer>0 and state=="playing" then tutorialTimer=0; tutorialSeen=true end
  local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
  local scale=math.min(sw/W,sh/H)
  local offsetX=(sw-W*scale)*0.5
  local offsetY=(sh-H*scale)*0.5
  x=(x-offsetX)/scale; y=(y-offsetY)/scale
  if x<0 or x>W or y<0 or y>H then return end
  if #storeItems==0 then buildStoreItems() end
  if state=="store" then
    if y<140 then
      local idx=math.floor((x+storeCamX-180)/100)+1
      if idx>=1 and idx<=#storeItems then
        storeCursor=idx
        syncStoreScroll(); playClick(.35)
      end
    elseif y>=215 and y<285 then
      purchaseStoreItem(storeCursor)
      playClick(.45)
    elseif x>500 and y>140 and y<215 then
      storeCursor=math.min(#storeItems,storeCursor+1); syncStoreScroll()
    end
  elseif state=="menu" then
    if y>140 and y<190 then reset(); playClick(0.8)
    elseif y>190 and y<235 then state="playing"; playClick(0.8)
    elseif y>235 and y<280 and x<420 then reset(); storeCursor=1; syncStoreScroll(); state="store"; playClick(0.8)
    elseif x>420 and y>235 then state="settings"; playClick(0.8) end
  elseif state=="pause" then
    if y>115 and y<165 then state="playing"; playClick(0.8)
    elseif y>165 and y<220 then state="menu"; playClick(0.8)
    elseif y>215 and x<300 then state="settings"; playClick(0.8) end
  elseif state=="settings" then
    if y>250 then state="menu" else difficulty=difficulty%3+1; playSfx("misc",0.7) end
  elseif state=="help" then
    state="menu"
  elseif state=="lan" then
    if y>225 then state="menu" end
  elseif state=="gameover" then
    if y>=225 and x<320 then reset() else state="menu" end
  elseif x<60 and y<55 then
    state="pause"; playClick(0.8)
  elseif x>455 and y<95 then
    local next=player.weapon
    for _=1,#weapons do
      next=next%#weapons+1
      if weaponOwned(next) then player.weapon=next; break end
    end
    playClick(0.45)
  elseif y>125 and y<270 and x>220 and x<410 then
    enterBuilding()
  elseif y>245 and x>=15 and x<105 then touch[id]="left";touch.left=true
  elseif y>245 and x>=105 and x<215 then touch[id]="right";touch.right=true
  elseif y>235 and x>=505 then touch[id]="fire";touch.fire=true
  elseif y>235 and x>=405 and x<505 then touch[id]="melee";touch.melee=true
  end
end

function M.touchreleased(id)
  local v=touch[id]
  if v then touch[v]=false end
  touch[id]=nil
end

function M.netReceive(data,peer)
  local p={}
  for s in data:gmatch("[^|]+") do p[#p+1]=s end
  if p[1]=="WELCOME" then
    M.netClientId=tonumber(p[2]) or 1
    return
  end
  if p[1]=="INPUT" and peer then
    remotePlayer=remotePlayer or {x=player.x+100,y=player.y,face=-1,hp=100,weapon=1,kills=0,walking=false,fireCd=0,meleeCd=0,anim=0}
    local incomingSeq=tonumber(p[2]) or 0
    if incomingSeq < (remoteInput.seq or 0) then return end
    remoteInput.seq=incomingSeq
    remoteInput.face=tonumber(p[5]) or remoteInput.face
    remotePlayer.face=remoteInput.face
    remoteInput.fire=tonumber(p[6])==1
    remoteInput.weapon=math.max(1,math.min(10,tonumber(p[7]) or 1))
    remoteInput.left=tonumber(p[8])==1
    remoteInput.right=tonumber(p[9])==1
    remoteInput.melee=tonumber(p[10])==1
    remotePlayer.weapon=remoteInput.weapon
    return
  end
  if p[1]=="SNAP" then
    local body=data:sub(6)
    local rem=nil
    local sharedEnemies={}
    local sharedBullets={}
    for line in body:gmatch("[^;]+") do
      local q={}
      for x in line:gmatch("[^,]+") do q[#q+1]=x end
      if q[1]=="P" and #q>=7 then
        local id=tonumber(q[2]) or 0
        local x=tonumber(q[3]) or 0
        local y=tonumber(q[4]) or 0
        local face=tonumber(q[5]) or 1
        local hp=tonumber(q[6]) or 100
        local weapon=tonumber(q[7]) or 1
        if id==0 then
          player.x=x; player.y=y; player.face=face; player.hp=hp; player.weapon=weapon
          kills=tonumber(q[8]) or kills; ammo=tonumber(q[9]) or ammo; money=tonumber(q[10]) or money; diamonds=tonumber(q[11]) or diamonds
        else
          rem={x=x,y=y,face=face,hp=hp,weapon=weapon,kills=tonumber(q[8]) or 0,t=love.timer.getTime(),ammo=tonumber(q[9]) or 75,money=tonumber(q[10]) or 0,diamonds=tonumber(q[11]) or 0}
        end
      elseif q[1]=="E" and #q>=5 then
        sharedEnemies[#sharedEnemies+1]={id=#sharedEnemies+1,typ=tonumber(q[2]) or 1,x=tonumber(q[3]) or 0,y=tonumber(q[4]) or 195,hp=tonumber(q[5]) or 1,maxhp=2,t=0,anim=love.timer.getTime(),dead=tonumber(q[6])==1,deathT=tonumber(q[6])==1 and .35 or 0,attackPhase=0,hitFlash=0}
      elseif q[1]=="B" and #q>=4 then
        sharedBullets[#sharedBullets+1]={x=tonumber(q[2]) or 0,y=tonumber(q[3]) or 0,vx=tonumber(q[4]) or 0,life=.15}
      end
    end
    remotePlayer=rem
    enemies=sharedEnemies
    -- Replace, rather than append, so snapshots cannot duplicate projectiles.
    bullets=sharedBullets
    return
  end
end

return M
