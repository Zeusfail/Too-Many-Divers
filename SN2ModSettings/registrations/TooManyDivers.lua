-- Manifest pre-ship pour SN2ModSettings.
-- Ce fichier doit etre installe dans : ue4ss/Mods/SN2ModSettings/registrations/TooManyDivers.lua
--
-- Il est ecrase a chaque lancement par TooManyDivers/Scripts/main.lua pour rester
-- synchronise avec config/settings.json, mais sa presence a l'installation evite
-- de devoir lancer le jeu deux fois.
--
-- Valeurs stockees divises par 100 : le widget ApplicationScaleSlider affiche
-- value*100, donc 0.16 -> affichage "16 joueurs", 2.55 -> "255 joueurs".
return {
    name    = "TooManyDivers",
    display = "Too Many Divers",
    settings = {
        {
            key         = "MaxPlayers",
            title       = "Max Players",
            description = "Nombre maximum de joueurs par session (2 a 64). Les changements s appliquent en temps reel sans redemarrer.",
            type        = "slider",
            default     = 0.16,
            min         = 0.04,
            max         = 0.64,
            step        = 0.01,
        },
    },
}
