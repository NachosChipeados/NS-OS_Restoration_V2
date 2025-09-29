
global function OS_Init
global function OS_RegisterCustomConversations
global function OS_BatteryReceived

global function CheckEntityBattery
global function CheckNormalVSGenericDiag
global function OS_PlayDiagAfterAlarm
global function TitanCockpit_PlayDialogAfterAlarm
global function PlayBettyAlarm

global function OS_Print

struct
{
	bool is_boarded = false
	bool registeredCoreOffline = false
} file

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

global bool alarmIsPlaying = false
global bool rodeoAlarmIsPlaying = false

global const float OS_lowestDebounce = 0.1
global const float OS_lowDebounce = 1
global const float OS_smallDebounce = 3
global const float OS_midDebounce = 5
global const float OS_highDebounce = 10
global const float OS_highestDebounce = 15

global const int VO_PRIORITY_TITANOS_LOWEST = 200
global const int VO_PRIORITY_TITANOS_LOW = 400
global const int VO_PRIORITY_TITANOS_MID = 1000
global const int VO_PRIORITY_TITANOS_HIGH = 2000 // From _settings.gnut

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////|

void function OS_Init()
{
	if ( IsLobby() )
		return

	OS_RegisterCustomConversations()
	AddCallback_PlayerClassChanged( OS_Running )
}

// NOTE: if you wanna make something similar, DONT call the function BEFORE mapspawn
// or else you WILL crash when playing the dialogue!!!
//
//	"RunOn": "CLIENT",
//	"ClientCallback": {
// 		"After": "OS_Init"
//	}

