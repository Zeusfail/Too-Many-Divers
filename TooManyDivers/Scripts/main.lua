local MOD_TAG = "[TooManyDivers]"

local DEFAULT_MAX_PLAYERS = 16
local MIN_MAX_PLAYERS = 4
local MAX_MAX_PLAYERS = 64

local function load_config()
    local src = debug.getinfo(1, "S").source
    local script_dir = src:match("^@?(.+)[/\\][^/\\]+$")
    if not script_dir then
        print(string.format("%s Could not resolve config path, using default (%d)\n", MOD_TAG, DEFAULT_MAX_PLAYERS))
        return DEFAULT_MAX_PLAYERS
    end
    local config_path = script_dir .. "\\..\\config\\settings.json"
    local file = io.open(config_path, "r")
    if not file then
        print(string.format("%s config/settings.json not found, using default (%d)\n", MOD_TAG, DEFAULT_MAX_PLAYERS))
        return DEFAULT_MAX_PLAYERS
    end
    local content = file:read("*a")
    file:close()
    local raw = content:match('"MaxPlayers"%s*:%s*(%d+)')
    local value = raw and tonumber(raw)
    if not value then
        print(string.format("%s MaxPlayers missing from config, using default (%d)\n", MOD_TAG, DEFAULT_MAX_PLAYERS))
        return DEFAULT_MAX_PLAYERS
    end
    if value < MIN_MAX_PLAYERS or value > MAX_MAX_PLAYERS then
        print(string.format("%s MaxPlayers=%d hors plage [%d-%d], using default (%d)\n",
            MOD_TAG, value, MIN_MAX_PLAYERS, MAX_MAX_PLAYERS, DEFAULT_MAX_PLAYERS))
        return DEFAULT_MAX_PLAYERS
    end
    return value
end

local TARGET_MAX_PLAYERS = load_config()

local MANIFEST_PATH = "./ue4ss/Mods/SN2ModSettings/registrations/TooManyDivers.lua"

