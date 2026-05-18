-- Manifest pre-ship pour SN2ModSettings.
-- Ce fichier doit etre installe dans : ue4ss/Mods/SN2ModSettings/registrations/TooManyDivers.lua
--
-- Il est ecrase a chaque lancement par TooManyDivers/Scripts/main.lua pour rester
-- synchronise avec config/settings.json, mais sa presence a l'installation evite
-- de devoir lancer le jeu deux fois.
return {
    name            = "TooManyDivers",
    display         = "Too Many Divers",
    version         = "1.2.0",
    github          = "Zeusfail/Too-Many-Divers",
    nexus_id        = "73",
    settings = {
        {
            key         = "MaxPlayers",
            title       = "Max Players",
            description = "Maximum number of players per session (4 to 64). Changes apply in real time without restarting.",
            type        = "slider",
            format      = "integer",
            default     = 16,
            min         = 4,
            max         = 64,
            step        = 1,
        },
    },
}
