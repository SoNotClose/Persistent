--[[
    Example of persistents code
    Source: (https://github.com/SoNotClose/Persistent)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Persistent = loadstring(game:HttpGet('https://raw.githubusercontent.com/SoNotClose/Persistent/main/Persistent.luau'))()

Persistent:Authorize({
    Webhook = '', -- could be the raw text or from a github
    AllowChanges = true, -- Must be true to use ChangeAuth() later
    AllowLogs = true     -- Enables console warnings for debugging
})

Persistent:SendMessage('User ' .. LocalPlayer.Name .. ' has loaded the script.')

Persistent:SendEmbedMessage(
    'Log Entry', 
    'Main Content', 
    'Detailed description of the event goes here.', 
    'Info', -- Preset Color
    {
        Thumbnail = 'https://www.roblox.com/headshot-thumbnail/image?userId=' .. LocalPlayer.UserId .. '&width=420&height=420&format=png',
        Footer = { Text = 'Persistent', IconUrl = '' },
        Author = 'Persistent'
    }
)

Persistent:SendMultiEmbed({
    {
        Title = 'Player Data',
        Color = '#FFD700',
        Fields = {
            {name = 'Username', value = LocalPlayer.Name, inline = true},
            {name = 'ID', value = tostring(LocalPlayer.UserId), inline = true}
        },
        Timestamp = DateTime.now():ToIsoDate()
    },
    {
        Title = 'Environment',
        Description = 'Place ID: ' .. game.PlaceId,
        Color = 'Purple'
    }
}, {
    Username = 'Persistent',
    AvatarUrl = 'https://cdn-icons-png.flaticon.com/512/1000/1000997.png'
})

-- task.wait(1)
-- Persistent:ChangeAuth('') can be used for textboxes
-- Persistent:Update() needs to be called to update

-- Persistent:SendMessage('Webhook successfully swapped')
