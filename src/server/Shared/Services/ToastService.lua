--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ToastService = Knit.CreateService({
	Name = "ToastService",
	Client = {
        ShowToast = Knit.CreateSignal(), -- (message: string, isError: boolean)
    },
})

function ToastService:Show(player: Player, message: string, isError: boolean?)
    self.Client.ShowToast:Fire(player, message, isError or false)
end

return ToastService