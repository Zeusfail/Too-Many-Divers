local MOD_TAG = "[TooManyDiversVoice]"

-- Chaque voix distante est jouee sur un canal FMOD (event + VCA) de
-- UWEVoiceChatWorldSubsystem.ActiveChatAssets. Le jeu n'en declare que 3 (player_01/03/04)
-- alors que les banques en contiennent 8 (player_00..07) : on ajoute ceux qui manquent.

local MOD_VERSION = "1.0.0"

local INIT_GUARD = "__SN2_TOO_MANY_DIVERS_VOICE_INITIALIZED"
local VOICE_SUBSYSTEM_CLASS = "/Script/UWEVoiceChat.UWEVoiceChatWorldSubsystem"
local VOICE_SLOT_COUNT = 8
local VOICE_POOL_POLL_MS = 500
local VOICE_POOL_MAX_POLLS = 240
-- Agrandir le TArray realloue ses elements : on prefere le faire avant toute attribution.
local VOICE_POOL_ASSIGNED_GRACE_POLLS = 6

-- Priorite : config/settings.json, puis SN2ModSettings (fichier saved, variables partagees).
local SETTINGS_NAME = "TooManyDiversVoice"
local DEFAULT_ENABLED = true
local MIN_MAX_VOICE_PLAYERS = 4
local MAX_MAX_VOICE_PLAYERS = VOICE_SLOT_COUNT + 1
local DEFAULT_MAX_VOICE_PLAYERS = MAX_MAX_VOICE_PLAYERS
local MANIFEST_PATH = "./ue4ss/Mods/SN2ModSettings/registrations/" .. SETTINGS_NAME .. ".lua"
local SAVED_PATH = "./ue4ss/Mods/SN2ModSettings/saved/" .. SETTINGS_NAME .. ".lua"
local SHARED_PREFIX = "SN2ModSettings/" .. SETTINGS_NAME .. "/"
local SHARED_POLL_MS = 1000

if rawget(_G, INIT_GUARD) then return end
_G[INIT_GUARD] = true

local function log(message, ...)
    print(string.format("%s %s\n", MOD_TAG, string.format(message, ...)))
end

local settings = { Enabled = DEFAULT_ENABLED, MaxVoicePlayers = DEFAULT_MAX_VOICE_PLAYERS }

local function normalize_setting(key, raw)
    if key == "Enabled" then
        if type(raw) == "boolean" then return raw end
        if type(raw) == "number" then return raw ~= 0 end
    elseif key == "MaxVoicePlayers" and type(raw) == "number" then
        local value = math.floor(raw + 0.5)
        if value >= MIN_MAX_VOICE_PLAYERS and value <= MAX_MAX_VOICE_PLAYERS then return value end
    end
    return nil
end

local function set_setting(key, raw, source)
    local value = normalize_setting(key, raw)
    if value == nil or value == settings[key] then return end
    settings[key] = value
    log("%s = %s (%s)", key, tostring(value), source)
end

local function load_config_file()
    local src = debug.getinfo(1, "S").source
    local script_dir = src:match("^@?(.+)[/\\][^/\\]+$")
    if not script_dir then return end
    local file = io.open(script_dir .. "\\..\\config\\settings.json", "r")
    if not file then return end
    local content = file:read("*a")
    file:close()
    local enabled = content:match('"Enabled"%s*:%s*(%a+)')
    if enabled == "true" or enabled == "false" then set_setting("Enabled", enabled == "true", "settings.json") end
    local max_players = content:match('"MaxVoicePlayers"%s*:%s*(%d+)')
    if max_players then set_setting("MaxVoicePlayers", tonumber(max_players), "settings.json") end
end

local function load_saved_settings()
    local chunk = loadfile(SAVED_PATH, "t", {})
    if not chunk then return end
    local ok, saved = pcall(chunk)
    if not ok or type(saved) ~= "table" then return end
    for key in pairs(settings) do
        if saved[key] ~= nil then set_setting(key, saved[key], "SN2ModSettings") end
    end
end

local function poll_shared_settings()
    if not ModRef then return end
    for key in pairs(settings) do
        local ok, raw = pcall(function() return ModRef:GetSharedVariable(SHARED_PREFIX .. key) end)
        if ok and raw ~= nil then set_setting(key, raw, "SN2ModSettings") end
    end
end

local function write_sn2modsettings_manifest()
    local dir = MANIFEST_PATH:match("(.*[/\\])")
    os.execute('mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul')
    local f = io.open(MANIFEST_PATH, "w")
    if not f then
        log("SN2ModSettings manifest: cannot write %s", MANIFEST_PATH)
        return
    end
    f:write(string.format([=[return {
    name            = "%s",
    display         = "Too Many Divers - Voice",
    version         = "%s",
    nexus_id        = "73",
    settings = {
        {
            key         = "Enabled",
            title       = "Extra voice slots",
            description = "Adds the unused proximity voice chat slots so more than 4 players can hear each other. Every player needs this mod. Applies the next time you load a game.",
            type        = "toggle",
            default     = %s,
        },
        {
            key         = "MaxVoicePlayers",
            title       = "Max voice players",
            description = "Players who can hear each other in proximity voice chat (%d to %d, game default 4). Applies the next time you load a game.",
            type        = "slider",
            format      = "integer",
            default     = %d,
            min         = %d,
            max         = %d,
            step        = 1,
            enabled_by  = "Enabled",
        },
    },
}
]=], SETTINGS_NAME, MOD_VERSION, tostring(settings.Enabled),
        MIN_MAX_VOICE_PLAYERS, MAX_MAX_VOICE_PLAYERS,
        settings.MaxVoicePlayers, MIN_MAX_VOICE_PLAYERS, MAX_MAX_VOICE_PLAYERS))
    f:close()
end

