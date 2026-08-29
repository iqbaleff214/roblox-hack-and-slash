--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundController = Knit.CreateController({ Name = "SoundController" })

local sounds: { [string]: Sound } = {}

local isMuted: boolean = false
local sfxVolume: number = 0.5

function SoundController:KnitStart()
    local sfxFolder: Folder = SoundService:WaitForChild("SFX") :: Folder

    for _, sound in sfxFolder:GetChildren() do
        if sound:IsA("Sound") then
            sounds[sound.Name] = sound
        end
    end
end

function SoundController:PlaySFX(soundName: string, randomizePitch: boolean?)
    if isMuted then return end

    local sound = sounds[soundName]
    if not sound then
        warn("[SoundController] Sound tidak ditemukan:", soundName)
        return
    end

    if randomizePitch then
        sound.PlaybackSpeed = math.random(95, 105) / 100
    end

    SoundService:PlayLocalSound(sound)
end

function SoundController:SetMuted(muted: boolean)
    isMuted = muted
end

return SoundController