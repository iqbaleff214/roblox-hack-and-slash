--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Constants = require(ReplicatedStorage.Shared.Constants)

local ShopController = Knit.CreateController({ Name = "ShopController" })

-- UI References
local screenGui: ScreenGui
local shopWindow: Frame
local backdrop: GuiObject
local uiScale: UIScale

-- Visual Effects
local blurEffect: BlurEffect

-- State & Debounce Management
local isAnimating: boolean = false
local lastCloseTime: number = 0
local COOLDOWN_TIME: number = 1.0 -- Cooldown agar tidak langsung re-open saat berdiri di zona

-- Config Tween Animasi
local TWEEN_OPEN = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_CLOSE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TWEEN_FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getOrCreateBlur(): BlurEffect
    local blur = Lighting:FindFirstChild("ShopBlur")
    if not blur then
        local newBlur = Instance.new("BlurEffect")
        newBlur.Name = "ShopBlur"
        newBlur.Size = 0
        newBlur.Enabled = false
        newBlur.Parent = Lighting
        return newBlur
    end
    return blur :: BlurEffect
end

local function refresh()
	local DataService = Knit.GetService("DataService")

	local successProfile, profile = DataService:GetProfile():await()
	if not successProfile or not profile then
		warn("Failed to fetch profile data.")
		return
	end
end

function ShopController:KnitStart()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	screenGui = playerGui:WaitForChild("Shop")

	backdrop = screenGui:WaitForChild("Backdrop") :: Frame
	shopWindow = screenGui:WaitForChild("ShopFrame") :: Frame

	uiScale = shopWindow:FindFirstChildOfClass("UIScale") :: UIScale
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = shopWindow :: Frame
    end

	blurEffect = getOrCreateBlur()

	local InventoryService = Knit.GetService("InventoryService")
	InventoryService.ItemGranted:Connect(refresh)

	local CurrencyService = Knit.GetService("CurrencyService")
	CurrencyService.CurrencyChanged:Connect(refresh)

	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:Close()
		end
	end)

	local function attachZone(instance: Instance)
        if not instance:IsA("BasePart") then return end

        instance.Touched:Connect(function(hit: BasePart)
            -- Cegah trigger saat sedang animasi atau baru saja ditutup
            if os.clock() - lastCloseTime < COOLDOWN_TIME then return end
            if self:IsOpen() or isAnimating then return end

            local character = player.Character
            if character and hit:IsDescendantOf(character) then
                self:Open()
            end
        end)
    end

	for _, part in CollectionService:GetTagged(Constants.Tags.ShopZone) do
		attachZone(part)
	end
	CollectionService:GetInstanceAddedSignal(Constants.Tags.ShopZone):Connect(attachZone)
end

function ShopController:Open()
	if isAnimating or screenGui.Enabled then return end
    isAnimating = true

    -- State Awal Animasi
    uiScale.Scale = 0.6
    backdrop.BackgroundTransparency = 1
    blurEffect.Size = 0
    blurEffect.Enabled = true
    screenGui.Enabled = true

    -- Jalankan Animasi
    TweenService:Create(uiScale, TWEEN_OPEN, { Scale = 1 }):Play()
    TweenService:Create(backdrop, TWEEN_FADE, { BackgroundTransparency = 0.4 }):Play()

    local blurTween = TweenService:Create(blurEffect, TWEEN_FADE, { Size = 16 })
    blurTween:Play()

	local SoundController = Knit.GetController("SoundController")
	SoundController:PlaySFX("UIWindow")

    blurTween.Completed:Connect(function()
        isAnimating = false

    end)

	refresh()
end

function ShopController:Close()
	if isAnimating or not screenGui.Enabled then return end
    isAnimating = true
    lastCloseTime = os.clock() -- Catat waktu tutup untuk cooldown

    -- Animasi Keluar
    TweenService:Create(uiScale, TWEEN_CLOSE, { Scale = 0.7 }):Play()
    TweenService:Create(backdrop, TWEEN_FADE, { BackgroundTransparency = 1 }):Play()
    
    local blurTween = TweenService:Create(blurEffect, TWEEN_FADE, { Size = 0 })
    blurTween:Play()

    -- Disentuh/Disembunyikan HANYA SETELAH animasi selesai
    blurTween.Completed:Connect(function()
        screenGui.Enabled = false
        blurEffect.Enabled = false
        isAnimating = false
    end)
end

function ShopController:IsOpen(): boolean
	return screenGui.Enabled
end

return ShopController
