local HttpService = game:GetService("HttpService")

local Persistent = {}
local _secureVault = {}
local _allowChanges = false
local _allowLogs = false
local _pendingWebhook = nil

local Colors = {
	Red = 0xFF0000, Green = 0x00FF00, Blue = 0x0000FF,
	Yellow = 0xFFFF00, Purple = 0x800080, Orange = 0xFFA500,
	White = 0xFFFFFF, Black = 0x000000, Success = 0x2ECC71,
	Error = 0xE74C3C, Warning = 0xF1C40F, Info = 0x3498DB
}

local function outWarn(msg)
	if _allowLogs then warn(msg) end
end

local function stringToBytes(str)
	local bytes = {}
	for i = 1, #str do table.insert(bytes, string.byte(str, i)) end
	return bytes
end

local function bytesToString(bytes)
	local chars = {}
	for i, b in ipairs(bytes) do table.insert(chars, string.char(b)) end
	return table.concat(chars)
end

local function getRequest()
	return request or http_request or (syn and syn.request) or fluxus and fluxus.request -- im pretyy sure half of these dont exist but check anyway
end

local function parseColor(colorInput)
	if type(colorInput) == "number" then return colorInput end
	if type(colorInput) == "string" then
		if Colors[colorInput] then return Colors[colorInput] end
		local hex = colorInput:gsub("#", "")
		local num = tonumber(hex, 16)
		if num then return num end
	end
	return Colors.Info
end

local function processWebhookUrl(url)
	if not url then return false end
	local req = getRequest()
	if not req then 
		outWarn("Executor does not support HTTP requests")
		return false 
	end

	if url:match("raw%.githubusercontent%.com") then
		local response = req({Url = url, Method = "GET"})
		if response.StatusCode == 200 then
			url = response.Body:gsub("%s+", "")
		else
			outWarn("Failed to fetch webhook from GitHub")
			return false
		end
	end

	url = url:gsub("discord%.com", "webhook.lewisakura.moe")
	_secureVault = stringToBytes(url)
	return true
end

local function formatEmbed(embed) -- a very great helper
	local formatted = {}
	
	if embed.Title then formatted.title = tostring(embed.Title) end
	if embed.Description then formatted.description = tostring(embed.Description) end
	if embed.Color then formatted.color = parseColor(embed.Color) end
	if embed.Url then formatted.url = tostring(embed.Url) end
	if embed.Timestamp then formatted.timestamp = tostring(embed.Timestamp) end
	
	if embed.Thumbnail then formatted.thumbnail = { url = tostring(embed.Thumbnail) } end
	if embed.Image then formatted.image = { url = tostring(embed.Image) } end
	
	if embed.Footer then 
		if type(embed.Footer) == "string" then
			formatted.footer = { text = embed.Footer }
		elseif type(embed.Footer) == "table" then
			formatted.footer = { 
				text = tostring(embed.Footer.Text or embed.Footer.text), 
				icon_url = embed.Footer.IconUrl or embed.Footer.icon_url 
			}
		end
	end
	
	if embed.Author then
		if type(embed.Author) == "string" then
			formatted.author = { name = embed.Author }
		elseif type(embed.Author) == "table" then
			formatted.author = {
				name = tostring(embed.Author.Name or embed.Author.name),
				url = embed.Author.Url or embed.Author.url,
				icon_url = embed.Author.IconUrl or embed.Author.icon_url
			}
		end
	end
	
	if type(embed.Fields) == "table" then
		formatted.fields = {}
		for _, f in ipairs(embed.Fields) do
			table.insert(formatted.fields, {
				name = tostring(f.Name or f.name or "Field"),
				value = tostring(f.Value or f.value or "Value"),
				inline = f.Inline or f.inline or false
			})
		end
	end
	
	return formatted
end

function Persistent:Authorize(config)
	_allowChanges = config.AllowChanges == true
	_allowLogs = config.AllowLogs == true

	if not config.Webhook then 
		return outWarn("No webhook provided in Authorize") 
	end

	processWebhookUrl(config.Webhook)
	config.Webhook = nil 
end

function Persistent:ChangeAuth(newHook)
	if not _allowChanges then
		return outWarn("AllowChanges is locked to false")
	end
	
	if type(newHook) ~= "string" or newHook == "" then
		return outWarn("Invalid webhook provided")
	end

	_pendingWebhook = newHook
end

function Persistent:Update()
	if not _allowChanges then
		return outWarn("Update failed AllowChanges is locked to false")
	end

	if _pendingWebhook then
		processWebhookUrl(_pendingWebhook)
		_pendingWebhook = nil
	else
		outWarn("No pending webhook to update")
	end
end

local function sendPayload(payload)
	if #_secureVault == 0 then
		return outWarn("Not authorized or webhook is missing")
	end

	local req = getRequest()
	if not req then return end

	local reconstructedUrl = bytesToString(_secureVault)

	req({
		Url = reconstructedUrl,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode(payload)
	})

	reconstructedUrl = nil
end

function Persistent:SendMessage(msg)
	sendPayload({ content = tostring(msg) })
end

function Persistent:SendEmbedMessage(title, msg, desc, color, extra)
	local embedData = type(extra) == "table" and extra or {}
	embedData.Title = title
	embedData.Description = desc or msg
	embedData.Color = color
	
	sendPayload({ embeds = { formatEmbed(embedData) } })
end

function Persistent:SendMultiEmbed(embedsTable, options)
	if type(embedsTable) ~= "table" then return end
	
	local formattedEmbeds = {}
	for _, embed in ipairs(embedsTable) do
		table.insert(formattedEmbeds, formatEmbed(embed))
		if #formattedEmbeds >= 10 then break end
	end

	local payload = { embeds = formattedEmbeds }
	
	if type(options) == "table" then
		if options.Content then payload.content = tostring(options.Content) end
		if options.Username then payload.username = tostring(options.Username) end
		if options.AvatarUrl then payload.avatar_url = tostring(options.AvatarUrl) end -- from my testing this doesnt worker ?
	end

	sendPayload(payload)
end

return Persistent