void function OS_RegisterCustomConversations()
{
	//RegisterConversation( "diag_gs_titan" + modifiedAliasSuffix + "_enemyTitanfall", VO_PRIORITY_PLAYERSTATE )

	//-------------------------
	// Batteries
	//-------------------------

	RegisterConversation( "batteryGotShieldActivated", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "batteryGotShieldEnabled", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "batteryNearDisembark", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "batteryNearGeneric", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "batteryStolenByPilot", VO_PRIORITY_TITANOS_LOW, OS_smallDebounce )
	RegisterConversation( "batteryStolenGnrc", VO_PRIORITY_TITANOS_LOW, OS_smallDebounce )

	// BT only
	RegisterConversation( "batteryUsed", VO_PRIORITY_TITANOS_LOW, OS_smallDebounce )

	// TODO: these callbacks are not arrays by default. Should pr???

	// Received battery from Pilot
	AddEventNotificationCallback( eEventNotifications.Rodeo_PilotAppliedBatteryToYou, OS_BatteryReceived )
	AddEventNotificationCallback( eEventNotifications.Rodeo_PilotAppliedBatteryToYourPetTitan, OS_BatteryReceived )

	// Applied battery to your own Titan
	AddEventNotificationCallback( eEventNotifications.Rodeo_YouEmbarkedWithABattery, OS_BatteryReceived )
	AddEventNotificationCallback( eEventNotifications.Rodeo_TitanPickedUpBattery, OS_BatteryReceived )

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	//-------------------------
	// Titan cores
	//-------------------------

	RegisterConversation( "burstCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "dashCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "flameWaveCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "laserCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "salvoCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )
	RegisterConversation( "upgradeCoreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )

	// BT only
	RegisterConversation( "coreOffline", VO_PRIORITY_TITANOS_LOWEST, OS_smallDebounce )

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	//-------------------------
	// Misc
	//-------------------------

	RegisterConversation( "doomEjectRec", VO_PRIORITY_TITANOS_LOW, OS_smallDebounce )
	RegisterConversation( "enemyTitanfall", VO_PRIORITY_TITANOS_HIGH, OS_smallDebounce )
	RegisterConversation( "hostileLeftHull", VO_PRIORITY_TITANOS_LOW, OS_highDebounce )
	RegisterConversation( "rodeoWarningGnrc", VO_PRIORITY_TITANOS_HIGH, OS_smallDebounce )

	//BT only
	RegisterConversation( "diag_sp_pilotLink_WD143a_07_01_mcor_bt", VO_PRIORITY_TITANOS_HIGH, OS_smallDebounce ) // Pilot, enemy Titanfall detected.
	RegisterConversation( "diag_sp_fogBattle_BE401_01_01_mcor_bt", VO_PRIORITY_TITANOS_HIGH, OS_midDebounce ) // Caution: Anomaly detected. Possible hostile Titan.

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	//-------------------------
	// Overrides
	//-------------------------

	SetConversationDebounce( "bettyAlarm", OS_lowDebounce ) // 0.1 -> 3

	SetConversationPriority( "embark", VO_PRIORITY_TITANOS_LOW - 1 ) // 
}

void function OS_Running( entity player )
{
	if ( !IsValid( player ) || player != GetLocalViewPlayer() )
		return

	if ( !IsAlive( player ) || IsSpectating() || IsWatchingKillReplay() )
		return

	string newClass = player.GetPlayerClass()

	if ( newClass == level.pilotClass )
	{
		if ( file.is_boarded )
		{
			OS_Disembark( player )

			file.is_boarded = false
		}
	}
	else if ( newClass == "titan" )
	{
		file.is_boarded = true

		// BTs pilot link sequence switches to Titan twice, for some reason?????? Kicking you to main menu
		// This fixes that
		if ( !file.registeredCoreOffline )
		{
			RegisterConCommandTriggeredCallback( "+offhand3", OS_CoreOffline )
			file.registeredCoreOffline = true
		}

		thread OS_DoomBeep( player )

		// TODO:
		//thread OS_PredCannonVO( player )
	}

	thread OS_BatteryRadar( player )
	thread OS_RodeoChecker( player )
}

void function OS_BatteryRadar( entity player )
{
	if ( !GetConVarBool( "OS.Enable_Battery_Radar" ) )
		return

	// BT doesnt have battery voicelines
	if ( IsSingleplayer() )
		return

	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "TitanEjectionStarted" )

	//player.EndSignal( "OnChangedPlayerClass" ) //???
	//player.EndSignal( "SettingsChanged" )

	player.EndSignal( "DisembarkingTitan" )
	//player.EndSignal( "OnSyncedMelee" )

	wait 3
	OS_Print( "Battery radar is now running" )

	while ( true )
	{
		while ( !player.IsTitan() && !IsValid( player.GetPetTitan() ) )
		{
			wait 3
		}

		array<entity> batteries = GetClientEntArrayBySignifier( "item_titan_battery" )
		//OS_Print( "Total batteries now is " + batteries.len() )

		float delay = 30

		foreach ( entity battery in batteries )
		{
			wait 2
			if ( !IsValid( battery ) )
				break

			float dist3d = Length( player.GetOrigin() - ( battery.GetOrigin() ) )
			//OS_Print ("Bossplayer of the battery is " + battery.GetParent())

			if ( IsValid( battery.GetParent() ) )
				break

			if ( file.is_boarded )
			{
				if ( dist3d < 500 )
				{
					//OS_PlayConversation( soundAlias_BatteryNearDisembark, player, 275 )
					TitanCockpit_PlayDialog( player, "batteryNearDisembark" )
					wait delay
				}
				else if ( dist3d < 2600 )
				{
					//OS_PlayConversation( soundAlias_batteryNearGeneric, player, 275 )
					TitanCockpit_PlayDialog( player, "batteryNearGeneric" )
					wait delay
				}
			}
			else
			{
				if ( dist3d < 1000 )
				{
					//OS_PlayConversation( soundAlias_batteryNearGeneric, player, 275 )
					TitanCockpit_PlayDialog( player, "batteryNearGeneric" )
					wait delay
				}
			}
		}
		wait 2
	}

	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Battery radar has ended" )
		}
	)
}