load_config_file()
-- Les defauts du manifest viennent de settings.json, pas des valeurs SN2ModSettings.
write_sn2modsettings_manifest()
load_saved_settings()

local function is_valid(obj)
    if not obj then return false end
    local ok, valid = pcall(function()
        return obj.IsValid and obj:IsValid()
    end)
    return ok and valid == true
end

local function array_count(arr)
    local ok, n = pcall(function() return arr:GetArrayNum() end)
    return ok and n or -1
end

local function object_name(obj)
    local ok, name = pcall(function() return obj:GetFullName() end)
    return ok and tostring(name) or "?"
end

-- "FMODEvent /Game/.../x_player_01.x_player_01" -> "/Game/.../x_player_01.x_player_01"
local function object_path(full_name)
    return full_name:match("^%S+%s+(.+)$") or full_name
end

local function slot_path(template_path, slot)
    return (template_path:gsub("player_%d%d", string.format("player_%02d", slot)))
end

local function find_or_load(path)
    local ok, obj = pcall(function() return StaticFindObject(path) end)
    if ok and is_valid(obj) then return obj end
    ok, obj = pcall(function() return LoadAsset(path) end)
    if ok and is_valid(obj) then return obj end
    ok, obj = pcall(function() return StaticFindObject(path) end)
    if ok and is_valid(obj) then return obj end
    return nil
end

local function append_voice_slot(active, event, vca)
    local index = active:GetArrayNum() + 1
    local ok = pcall(function()
        active[index] = { bAssigned = false, AssignedPlayer = "", PrettyName = "", FMODEvent = event, FMODVCA = vca }
    end)
    if not ok or active:GetArrayNum() < index then
        -- Repli : indexer au-dela de la fin agrandit le TArray (element mis a zero).
        ok = pcall(function()
            local entry = active[index]
            entry.FMODEvent = event
            entry.FMODVCA = vca
        end)
    end
    if not ok then return false end
    local ok_check, check = pcall(function() return object_name(active[index].FMODEvent) end)
    return ok_check and check ~= "?" and check:find(object_path(object_name(event)), 1, true) ~= nil
end

-- Retourne true quand il n'y a plus rien a faire pour ce subsystem.
local function try_expand_voice_pool(subsystem, attempt)
    local active = subsystem.ActiveChatAssets
    local count = array_count(active)
    if count <= 0 then return false end
    if not settings.Enabled then
        log("Voice pool: extra slots disabled in settings (%d slots)", count)
        return true
    end
    local target = settings.MaxVoicePlayers - 1
    if count >= target then return true end

    local used, assigned = {}, 0
    local template_event, template_vca
    active:ForEach(function(_, elem)
        local entry = elem:get()
        local ok_ev, ev = pcall(function() return object_name(entry.FMODEvent) end)
        local ok_vca, vca = pcall(function() return object_name(entry.FMODVCA) end)
        local ok_as, is_assigned = pcall(function() return entry.bAssigned end)
        if ok_as and is_assigned then assigned = assigned + 1 end
        if ok_ev then
            local slot = tonumber(ev:match("player_(%d%d)"))
            if slot then used[slot] = true end
            if not template_event and slot then template_event = object_path(ev) end
        end
        if ok_vca and not template_vca and vca:match("player_%d%d") then template_vca = object_path(vca) end
    end)
    if assigned > 0 and attempt < VOICE_POOL_ASSIGNED_GRACE_POLLS then return false end
    if not template_event or not template_vca then
        log("Voice pool: unexpected FMOD asset names, not expanding (%d slots)", count)
        return true
    end

    local before = count
    for slot = 0, VOICE_SLOT_COUNT - 1 do
        if count >= target then break end
        if not used[slot] then
            local event = find_or_load(slot_path(template_event, slot))
            local vca = find_or_load(slot_path(template_vca, slot))
            if not event or not vca then
                log("Voice pool: slot %02d missing (event=%s vca=%s)", slot, tostring(event ~= nil), tostring(vca ~= nil))
            elseif append_voice_slot(active, event, vca) then
                count = array_count(active)
            else
                log("Voice pool: failed to add slot %02d", slot)
                break
            end
        end
    end
    log("Voice pool: %d -> %d slots (voice for up to %d players)", before, count, count + 1)
    return true
end

local function watch_voice_pool(subsystem, attempt)
    ExecuteWithDelay(VOICE_POOL_POLL_MS, function()
        ExecuteInGameThread(function()
            local ok, done = pcall(function()
                if not is_valid(subsystem) then return true end
                return try_expand_voice_pool(subsystem, attempt)
            end)
            if not ok then
                log("Voice pool: error: %s", tostring(done))
            elseif not done and attempt < VOICE_POOL_MAX_POLLS then
                watch_voice_pool(subsystem, attempt + 1)
            end
        end)
    end)
end

local function bootstrap()
    local ok, err = pcall(function()
        NotifyOnNewObject(VOICE_SUBSYSTEM_CLASS, function(subsystem)
            watch_voice_pool(subsystem, 1)
        end)
    end)
    if not ok then
        log("Failed to arm NotifyOnNewObject for UWEVoiceChatWorldSubsystem: %s", tostring(err))
        return
    end
    -- Subsystem deja cree avant le chargement du mod (rechargement a chaud).
    local ok_find, existing = pcall(function() return FindFirstOf("UWEVoiceChatWorldSubsystem") end)
    if ok_find and is_valid(existing) then watch_voice_pool(existing, 1) end
    poll_shared_settings()
    log("Loaded. Enabled = %s, voice for up to %d players", tostring(settings.Enabled), settings.MaxVoicePlayers)
end

ExecuteInGameThread(bootstrap)

LoopAsync(SHARED_POLL_MS, function()
    poll_shared_settings()
    return false
end)
