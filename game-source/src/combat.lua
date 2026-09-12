-- Combat helpers kept in a separate module to avoid Lua's 60-upvalue limit.
local C = {}

function C.fire(state, player, ammo, weapons, weaponOwned, setPlayerAction, bullets, anim, addFx, fx, soundForWeapon, playFile)
  if state ~= "playing" or player.fireCd > 0 or ammo <= 0 or player.dead then return ammo end
  if not weaponOwned(player.weapon) then player.weapon = 1 end
  local w = weapons[player.weapon] or weapons[1]
  player.fireCd = w.cooldown or .22
  player.shootAnim = .20
  setPlayerAction("fire", .22)
  ammo = math.max(0, ammo - (w.ammoCost or 1))
  local muzzleX = player.x + player.face * 42
  local muzzleY = player.y - 25
  local burst = w.burst or 1
  for n = 1, burst do
    local spread = w.spread or 0
    local vy = math.tan((n - (burst + 1) / 2) * spread) * (w.speed or 500)
    bullets[#bullets + 1] = {
      x=muzzleX, y=muzzleY, vx=player.face*(w.speed or 500), vy=vy,
      life=w.life or 1.2, dmg=w.damage or 1, owner=0, weapon=player.weapon,
      trail=0, frameT=0, pierce=w.pierce or 0, kind=w.kind or "bullet"
    }
  end
  addFx(muzzleX, muzzleY, 4, anim.muzzle, .16, .65)
  fx[#fx + 1] = {
    x=player.x-player.face*12, y=player.y-8, t=.28, maxT=.28, kind=7,
    frames=anim.shell, scale=.72, frameT=0, frame=0,
    vx=-player.face*18, vy=-48
  }
  if player.weapon == 10 and anim.gunLightning and #anim.gunLightning > 0 then
    addFx(muzzleX+player.face*8, muzzleY, 11, anim.gunLightning, .22, .72)
  elseif player.weapon == 9 and anim.laser and #anim.laser > 0 then
    addFx(muzzleX+player.face*8, muzzleY, 11, anim.laser, .22, .62)
  end
  playFile(w.sound or soundForWeapon[player.weapon] or "zm_sfx00.ogg", w.volume or .78)
  return ammo
end

return C
