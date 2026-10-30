local MOD_TAG = "[TooManyDivers]"
local MOD_VERSION = "1.2.1"
local GITHUB_REPO = "Zeusfail/Too-Many-Divers"

local DEFAULT_MAX_PLAYERS = 16
local MIN_MAX_PLAYERS = 4
local MAX_MAX_PLAYERS = 64

local INIT_GUARD = "__SN2_MORE_PLAYERS_INITIALIZED"
local MANIFEST_PATH = "./ue4ss/Mods/SN2ModSettings/registrations/TooManyDivers.lua"
local SHARED_MAX_PLAYERS = "SN2ModSettings/TooManyDivers/MaxPlayers"
local PATCH_RETRY_DELAY_MS = 1000
local SHARED_POLL_MS = 1000

local function log(message, ...)
    print(string.format("%s %s\n", MOD_TAG, string.format(message, ...)))
end

local function read_config_content()
    local src = debug.getinfo(1, "S").source
    local script_dir = src:match("^@?(.+)[/\\][^/\\]+$")
    if not script_dir then
        log("Could not resolve config path, using defaults")
        return nil
    end
    local file = io.open(script_dir .. "\\..\\config\\settings.json", "r")
    if not file then
        log("config/settings.json not found, using defaults")
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function load_max_players(content)
    if not content then return DEFAULT_MAX_PLAYERS end
    local raw = content:match('"MaxPlayers"%s*:%s*(%d+)')
    local value = raw and tonumber(raw)
    if not value then
        log("MaxPlayers missing from config, using default (%d)", DEFAULT_MAX_PLAYERS)
        return DEFAULT_MAX_PLAYERS
    end
    if value < MIN_MAX_PLAYERS or value > MAX_MAX_PLAYERS then
        log("MaxPlayers=%d out of range [%d-%d], using default (%d)",
            value, MIN_MAX_PLAYERS, MAX_MAX_PLAYERS, DEFAULT_MAX_PLAYERS)
        return DEFAULT_MAX_PLAYERS
    end
    return value
end

local TARGET_MAX_PLAYERS = load_max_players(read_config_content())

local function write_sn2modsettings_manifest()
    local dir = MANIFEST_PATH:match("(.*[/\\])")
    os.execute('mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul')
    local f = io.open(MANIFEST_PATH, "w")
    if not f then
        log("SN2ModSettings manifest: cannot write %s", MANIFEST_PATH)
        return
    end
    f:write(string.format([=[return {
    name            = "TooManyDivers",
    display         = "Too Many Divers",
    version         = "%s",
    github          = "%s",
    nexus_id        = "73",
    settings = {
        {
            key         = "MaxPlayers",
            title       = "Max Players",
            description = "Maximum number of players per session (%d to %d). Changes apply in real time without restarting.",
            type        = "slider",
            format      = "integer",
            default     = %d,
            min         = %d,
            max         = %d,
            step        = 1,
        },
    },
}
]=], MOD_VERSION, GITHUB_REPO, MIN_MAX_PLAYERS, MAX_MAX_PLAYERS,
        TARGET_MAX_PLAYERS, MIN_MAX_PLAYERS, MAX_MAX_PLAYERS))
    f:close()
end

write_sn2modsettings_manifest()

if rawget(_G, INIT_GUARD) then return end
_G[INIT_GUARD] = true

local CLASS_DEFS = {
    {
        short_name = "SN2GameSession",
        class_name = "/Script/Subnautica2.SN2GameSession",
        cdo_name   = "/Script/Subnautica2.Default__SN2GameSession",
        fields     = { "MaxPlayers" }
    },
    {
        short_name = "UWEOnlineSessionSubsystem",
        class_name = "/Script/UWESonar.UWEOnlineSessionSubsystem",
        cdo_name   = "/Script/UWESonar.Default__UWEOnlineSessionSubsystem",
        fields     = { "MaxSessionPlayerCount" }
    },
    {
        -- MaxPlayerCount est herite de UCommonSession_HostSessionRequest.
        short_name = "UWEHostSessionRequest",
        class_name = "/Script/UWESonar.UWEHostSessionRequest",
        cdo_name   = "/Script/UWESonar.Default__UWEHostSessionRequest",
        fields     = { "MaxPlayerCount" }
    },
    {
        short_name = "GameSession",
        class_name = "/Script/Engine.GameSession",
        cdo_name   = "/Script/Engine.Default__GameSession",
        fields     = { "MaxPlayers" }
    }
}

local notify_registered = {}
local cdo_warnings_logged = {}

-- Instances vues par NotifyOnNewObject : evite FindAllOf/FindFirstOf hors du demarrage,
-- qui provoquait des access violations apres un passage du GC.
local cached_instances = {}

local function is_valid(obj)
    if not obj then return false end
    local ok, valid = pcall(function()
        return obj.IsValid and obj:IsValid()
    end)
    return ok and valid == true
end

local function read_numeric_field(obj, field_name)
    if not is_valid(obj) then return nil end
    local ok, value = pcall(function() return obj[field_name] end)
    if ok and type(value) == "number" then return value end
    return nil
end

