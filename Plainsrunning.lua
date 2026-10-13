--============================================================
-- PLAINSRUNNING (Tauren) - inspirado no WoW Forever
-- Velocidade de corrida aumenta progressivamente enquanto o
-- Tauren se move continuamente, ate +30% em 10 segundos.
-- Reseta ao parar, entrar em combate, montar ou entrar em
-- masmorra/raid.
-- Sem icone de buff - so a mecanica.
--============================================================

local TAUREN_RACE          = 6
local RAMP_TIME             = 10     -- segundos para atingir o bonus maximo
local MAX_BONUS              = 0.30   -- +30% de velocidade de corrida
local TICK_MS                 = 1000   -- intervalo de checagem (ms)
local MOVE_THRESHOLD        = 0.4    -- distancia minima por tick para contar como "em movimento"

local MOVE_RUN = 1 -- indice de Player:SetSpeed para velocidade de corrida

local PlainsData = {} -- [guidLow] = { lastX, lastY, lastZ, moveSeconds, active }

local function ResetSpeed(player, data)
    if data.active then
        player:SetSpeed(MOVE_RUN, 1.0, true)
        data.active = false
    end
    data.moveSeconds = 0
end

local function PlainsrunningTick(eventId, delay, repeats)
    for _, player in ipairs(GetPlayersInWorld()) do
        if player and player:IsInWorld() and player:GetRace() == TAUREN_RACE then
            local guidLow = player:GetGUIDLow()
            local data = PlainsData[guidLow]

            if not data then
                data = {
                    lastX = player:GetX(),
                    lastY = player:GetY(),
                    lastZ = player:GetZ(),
                    moveSeconds = 0,
                    active = false
                }
                PlainsData[guidLow] = data
            end

            local map = player:GetMap()
            local blocked = player:IsInCombat()
                or player:IsMounted()
                or (map ~= nil and (map:IsDungeon() or map:IsRaid()))

            local x, y, z = player:GetX(), player:GetY(), player:GetZ()

            if blocked then
                ResetSpeed(player, data)
            else
                local dx = x - data.lastX
                local dy = y - data.lastY
                local moving = (dx * dx + dy * dy) > MOVE_THRESHOLD

                if moving then
                    data.moveSeconds = math.min(data.moveSeconds + (TICK_MS / 1000), RAMP_TIME)

                    local bonus = (data.moveSeconds / RAMP_TIME) * MAX_BONUS
                    player:SetSpeed(MOVE_RUN, 1.0 + bonus, true)
                    data.active = true
                else
                    ResetSpeed(player, data)
                end
            end

            data.lastX, data.lastY, data.lastZ = x, y, z
        end
    end
end

local function OnLogout(event, player)
    PlainsData[player:GetGUIDLow()] = nil
end

RegisterPlayerEvent(4, OnLogout) -- PLAYER_EVENT_ON_LOGOUT

CreateLuaEvent(PlainsrunningTick, TICK_MS, 0) -- 0 repeticoes = infinito
