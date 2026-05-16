-- Manifest pre-ship pour SN2ModSettings.
-- Ce fichier doit etre installe dans : ue4ss/Mods/SN2ModSettings/registrations/TooManyDivers.lua
--
-- Il est ecrase a chaque lancement par TooManyDivers/Scripts/main.lua pour rester
-- synchronise avec config/settings.json, mais sa presence a l'installation evite
-- de devoir lancer le jeu deux fois.
return {
    name    = "TooManyDivers",
    display = "Too Many Divers",
    settings = {
        {
            key         = "MaxPlayers",
            title       = "Max Players",
            description = "Nombre maximum de joueurs par session (4 a 64). Les changements s appliquent en temps reel sans redemarrer.",
            type        = "slider",
            format      = "integer",
            default     = 16,
            min         = 4,
            max         = 64,
            step        = 1,
        },
    },
}