local function set_numeric_field(obj, field_name, scope)
    local current = read_numeric_field(obj, field_name)
    if current == nil then return false end
    if current == TARGET_MAX_PLAYERS then return true end
    local ok, err = pcall(function() obj[field_name] = TARGET_MAX_PLAYERS end)
    if not ok then
        log("Failed to write %s.%s: %s", scope, field_name, tostring(err))
        return false
    end
    log("%s.%s: %d -> %d", scope, field_name, current, TARGET_MAX_PLAYERS)
    return true
end

local function patch_object(obj, config, scope)
    if not is_valid(obj) then return false end
    local patched = false
    for _, field_name in ipairs(config.fields) do
        if set_numeric_field(obj, field_name, scope) then patched = true end
    end
    return patched
end

local function log_cdo_warning_once(key, message, ...)
    if cdo_warnings_logged[key] then return end
    cdo_warnings_logged[key] = true
    log(message, ...)
end

local function patch_cdo(config)
    local ok, obj = pcall(function() return StaticFindObject(config.cdo_name) end)
    if not ok then
        log_cdo_warning_once(config.cdo_name .. "#err",
            "CDO %s: StaticFindObject errored: %s", config.short_name, tostring(obj))
        return
    end
    if not is_valid(obj) then
        log_cdo_warning_once(config.cdo_name .. "#missing",
            "CDO %s: not found at %s", config.short_name, config.cdo_name)
        return
    end
    for _, field_name in ipairs(config.fields) do
        local ok_read, value = pcall(function() return obj[field_name] end)
        if not ok_read then
            log_cdo_warning_once(config.cdo_name .. "." .. field_name .. "#err",
                "CDO %s.%s: read errored: %s", config.short_name, field_name, tostring(value))
        elseif type(value) ~= "number" then
            log_cdo_warning_once(config.cdo_name .. "." .. field_name .. "#nan",
                "CDO %s.%s: non-numeric (type=%s)", config.short_name, field_name, type(value))
        end
    end
    patch_object(obj, config, "CDO " .. config.short_name)
end

-- Appelee une seule fois, au demarrage : FindAllOf n'y est pas risque.
local function patch_instances(config)
    local ok, objects = pcall(function() return FindAllOf(config.short_name) end)
    if not ok or not objects then return end
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

local function apply_cached_patches()
    for _, config in ipairs(CLASS_DEFS) do
        patch_cdo(config)
        local obj = cached_instances[config.short_name]
        if obj then
            local ok = pcall(function()
                if is_valid(obj) then
                    patch_object(obj, config, "Cached " .. config.short_name)
                else
                    cached_instances[config.short_name] = nil
                end
            end)
            if not ok then
                cached_instances[config.short_name] = nil
            end
        end
    end
end

-- HostSessionAsync est appele en C++ natif (un RegisterHook ne se declenche jamais) :
-- la creation de la requete est le seul point d'entree avant la creation de la session.
local function on_new_host_request(new_obj, config)
    ExecuteInGameThread(function()
        pcall(function()
            if not is_valid(new_obj) then return end
            patch_object(new_obj, config, "Next tick " .. config.short_name)
        end)
    end)
end

local function register_new_object_notify(config)
    if notify_registered[config.class_name] then return end
    local ok, err = pcall(function()
        NotifyOnNewObject(config.class_name, function(new_obj)
            cached_instances[config.short_name] = new_obj
            patch_object(new_obj, config, "New " .. config.short_name)
            if config.short_name == "UWEHostSessionRequest" then
                on_new_host_request(new_obj, config)
            end
        end)
    end)
    if ok then
        notify_registered[config.class_name] = true
    else
        log("Failed to arm NotifyOnNewObject for %s: %s", config.short_name, tostring(err))
    end
end

-- Retourne true si la valeur SN2ModSettings a change TARGET_MAX_PLAYERS.
local function load_from_shared()
    if not ModRef then return false end
    local ok, raw = pcall(function() return ModRef:GetSharedVariable(SHARED_MAX_PLAYERS) end)
    if not ok or type(raw) ~= "number" then return false end
    local value = math.floor(raw + 0.5)
    if value < MIN_MAX_PLAYERS or value > MAX_MAX_PLAYERS or value == TARGET_MAX_PLAYERS then return false end
    TARGET_MAX_PLAYERS = value
    log("MaxPlayers = %d (SN2ModSettings)", TARGET_MAX_PLAYERS)
    return true
end

local function bootstrap()
    for _, config in ipairs(CLASS_DEFS) do
        register_new_object_notify(config)
    end
    -- Instances creees avant le chargement du mod (jamais vues par NotifyOnNewObject).
    for _, config in ipairs(CLASS_DEFS) do
        local ok, obj = pcall(function() return FindFirstOf(config.short_name) end)
        if ok and is_valid(obj) then
            cached_instances[config.short_name] = obj
        end
    end
    load_from_shared()
    apply_existing_patches()
    log("Loaded. Target max players = %d", TARGET_MAX_PLAYERS)
end

ExecuteInGameThread(bootstrap)

-- Certains CDOs ne sont pas encore prets au premier passage.
ExecuteWithDelay(PATCH_RETRY_DELAY_MS, function()
    ExecuteInGameThread(function()
        for _, config in ipairs(CLASS_DEFS) do
            patch_cdo(config)
        end
    end)
end)

LoopAsync(SHARED_POLL_MS, function()
    if load_from_shared() then
        ExecuteInGameThread(apply_cached_patches)
    end
end)
