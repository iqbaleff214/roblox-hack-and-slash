--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ToastController = Knit.CreateController({ Name = "ToastController" })

local toastFrame: Frame
local textMessage: TextLabel

function ToastController:KnitStart()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    toastFrame = playerGui:WaitForChild("ToastGui"):WaitForChild("Container") :: Frame
    textMessage = toastFrame:WaitForChild("Message") :: TextLabel

    local ToastService = Knit.GetService("ToastService")

    ToastService.ShowToast:Connect(function(message: string, isError: boolean)
        self:DisplayToast(message, isError)
    end)
end

function ToastController:DisplayToast(message: string, isError: boolean)
    textMessage.Text = message
    toastFrame.BackgroundColor3 = isError and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(60, 200, 100)

    -- Tampilkan (Misal dengan Fade In / Fade Out)
    toastFrame.Visible = true

    task.delay(3, function()
        toastFrame.Visible = false
    end)
end

return ToastController