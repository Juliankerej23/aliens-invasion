-- ENet LAN transport for Aliens Invasion.
-- v22: host-authoritative shared world, independent player-2 state,
-- sequence numbers and basic connection status.
local M = {}
local enet, host, peer, mode = nil, nil, nil, "offline"
local port = 22122
local peers = {}
local inbox = {}
local seq = 0
local lastRx = 0
local clientId = 0
local MAX_WEAPONS = 10

local function send(p, msg)
  if p then p:send(msg, 0, true) end
end

function M.init(p)
  port = p or port
  local ok, e = pcall(require, "enet")
  if ok then enet = e; mode = "ready" else M.error = "ENet no disponible en esta build"; mode = "offline" end
end

function M.host()
  if not enet then return false end
  if host then pcall(host.flush, host) end
  local ok, h = pcall(enet.host_create, "*:" .. port, 8)
  if not ok then M.error = tostring(h); return false end
  host, peer, peers = h, nil, {}
  mode, clientId, lastRx = "host", 0, love.timer.getTime()
  return true
end

function M.join(ip)
  if not enet then return false end
  local ok, h = pcall(enet.host_create, nil, 1)
  if not ok then M.error = tostring(h); return false end
  host = h
  local ok2, p = pcall(host.connect, host, ip .. ":" .. port)
  if not ok2 then M.error = tostring(p); return false end
  peer = p
  mode, clientId, lastRx, seq = "client", 1, love.timer.getTime(), 0
  return true
end

function M.update(dt, game)
  if not host then return end
  while true do
    local ev = host:service(0)
    if not ev then break end
    if ev.type == "connect" then
      if mode == "host" then
        peers[ev.peer] = true
        send(ev.peer, "WELCOME|1")
      end
      lastRx = love.timer.getTime()
    elseif ev.type == "receive" then
      inbox[#inbox + 1] = { peer = ev.peer, data = ev.data }
      lastRx = love.timer.getTime()
    elseif ev.type == "disconnect" then
      peers[ev.peer] = nil
      if ev.peer == peer then peer = nil end
    end
  end
  if game and game.netReceive then
    for i = 1, #inbox do game.netReceive(inbox[i].data, inbox[i].peer) end
  end
  inbox = {}
  if mode == "client" and peer and love.timer.getTime() - lastRx > 8 then
    M.error = "Servidor LAN sin respuesta"
  end
end

function M.sendInput(x, y, face, fire, weapon, left, right, melee)
  if mode ~= "client" or not peer then return end
  seq = seq + 1
  send(peer, string.format("INPUT|%d|%.2f|%.2f|%d|%d|%d|%d|%d|%d", seq, x, y, face,
    fire and 1 or 0, math.max(1, math.min(MAX_WEAPONS, weapon or 1)), left and 1 or 0, right and 1 or 0, melee and 1 or 0))
end

function M.broadcast(snapshot)
  if mode ~= "host" or not host then return end
  local msg = "SNAP|" .. snapshot
  for p in pairs(peers) do send(p, msg) end
end

function M.event(kind, payload)
  local msg = "EVENT|" .. kind .. "|" .. (payload or "")
  if mode == "host" then
    for p in pairs(peers) do send(p, msg) end
  elseif peer then send(peer, msg) end
end

function M.isHost() return mode == "host" end
function M.isClient() return mode == "client" end
function M.connected() return mode == "host" or (mode == "client" and peer ~= nil) end
function M.status()
  if M.error then return "LAN: " .. M.error end
  if mode == "host" then return "LAN HOST :" .. port end
  if mode == "client" then return peer and "LAN CLIENT" or "LAN CONECTANDO" end
  if mode == "ready" then return "LAN LISTO" end
  return "LAN LOCAL"
end

return M