void function OS_BatteryReceived( entity friendlyPilot, var eventVal )
{
//	if ( !IsValid( friendlyPilot ) )
//		return

	if ( !GetConVarBool( "OS.Enable_Battery_Received" ) )
		return

	entity player = GetLocalClientPlayer()

	if ( !player.IsTitan() && !IsValid( player.GetPetTitan() ) )
		return

	entity titan = player.IsTitan() ? player : player.GetPetTitan()
	string titanName = GetTitanCharacterName( titan )

	if ( IsSingleplayer() )
	{
		if ( CoinFlip() )
			TitanCockpit_PlayDialog( player, "batteryGot" )
		else
			TitanCockpit_PlayDialog( player, "batteryUsed" )
	}
	else
	{
		// Monarch has voicelines AND sound events for these, but they dont play for some reason
		if ( titanName == "vanguard" )
			TitanCockpit_PlayDialog( player, "batteryGot" )
		else
		{
			switch( RandomInt( 3 ) )
			{
				// Theres also "batteryGotAllKitsActivated", "batteryGotAllKitsEnabled", "batteryGotPowerActivated", "batteryGotPowerEnabled"
				// "batteryGotSpeedActivated", "batteryGotSpeedEnabled", but i dont think that they fit
				case 1:
					TitanCockpit_PlayDialog( player, "batteryGotShieldActivated" )
					break
				case 2:
					TitanCockpit_PlayDialog( player, "batteryGotShieldEnabled" )
					break

				default:
					TitanCockpit_PlayDialog( player, "batteryGot" )
					break
			}
		}
	}

	//PlayBatteryScreenFX( player, expect bool( eventVal ) )
}

// Mostly a copy of CheckCoreAvailable()
void function OS_CoreOffline( entity player )
{
	if ( !GetConVarBool( "OS.Enable_Core_Offline" ) )
		return

	if ( IsWatchingKillReplay() )
		return

	if ( !player.IsTitan() )
		return

	if ( player.ContextAction_IsActive() )
		return

	if ( IsInExecutionMeleeState( player ) )
		return

	if ( player.GetParent() != null )
		return

	entity soul = player.GetTitanSoul()

	if ( soul == null )
		return

	if ( soul.IsEjecting() )
		return

	if ( !IsCoreChargeAvailable( player, soul ) )
	{
		entity coreWeapon = player.GetOffhandWeapon( OFFHAND_EQUIPMENT )
		string className = coreWeapon.GetWeaponClassName()

		string diag

		switch ( className )
		{
			case "mp_titancore_amp_core":
				diag = "burstCoreOffline"
				break

			case "mp_titancore_dash_core":
				diag = "dashCoreOffline"
				break

			case "mp_titancore_flame_wave":
			case "mp_titancore_storm_core": // Archon
				diag = "flameWaveCoreOffline"
				break

			case "mp_titancore_flight_core":
			case "mp_titancore_barrage_core": // Brute-4
				diag = "flightCoreOffline"
				break

			case "mp_titancore_laser_cannon":
				diag = "laserCoreOffline"
				break

			case "mp_titancore_salvo_core":
				diag = "salvoCoreOffline"
				break

			case "mp_titancore_shift_core":
			case "mp_titancore_berserk_core": // Havoc
				diag = "swordCoreOffline"
				break

			case "mp_titancore_siege_mode":
				diag = "smartCoreOffline"
				break

			case "mp_titancore_upgrade":
				diag = "upgradeCoreOffline"
				break

			default:
				return
				break
		}

		if ( IsSingleplayer() && ( RandomInt( 10 ) == 0 ) )
		{
			// Theres also some "coreNotReady" sounds, but unfortunately they dont have a sound event
			diag = "coreOffline"
		}

		EmitSoundOnEntity( player, "titan_dryfire" )
		TitanCockpit_PlayDialog( player, diag )
	}
}

void function OS_Disembark( entity player )
{
	OS_Print( "Disembarking..." )

	FadeOutSoundOnEntity( player, "boneyard_scr_bliskintro_foley_part1", 3.0 )
	FadeOutSoundOnEntity( player, "titan_alarm_loop", 3.0 )
	rodeoAlarmIsPlaying = false

	DeregisterConCommandTriggeredCallback( "+offhand3", OS_CoreOffline )
	file.registeredCoreOffline = false

	entity titan = player.GetPetTitan()

	if ( IsValid( titan ) && titan.GetTitanSoul().IsEjecting() == false )
	{
		if ( !GetConVarBool( "OS.Enable_Disembark" ) )
			return

		// Fix for BT playing disembark voicelines when the timeline is frozen
		// See GetEntityTimelinePosition() in sh_sp_timeshift.gnut, right at the bottom
		if ( GetMapName() == "sp_hub_timeshift" )
		{
			float z = player.GetOrigin().z
			if ( z < -6000 )
				return
		}

		TitanCockpit_PlayDialog( player, "disembark" )
	}
}

