-- Manifest pre-ship pour SN2ModSettings.
-- Ce fichier doit etre installe dans : ue4ss/Mods/SN2ModSettings/registrations/TooManyDiversVoice.lua
--
-- Il est ecrase a chaque lancement par TooManyDiversVoice/Scripts/main.lua pour rester
-- synchronise avec config/settings.json, mais sa presence a l'installation evite
-- de devoir lancer le jeu deux fois.
return {
    name            = "TooManyDiversVoice",
    display         = "Too Many Divers - Voice",
    version         = "1.0.0",
    nexus_id        = "73",
    settings = {
        {
            key         = "Enabled",
            title       = "Extra voice slots",
            description = "Adds the unused proximity voice chat slots so more than 4 players can hear each other. Every player needs this mod. Applies the next time you load a game.",
            type        = "toggle",
            default     = true,
        },
        {
            key         = "MaxVoicePlayers",
            title       = "Max voice players",
            description = "Players who can hear each other in proximity voice chat (4 to 9, game default 4). Applies the next time you load a game.",
            type        = "slider",
            format      = "integer",
            default     = 9,
            min         = 4,
            max         = 9,
            step        = 1,
            enabled_by  = "Enabled",
        },
    },
}
