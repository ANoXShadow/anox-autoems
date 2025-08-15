--[[------------------------>FOR ASSISTANCE,SCRIPTS AND MORE JOIN OUR DISCORD<-------------------------------------
 ________   ________    ________      ___    ___      ________   _________   ___  ___   ________   ___   ________     
|\   __  \ |\   ___  \ |\   __  \    |\  \  /  /|  ||  |\   ____\ |\___   ___\|\  \|\  \ |\   ___ \ |\  \ |\   __  \    
\ \  \|\  \\ \  \\ \  \\ \  \|\  \   \ \  \/  / /  ||  \ \  \___|_\|___ \  \_|\ \  \\\  \\ \  \_|\ \\ \  \\ \  \|\  \   
 \ \   __  \\ \  \\ \  \\ \  \\\  \   \ \    / /   ||   \ \_____  \    \ \  \  \ \  \\\  \\ \  \ \\ \\ \  \\ \  \\\  \  
  \ \  \ \  \\ \  \\ \  \\ \  \\\  \   /     \/    ||    \|____|\  \    \ \  \  \ \  \\\  \\ \  \_\\ \\ \  \\ \  \\\  \ 
   \ \__\ \__\\ \__\\ \__\\ \_______\ /  /\   \    ||      ____\_\  \    \ \__\  \ \_______\\ \_______\\ \__\\ \_______\
    \|__|\|__| \|__| \|__| \|_______|/__/ /\ __\   ||     |\_________\    \|__|   \|_______| \|_______| \|__| \|_______|
                                     |__|/ \|__|   ||     \|_________|                                                 
------------------------------------->(https://discord.gg/gbJ5SyBJBv)---------------------------------------------------]]
Config = {}
Config.Debug = true
Config.Framework = 'auto' -- 'auto', 'esx', 'qb', 'qbx'
Config.Language = 'en'
Config.Cost = 500
Config.MaxActiveEMS = 5
Config.EMSCount = 1
Config.CallCooldown = 300000
Config.ReviveTime = 10000
Config.NPCDespawnTime = 30000
Config.ReviveAnimDict = 'mini@cpr@char_a@cpr_str'
Config.ReviveAnimName = 'cpr_pumpchest'

Config.UISystem = {
    Notify = 'ox',           -- 'ox'
}

Config.EMSModels = {
    's_m_m_paramedic_01',
    's_f_y_scrubs_01'
}

Config.BlacklistedJobs = {
    'gang',
    'police'
}

Config.BlacklistedLocations = {
    {coords =  vector3(102.66, -1935.22, 20.80) , radius = 50.0, name = "Grove Street"}
}

Config.EMSBlip = {
    sprite = 61,
    color = 1,
    scale = 0.8,
    shortRange = true,
    name = "Auto EMS"
}