void function OS_DoomBeep( entity player )
{
	if ( !GetConVarBool( "OS.Enable_Doom_Alarm" ) )
		return

	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "TitanEjectionStarted" )

	OS_Print( "Doomed beep has started" )

	while ( file.is_boarded )
	{
		if ( GetDoomedState( player ) )
		{
			EmitSoundOnEntity( player, "boneyard_scr_bliskintro_foley_part1" )
			FadeOutSoundOnEntity( player, "titan_alarm_loop", 3.0 )
			rodeoAlarmIsPlaying = false

			thread OS_DoomSpark( player )

			break
		}
		WaitFrame()
	}

	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Doomed beep has ended" )
		}
	)
}

void function OS_DoomSpark( entity player )
{
	if ( !GetConVarBool( "OS.Enable_Cockpit_Sparks" ) )
		return

	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "TitanEjectionStarted" )

	wait 1

	float wait_time = 1.0
	int spark_count = 4

	OS_Print( "Doomed sparks has started" )

	while ( file.is_boarded )
	{
		if ( !GetConVarBool( "OS.Enable_Cockpit_Sparks" ) )
			break

		entity cockpit = player.GetCockpit()

		if ( !GetDoomedState( player ) )
			player.WaitSignal( "Doomed" )

		PlayCockpitSparkFX( cockpit, spark_count )

		//EmitSoundOnEntity( player, "Pilot_Mvmt_Execution_Cloak_AndroidSparks" ) // Too loud
		//EmitSoundOnEntity( player, "Timeshift_Emit_Sparks" ) // Too quiet
		//EmitSoundOnEntity( player, "titan_damage_spark" ) // Doesn't even play

		wait_time = RandomFloatRange( 1.5, 3.5 )
		spark_count = RandomIntRange( 4, 20 )

		wait wait_time
	}

	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Doomed sparks has ended" )
		}
	)
}

// TODO: this is still very similar to the original. Need to change it
// "yea, I spoke with frag about it, in his os restore mod, you can hear the voiceline for a low profile pilot disembarking earlier, they always know even with low profile"
// https://discord.com/channels/920776187884732556/1102373220121845880/1196010873962119289

void function OS_RodeoChecker( entity player )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "TitanEjectionStarted" )

	player.EndSignal( "DisembarkingTitan" )

	wait 1
	OS_Print( "Rodeo checker has started" )

	bool hostileOnBoard = false
	bool BoardedWithBattery = false
	entity prevrider

	while ( true ) //file.is_boarded
	{
		while ( !player.IsTitan() && !IsValid( player.GetPetTitan() ) )
		{
			wait 3
		}

		entity rider

		// Play voicelines on auto titan as well
		if ( player.IsTitan() || player.GetPetTitan() )
			rider = player.IsTitan() ? player.GetRodeoRider( 0 ) : player.GetPetTitan().GetRodeoRider( 0 )

		if ( rider == null )
		{
			//OS_Print("no current rodeo")

			if ( hostileOnBoard )
			{
				FadeOutSoundOnEntity( player, "titan_alarm_loop", 3.0 )

				//OS_Print("debug riderz 0")
				if ( !IsValid( prevrider ) )
				  break

				if( !BoardedWithBattery )
				{
					//OS_Print("debug riderz 1")

					wait 0.2
					bool currentlyWithBattery = CheckEntityBattery( prevrider )
					//OS_Print("the battery status of " + prevrider + "is " + currentlyWithBattery )
	
					if ( currentlyWithBattery )
					{
						CheckNormalVSGenericDiag( player, prevrider, "batteryStolenByPilot", "batteryStolenGnrc" )
					}
					else
					{
						wait 0.3
						if ( IsAlive( prevrider ) )
						{
							//OS_Print("debug riderz 3")
							TitanCockpit_PlayDialog( player, "hostileLeftHull" )
						}
						else
						{
							CheckNormalVSGenericDiag( player, prevrider, "killEnemyRodeo", "killEnemyRodeoGnrc" )
						}
					}
				}
				else
				{
					//OS_Print("debug riderz 7")
					if ( !IsValid( prevrider ) )
					{
						OS_Print("invalid rider")
						break
					}
					wait 0.3

					if ( IsAlive( prevrider ) )
					{
						//OS_Print("debug riderz 3")
						TitanCockpit_PlayDialog( player, "hostileLeftHull" )
					}
					else
					{
						CheckNormalVSGenericDiag( player, prevrider, "killEnemyRodeo", "killEnemyRodeoGnrc" )
					}
				}
			}

			hostileOnBoard = false
			prevrider = null
			BoardedWithBattery = false

		}
		else
		{
			if ( rider.GetTeam() != player.GetTeam() )
			{
				if ( !hostileOnBoard )
				{
					//OS_Print( "debug riderz 7" )
					BoardedWithBattery = CheckEntityBattery( rider )

					//OS_Print( "the current rider is " + rider + " with battery? " + CheckEntityBattery( rider ) )
					prevrider = rider
				}
				hostileOnBoard = true
			}
		}
		WaitFrame()
	}

	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Rodeo checker has ended" )
		}
	)
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool function CheckEntityBattery( entity rider )
{
	if ( !IsValid( rider ) )
		return false

	array<entity> batteries = GetClientEntArrayBySignifier( "item_titan_battery" )

	foreach ( battery in batteries )
	{
		if ( !IsValid( battery ) )
			return false

		if ( battery.GetParent() != null && battery.GetParent() == rider )
			return true
	}
	return false
}