local function write_sn2modsettings_manifest()
    local dir = MANIFEST_PATH:match("(.*[/\\])")
    os.execute('mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul')
    local f = io.open(MANIFEST_PATH, "w")
    if not f then
        print(string.format("%s SN2ModSettings manifest: impossible d'ecrire %s (SN2ModSettings absent ou chemin invalide)\n", MOD_TAG, MANIFEST_PATH))
        return
    end
    -- Le widget ApplicationScaleSlider affiche value*100 (c'est un widget de pourcentage).
    -- On stocke donc les valeurs divisees par 100 : 0.16 s'affiche comme 16, 2.55 comme 255.
    -- TooManyDivers relit et multiplie par 100 pour recuperer le vrai nombre de joueurs.
    -- IMPORTANT : string.format("%.2f") utilise le separateur decimal de la locale systeme
    -- (virgule en locale francaise). On force le point via gsub pour que le manifest soit
    -- du Lua valide quel que soit la locale de la machine.
    local function f2s(n)
        return (string.format("%.2f", n):gsub(",", "."))
    end
    f:write(string.format([=[return {
    name    = "TooManyDivers",
    display = "Too Many Divers",
    settings = {
        {
            key         = "MaxPlayers",
            title       = "Max Players",
            description = "Nombre maximum de joueurs par session (%d a %d). Les changements s appliquent en temps reel sans redemarrer.",
            type        = "slider",
            default     = %s,
            min         = %s,
            max         = %s,
            step        = 0.01,
        },
    },
}
]=], MIN_MAX_PLAYERS, MAX_MAX_PLAYERS,
        f2s(TARGET_MAX_PLAYERS / 100.0),
        f2s(MIN_MAX_PLAYERS     / 100.0),
        f2s(MAX_MAX_PLAYERS     / 100.0)))
    f:close()
    print(string.format("%s SN2ModSettings manifest ecrit (default=%d)\n", MOD_TAG, TARGET_MAX_PLAYERS))
end

write_sn2modsettings_manifest()

local INIT_GUARD = "__SN2_MORE_PLAYERS_INITIALIZED"
local HOST_SESSION_HOOK_PATH = "/Script/UWESonar.UWEOnlineSessionSubsystem:HostSessionAsync"
local HOOK_RETRY_DELAY_MS = 1000
local MAX_HOOK_ATTEMPTS = 10
local MONITOR_DELAY_MS = 10000 -- Monitor state every 10 seconds
local PATCH_RETRY_DELAY_MS_1 = 1000
local PATCH_RETRY_DELAY_MS_2 = 3000
local PATCH_RETRY_DELAY_MS_3 = 10000

if rawget(_G, INIT_GUARD) then
    print(string.format("%s Duplicate entrypoint skipped\n", MOD_TAG))
    return
end

_G[INIT_GUARD] = true

local CLASS_DEFS = {
    {
        short_name = "SN2GameSession",
        class_name = "/Script/Subnautica2.SN2GameSession",
        cdo_name = "/Script/Subnautica2.Default__SN2GameSession",
        fields = { "MaxPlayers" }
    },
    {
        short_name = "UWEOnlineSessionSubsystem",
        class_name = "/Script/UWESonar.UWEOnlineSessionSubsystem",
        cdo_name = "/Script/UWESonar.Default__UWEOnlineSessionSubsystem",
        fields = { "MaxSessionPlayerCount" }
    },
    {
        short_name = "UWEHostSessionRequest",
        class_name = "/Script/UWESonar.UWEHostSessionRequest",
        cdo_name = "/Script/UWESonar.Default__UWEHostSessionRequest",
        fields = { "MaxPlayers", "MaxSessionPlayerCount" }
    },
    {
        short_name = "GameSession",
        class_name = "/Script/Engine.GameSession",
        cdo_name = "/Script/Engine.Default__GameSession",
        fields = { "MaxPlayers" }
    }
}

local hook_registered = false
local hook_attempts = 0
local notify_registered = {}
local cdo_diagnostics_logged = {}

local function get_config_by_short_name(short_name)
    for _, cfg in ipairs(CLASS_DEFS) do
        if cfg.short_name == short_name then
            return cfg
        end
    end
    return nil
end

local function log(message, ...)
    print(string.format("%s %s\n", MOD_TAG, string.format(message, ...)))
end

local function is_valid(obj)
    if not obj then
        return false
    end
    local ok, valid = pcall(function()
        return obj.IsValid and obj:IsValid()
    end)
    return ok and valid == true
end

local function unwrap_param(param)
    if param == nil then
        return nil
    end
    local ok_type, ue_type = pcall(function()
        return param:type()
    end)
    if ok_type and (ue_type == "RemoteUnrealParam" or ue_type == "LocalUnrealParam") then
        local ok_get, value = pcall(function()
            return param:get()
        end)
        if ok_get then
            return value
        end
    end
    return param
end

local function is_object_of_class(obj, class_name)
    if not is_valid(obj) then
        return false
    end
    local ok, result = pcall(function()
        return obj:IsA(class_name)
    end)
    return ok and result == true
end

local function read_numeric_field(obj, field_name)
    if not is_valid(obj) then
        return nil
    end
    local ok, value = pcall(function()
        return obj[field_name]
    end)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

local function set_numeric_field(obj, field_name, scope)
    local current = read_numeric_field(obj, field_name)
    if current == nil then
        return false
    end

    if current == TARGET_MAX_PLAYERS then
        return true
    end

    local ok, err = pcall(function()
        obj[field_name] = TARGET_MAX_PLAYERS
    end)
    if not ok then
        log("Failed to write %s.%s: %s", scope, field_name, tostring(err))
        return false
    end

    log("%s.%s: %d -> %d", scope, field_name, current, TARGET_MAX_PLAYERS)
    return true
end

-- Centralized patch function for a given object and its config
local function patch_object(obj, config, scope)
    if not is_valid(obj) then
        return false
    end

    local patched = false
    for _, field_name in ipairs(config.fields) do
        if set_numeric_field(obj, field_name, scope) then
            patched = true
        end
    end
    return patched
end

local function log_cdo_diag_once(key, message, ...)
    if cdo_diagnostics_logged[key] then
        return
    end
    cdo_diagnostics_logged[key] = true
    log(message, ...)
end

local function patch_cdo(config)
    local ok, obj = pcall(function()
        return StaticFindObject(config.cdo_name)
    end)
    if not ok then
        log_cdo_diag_once(config.cdo_name .. "#err",
            "CDO %s: StaticFindObject errored (%s): %s",
            config.short_name, config.cdo_name, tostring(obj))
        return
    end
    if not is_valid(obj) then
        log_cdo_diag_once(config.cdo_name .. "#missing",
            "CDO %s: not found at %s", config.short_name, config.cdo_name)
        return
    end

    -- CDO exists; probe each field so we can tell "found but field not a UProperty"
    -- apart from "CDO not found". Numeric fields fall through to patch_object below.
    for _, field_name in ipairs(config.fields) do
        local ok_read, value = pcall(function()
            return obj[field_name]
        end)
        if not ok_read then
            log_cdo_diag_once(config.cdo_name .. "." .. field_name .. "#err",
                "CDO %s.%s: read errored: %s",
                config.short_name, field_name, tostring(value))
        elseif type(value) ~= "number" then
            log_cdo_diag_once(config.cdo_name .. "." .. field_name .. "#nan",
                "CDO %s.%s: present but non-numeric (type=%s, value=%s)",
                config.short_name, field_name, type(value), tostring(value))
        end
    end

    patch_object(obj, config, "CDO " .. config.short_name)
end

local function patch_instances(config)
    local ok, objects = pcall(function()
        return FindAllOf(config.short_name)
    end)
    if not ok or not objects then
        return
    end
    for index, obj in ipairs(objects) do
        patch_object(obj, config, string.format("%s[%d]", config.short_name, index))
    end
end

local function apply_existing_patches()
    for _, config in ipairs(CLASS_DEFS) do
        patch_cdo(config)
        patch_instances(config)
    end
end

local function register_new_object_notify(config)
    if notify_registered[config.class_name] then
        return
    end
    local ok, err = pcall(function()
        NotifyOnNewObject(config.class_name, function(new_obj)
            -- Single callback for this class, handling all fields
            patch_object(new_obj, config, "New " .. config.short_name)
        end)
    end)
    if ok then
        notify_registered[config.class_name] = true
        log("NotifyOnNewObject armed for %s", config.short_name)
    else
        log("Failed to arm NotifyOnNewObject for %s: %s", config.short_name, tostring(err))
    end
end

-- Improved host session hook
local function on_host_session_async_pre(self_unwrapped, ...)
    -- self is the first param, it's a RemoteUnrealParam
    local self_obj = unwrap_param(self_unwrapped)
    if self_obj then
        -- Patch the subsystem that is calling the function
        local cfg_uwe = get_config_by_short_name("UWEOnlineSessionSubsystem")
        if cfg_uwe then patch_object(self_obj, cfg_uwe, "HostSessionAsync self") end
    end

    -- Iterate through arguments to find the UWEHostSessionRequest
    for i = 1, select("#", ...) do
        local arg = unwrap_param(select(i, ...))
        if arg and is_object_of_class(arg, "/Script/UWESonar.UWEHostSessionRequest") then
            local cfg_req = get_config_by_short_name("UWEHostSessionRequest")
            if cfg_req then patch_object(arg, cfg_req, string.format("HostSessionAsync arg[%d]", i)) end
            -- After patching, log the state of the request
            local val = read_numeric_field(arg, "MaxPlayers")
            if val then
                log("HostSessionAsync pre: request.MaxPlayers=%d", val)
            else
                log("HostSessionAsync pre: request has no readable max-player field")
            end
            break -- Found the request, no need to continue
        end
    end
end

local function on_host_session_async_post(...)
    -- In post-hook, we can also log the final state of the system's GameSession
    local game_session = FindFirstOf("SN2GameSession")
    if game_session then
        local val = read_numeric_field(game_session, "MaxPlayers")
        if val then
            log("HostSessionAsync post: SN2GameSession.MaxPlayers=%d", val)
        end
    end

end

local function try_register_host_session_hook()
    if hook_registered then
        return
    end
    hook_attempts = hook_attempts + 1

    local ok, pre_id, post_id = pcall(function()
        return RegisterHook(HOST_SESSION_HOOK_PATH, on_host_session_async_pre, on_host_session_async_post)
    end)

    if ok and type(pre_id) == "number" and type(post_id) == "number" then
        hook_registered = true
        log("Registered %s", HOST_SESSION_HOOK_PATH)
        return
    end

    if hook_attempts < MAX_HOOK_ATTEMPTS then
        ExecuteWithDelay(HOOK_RETRY_DELAY_MS, function()
            ExecuteInGameThread(try_register_host_session_hook)
        end)
        return
    end
    log("Could not register %s after %d attempts", HOST_SESSION_HOOK_PATH, hook_attempts)
end

-- Optional monitor to periodically check state and log if something reverts
local function start_monitor()
    local function monitor_loop()
        local gs = FindFirstOf("SN2GameSession")
        local uwe = FindFirstOf("UWEOnlineSessionSubsystem")
        if gs then
            local val = read_numeric_field(gs, "MaxPlayers")
            if val and val ~= TARGET_MAX_PLAYERS then
                log("WARNING: SN2GameSession.MaxPlayers changed to %d! Re-patching...", val)
                apply_existing_patches()
            end
        end
        if uwe then
            local val = read_numeric_field(uwe, "MaxSessionPlayerCount")
            if val and val ~= TARGET_MAX_PLAYERS then
                log("WARNING: UWEOnlineSessionSubsystem.MaxSessionPlayerCount changed to %d! Re-patching...", val)
                apply_existing_patches()
            end
        end
        local ags = FindFirstOf("GameSession")
        if ags then
            local val = read_numeric_field(ags, "MaxPlayers")
            if val and val ~= TARGET_MAX_PLAYERS then
                log("WARNING: GameSession.MaxPlayers changed to %d! Re-patching...", val)
                apply_existing_patches()
            end
        end
        ExecuteWithDelay(MONITOR_DELAY_MS, monitor_loop)
    end
    ExecuteWithDelay(MONITOR_DELAY_MS, monitor_loop)
end

-- Read the saved value from SN2ModSettings SharedVariable and update TARGET_MAX_PLAYERS.
-- Called at startup (before the first apply_existing_patches) so the correct player
-- count is used from the very first patch, not just after the first LoopAsync tick.
local function load_from_shared()
    if not ModRef then return end
    local ok, raw = pcall(function()
        return ModRef:GetSharedVariable("SN2ModSettings/TooManyDivers/MaxPlayers")
    end)
    if not ok or raw == nil or type(raw) ~= "number" then return end
    -- Le manifest stocke value/100 (compensation du facteur x100 du widget d'affichage)
    local value = math.floor(raw * 100 + 0.5)
    if value < MIN_MAX_PLAYERS or value > MAX_MAX_PLAYERS then return end
    if value == TARGET_MAX_PLAYERS then return end
    TARGET_MAX_PLAYERS = value
    log("MaxPlayers initialise depuis SN2ModSettings: %d", TARGET_MAX_PLAYERS)
end

local function bootstrap()
    for _, config in ipairs(CLASS_DEFS) do
        register_new_object_notify(config)
    end
    load_from_shared() -- Seed TARGET_MAX_PLAYERS from SN2ModSettings before first patch
    apply_existing_patches()
    try_register_host_session_hook()
    start_monitor() -- Start optional monitor
    log("Loaded. Target max players = %d", TARGET_MAX_PLAYERS)
end

ExecuteInGameThread(bootstrap)

ExecuteWithDelay(PATCH_RETRY_DELAY_MS_1, function()
    ExecuteInGameThread(apply_existing_patches)
    ExecuteInGameThread(try_register_host_session_hook)
end)

ExecuteWithDelay(PATCH_RETRY_DELAY_MS_2, function()
    ExecuteInGameThread(apply_existing_patches)
end)
ExecuteWithDelay(PATCH_RETRY_DELAY_MS_3, function()
    ExecuteInGameThread(apply_existing_patches)
end)

LoopAsync(1000, function()
    if not ModRef then return end
    local ok, raw = pcall(function()
        return ModRef:GetSharedVariable("SN2ModSettings/TooManyDivers/MaxPlayers")
    end)
    if not ok or raw == nil or type(raw) ~= "number" then return end
    -- Le manifest stocke value/100 (compensation du facteur x100 du widget d'affichage)
    local value = math.floor(raw * 100 + 0.5)
    if value < MIN_MAX_PLAYERS or value > MAX_MAX_PLAYERS then return end
    if value == TARGET_MAX_PLAYERS then return end
    TARGET_MAX_PLAYERS = value
    ExecuteInGameThread(function()
        log("MaxPlayers mis a jour via SN2ModSettings: %d", TARGET_MAX_PLAYERS)
        apply_existing_patches()
    end)
end)