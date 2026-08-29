--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ButtonController = Knit.CreateController({ Name = "ButtonController" })

-- Konfigurasi Tweens
local TWEEN_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_RESET = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Tag khusus untuk tombol yang diberi animasi (bisa dipasang lewat Studio / Tag Editor)
local BUTTON_TAG = "AnimatedButton"

local function setupButtonAnimation(button: GuiButton)
    -- Ambil atau buat UIScale di dalam tombol
    local uiScale = button:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = button
    end

    local isHovered = false

    -- 1. Efek Mouse Hover / Masuk Kursor
    button.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(uiScale, TWEEN_HOVER, { Scale = 1.05 }):Play()

        -- (Opsional) Mainkan SFX Hover via SoundController
        local SoundController = Knit.GetController("SoundController")
        SoundController:PlaySFX("UIHover", true)
    end)

    -- 2. Efek Mouse Leave / Kursor Keluar
    button.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(uiScale, TWEEN_RESET, { Scale = 1 }):Play()
    end)

    -- 3. Efek Ditekan (Click / Touch Down)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(uiScale, TWEEN_PRESS, { Scale = 0.92 }):Play()
        end
    end)

    -- 4. Efek Dilepas (Click / Touch Up)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local targetScale = if isHovered then 1.05 else 1.0
            TweenService:Create(uiScale, TWEEN_RESET, { Scale = targetScale }):Play()

            -- (Opsional) Mainkan SFX Click via SoundController
            local SoundController = Knit.GetController("SoundController")
            SoundController:PlaySFX("UIClick", true)
        end
    end)
end

function ButtonController:KnitStart()
    for _, button in CollectionService:GetTagged(BUTTON_TAG) do
        if button:IsA("GuiButton") then
            setupButtonAnimation(button)
        end
    end
    CollectionService:GetInstanceAddedSignal(BUTTON_TAG):Connect(function(button)
        if button:IsA("GuiButton") then
            setupButtonAnimation(button)
        end
    end)
end

return ButtonController