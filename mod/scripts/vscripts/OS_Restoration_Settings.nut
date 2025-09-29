global function OS_Settings_Init

void function OS_Settings_Init()
{
	ModSettings_AddModTitle( "OS Restoration V2" )
	ModSettings_AddModCategory( "Voicelines" )
	ModSettings_AddEnumSetting( "OS.Enable_Battery_Radar", "Enable Battery Radar Voicelines", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Battery_Received", "Enable Battery Received Voicelines", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Core_Offline", "Enable Core Offline Voicelines", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Disembark", "Enable Disembark Voicelines", [ "#SETTING_OFF", "#SETTING_ON" ] )

	ModSettings_AddModCategory( "Misc" )
	ModSettings_AddEnumSetting( "OS.Enable_Betty_Alarm", "Enable Warning Alarm", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Force_Betty_Alarm", "Force Warning Alarm to Play on Every Voiceline", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Doom_Alarm", "Enable Doomed Alarm", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Rodeo_Alarm", "Enable Rodeo Alarm", [ "#SETTING_OFF", "#SETTING_ON" ] )
	ModSettings_AddEnumSetting( "OS.Enable_Cockpit_Sparks", "Enable Doomed Spark FXs", [ "#SETTING_OFF", "#SETTING_ON" ] )
}