void function CheckNormalVSGenericDiag( entity player, entity rider, string diag, string diagGnrc )
{
	if ( !IsValid( player ) )
		return

	if ( !IsValid( rider ) )
		return

	if ( RandomInt( 2 ) != 1 )
		TitanCockpit_PlayDialog( player, diagGnrc )
	else
	{
		if ( IsPilot( rider ) )
			TitanCockpit_PlayDialog( player, diag )
		else
			TitanCockpit_PlayDialog( player, diagGnrc )
	}
}

void function OS_PlayDiagAfterAlarm( entity player, string diag, int priority )
{
	thread PlayBettyAlarm( player )

	while ( alarmIsPlaying )
	{
		WaitFrame()
	}

	OS_PlayConversation( diag, player, priority )
}

// Gets called during TitanCockpit_PlayDialog()
void function TitanCockpit_PlayDialogAfterAlarm( entity player, string conversationName, int priority, string soundAlias )
{
	thread PlayBettyAlarm( player )

	while ( alarmIsPlaying )
	{
		WaitFrame()
	}

	entity weapon = player.GetOffhandWeapon( OFFHAND_EQUIPMENT )
	if ( IsValid( weapon ) )
		PlayOneLinerConversationOnEntWithPriority( conversationName, soundAlias, weapon, priority )
	else
		PlayOneLinerConversationOnEntWithPriority( conversationName, soundAlias, player, priority )
}

void function PlayBettyAlarm( entity player )
{
	if ( !IsValid( player ) )
		return

	if ( alarmIsPlaying )
		return

	string conversationName = "bettyAlarm"
	string soundAlias_BettyAlarm = GenerateTitanOSAlias( player, conversationName )
	float alarmBeepDuration = GetSoundDuration( soundAlias_BettyAlarm )

	alarmIsPlaying = true

	//EmitSoundOnEntity( player, soundAlias_BettyAlarm )
	TitanCockpit_PlayDialog( player, conversationName )

	wait alarmBeepDuration + 0.1 // Extra 0.1 delay to prevent alarm from canceling the dialogue
	alarmIsPlaying = false
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void function OS_Print( string printString )
{
	if ( GetConVarBool( "OS.Print" ) )
		printt( printString )
}

// These are not used anymore, but they may come in handy so i kept them

void function OS_PlayConversation_Delayed( string soundAlias, entity ent, int priority, float delay )
{
	ent.EndSignal( "OnDestroy" )
	wait delay

	OS_PlayConversation( soundAlias, ent, priority )
}

// Used to be PlayOneLinerConversationOnEntWithPriority_custom()
void function OS_PlayConversation( string soundAlias, entity ent, int priority )
{
	//OS_Print( "PlayOneLinerConversationOnEntWithPriority, ConversationName: " + conversationName )

	if ( AbortConversationDueToPriority( priority ) )
	{
		//OS_Print( "Aborting conversation: " + conversationName + " due to higher priority conversation going on" )
		OS_Print( soundAlias + "aborted due to priority" )
		return
	}

	CancelConversation( ent )

	thread PlayOneLinerConversationOnEntWithPriority_internal( soundAlias, ent, priority ) // Only thread this off once we've done the priority check since threading is expensive
}
