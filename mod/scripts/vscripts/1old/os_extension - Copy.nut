
global function OS_Init
global function PlayOneLinerConversationOnEntWithPriority_custom
global function CheckPlayerNameBattery

struct
{
	bool is_boarded = false
	bool once = false
	bool music = false

	entity prevRider = null
}file

global bool alarmIsPlaying = false
global int alarmDamage = 0

void function OS_Init()
{
	if ( IsLobby() )
		return

	AddCallback_LocalClientPlayerSpawned( OS_Running )
}

void function OS_Running( entity player )
{
	player.EndSignal( "OnDeath" )

	OS_Print( "OS is now running" )

	while ( true )
	{
		WaitFrame()

		if ( !IsValid( player ) )
			return
		
		//OS_Print( "Batteries " + GetClientEntArrayBySignifier( "item_titan_battery" ).len() )

		if ( player.IsTitan() )
		{
			if ( !file.once )
			{
				OS_Print( "Boarded.." )
				file.is_boarded = true
				file.once = true
				OS_Print( "once is " + file.once )

				thread OS_BatteryRadar( player )
				thread OS_DamageAlarm( player )
				thread OS_RodeoChecker( player )
				thread OS_DoomBeep( player )
			}
		}
		else if ( ( player.GetPetTitan() != null ) )
		{
			if ( file.is_boarded )
			{
				file.is_boarded = false
				file.once = false
				file.music = true
				OS_Print( "Disembarking..." )
	
				if ( player.GetPetTitan().GetTitanSoul().IsEjecting() == false )
				{
					// Fix for BT playing disembark voicelines when the timeline is frozen
					if ( GetMapName() == "sp_hub_timeshift" )
					{
						float z = player.GetOrigin().z
						if ( z < -6000 )
							break
					}

					TitanCockpit_PlayDialog( GetLocalViewPlayer(), "disembark" )
				}
			}

			if ( !file.music )
			{
				/*
				wait 0.2
				thread PlayOneLinerConversationOnEntWithPriority_custom( "music_wilds_16d_embark", player, 1275 )
				OS_Print( "Playing music" )
				thread FadeOutSoundOnEntity(player,"music_wilds_16d_embark",2)
				*/
	
				file.music = true
			}
		}
		else
		{
			//OS_Print("hello peter 3")
			file.is_boarded = false
			file.once = false
			file.music = false
		}
	}
}

void function OS_BatteryRadar( entity player )
{
	// BT doesnt have battery voicelines
	if ( IsSingleplayer() )
		return

	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )
	//player.EndSignal( "DisembarkingTitan" )
	player.EndSignal( "OnSyncedMelee" )

	wait 3

	if ( !IsValid( player ) )
		return

	OS_Print( "Battery radar is now running" )
	string conversationName = "batteryNearDisembark"
	string soundAlias = GenerateTitanOSAlias_custom( player, conversationName )
	string conversationName2 = "batteryNearGeneric"
	string soundAlias2 = GenerateTitanOSAlias_custom( player, conversationName2 )

	while ( true )
	{
		array<entity> batteries = GetClientEntArrayBySignifier( "item_titan_battery" )
		//OS_Print( "Total batteries now is " + batteries.len() )
		foreach ( entity battery in batteries )
		{
			if ( !IsValid(battery) )
				break

			float dist3d = Length( player.GetOrigin() - ( battery.GetOrigin() ) )
			//OS_Print ("Bossplayer of the battery is " + battery.GetParent())

			if ( battery.GetParent() != null )
				break

			if ( file.is_boarded )
			{
				if ( dist3d < 500 )
				{
					string conversationName = "batteryNearDisembark"
					thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias, player, 275 )
					wait 15
				}
				else if ( dist3d < 2600 )
				{
					string conversationName = "batteryNearGeneric"
					thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias2, player, 275 )
					wait 15
				}
			}
			else
			{
				if ( dist3d < 1000 )
				{
					string conversationName = "batteryNearGeneric"
					thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias2, player, 275 )
					wait 15
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

string function GenerateTitanOSAlias_custom( entity player, string aliasSuffix )
{
	//HACK: Temp fix for blocker bug. Fixing correctly next.
	if ( IsSingleplayer() )
	{
		return "diag_gs_titanBt_" + aliasSuffix
	}
	else
	{
		entity titan
		if ( player.IsTitan() )
			titan = player
		else
			titan = player.GetPetTitan()

		Assert( IsValid( titan ) )
		string titanCharacterName = GetTitanCharacterName_custom( titan )
		string primeTitanString = ""

		if ( IsTitanPrimeTitan_custom( titan ) )
			primeTitanString = "_prime"

		string modifiedAlias = "diag_gs_titan" + titanCharacterName + primeTitanString + "_" + aliasSuffix
		
		return modifiedAlias
	}
	unreachable
}

bool function IsTitanPrimeTitan_custom( entity titan )
{
	Assert( titan.IsTitan() )
	string setFile

	if( !IsValid( titan ) )
	{
		OS_Print( "Null failsafe for prime is working" )
		return false
	}

	if ( titan.IsPlayer() )
	{
		setFile = titan.GetPlayerSettings()
	}
	else
	{
		string aiSettingsFile = titan.GetAISettingsName()
		setFile = expect string( Dev_GetAISettingByKeyField_Global( aiSettingsFile, "npc_titan_player_settings" ) )
	}

	return Dev_GetPlayerSettingByKeyField_Global( setFile, "isPrime" ) == 1
}

string function GetTitanCharacterName_custom( entity titan )
{
	Assert( titan.IsTitan() )

	string setFile
	if ( !IsValid( titan ) )
	{
		OS_Print( "Null failsafe for character name is working" )
		return ""
	}
	if ( titan.IsPlayer() )
	{
		setFile = titan.GetPlayerSettings()
	}
	else
	{
		string aiSettingsFile = titan.GetAISettingsName()
		setFile = expect string( Dev_GetAISettingByKeyField_Global( aiSettingsFile, "npc_titan_player_settings" ) )
	}

	return GetTitanCharacterNameFromSetFile( setFile )
}

void function OS_DoomBeep( entity player )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )
	//player.EndSignal( "DisembarkingTitan" )
	player.EndSignal( "OnSyncedMelee" )

	OS_Print( "Doom beep has started" )

	if( !IsValid( player ) )
		return

	while ( file.is_boarded )
	{
		if ( player.IsTitan() && GetDoomedState( player ) )
		{
			EmitSoundOnEntity( player, "boneyard_scr_bliskintro_foley_part1" )
			break
		}
		WaitFrame()
	}
	
	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Doom beep has ended" )
		}
	)
}

void function OS_DamageAlarm( entity player )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )
	//player.EndSignal( "DisembarkingTitan" )
	player.EndSignal( "OnSyncedMelee" )

	wait 1
	OS_Print( "Damage alarm has started" )

	if( !IsValid( player ) )
		return

	while( file.is_boarded )
	{
		int prevHealth = player.GetHealth()
		string conversationName = "bettyAlarm"
		string soundAlias = GenerateTitanOSAlias_custom( player, conversationName )
		int milliseconds = 0

		while ( IsValid( player ) )
		{
			if ( prevHealth == player.GetHealth() )
				WaitFrame()
			else
				break
		}

		if ( !file.is_boarded )
		{
			OS_Print( "Damage alarm has ended due to auto titan" )
			return
		}

		while ( milliseconds < 220 )
		{
			if ( !IsValid( player ) )
				return

			int currentHealth = player.GetHealth()
			
			alarmDamage = prevHealth - currentHealth
			//OS_Print( "alarmDamage is " + alarmDamage + "in millisecond: " + milliseconds )
			if ( ( prevHealth - currentHealth ) > 1999 )
			{
				if( player.IsTitan() )
	 			{
					OS_Print("alarm current health is " + currentHealth)
					alarmIsPlaying = true
					thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias, player, 1000)
					wait 0.6
					alarmIsPlaying = false

					break
	 			}
			}
			milliseconds = milliseconds + 1
			wait 0.001
		}
		WaitFrame()
		alarmDamage = 0
	}
	
	OnThreadEnd(
		function() : ()
		{
			OS_Print( "Damage alarm has ended" )
		}
	)
}

void function OS_RodeoChecker( entity player )
{
	player.EndSignal( "OnDeath" )
	player.EndSignal( "TitanEjectionStarted" )
	//player.EndSignal( "DisembarkingTitan" )
	player.EndSignal( "OnSyncedMelee" )

	wait 1
	OS_Print( "Rodeo checker has started" )

	string conversationName1 = "hostileLeftHull"
	string conversationName2 = "killEnemyRodeo"
	string conversationName3 = "batteryStolenByPilot"
	string conversationName4 = "batteryStolenGnrc"
	string conversationName5 = "killEnemyRodeoGnrc"
	string soundAlias_left = GenerateTitanOSAlias_custom( player, conversationName1 )
	string soundAlias_dead = GenerateTitanOSAlias_custom( player, conversationName2 )
	string soundAlias_deadgnrc = GenerateTitanOSAlias_custom( player, conversationName5 )
	string soundAlias_stolen = GenerateTitanOSAlias_custom( player, conversationName3 )
	string soundAlias_stolengnrc = GenerateTitanOSAlias_custom( player, conversationName4 )

	//thread PlayOneLinerConversationOnEntWithPriority_internal( soundAlias, player, 2 )

	if( !IsValid( player ) )
		return

	bool hostileOnBoard = false
	bool BoardedWithBattery = false
	entity prevrider

	while( file.is_boarded )
	{
		entity rider = player.GetRodeoRider( 0 )

		if ( rider == null )
		{
			//OS_Print("no current rodeo")

			if( hostileOnBoard )
			{
				//OS_Print("debug riderz 0")
				if( !IsValid( prevrider ) )
				  break

				if( !BoardedWithBattery )
				{
					//OS_Print("debug riderz 1")

					wait 0.2
					bool currentlyWithBattery = CheckPlayerNameBattery( prevrider.GetPlayerName())
					//OS_Print("the battery status of " + prevrider.GetPlayerName() + "is " + CheckPlayerNameBattery( prevrider.GetPlayerName()) )
	
					if( CheckPlayerNameBattery( prevrider.GetPlayerName() ) )
					{
						//OS_Print("debug riderz 2")
						int random = RandomInt( 2 )
						if ( random == 0 )
						{
							thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_stolengnrc, player, 2001 )
						}
						else
						{
							thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_stolen, player, 2001 )
						}
					}
					else
					{
						wait 0.3
						if ( IsAlive( prevrider ) )
						{
							//OS_Print("debug riderz 3")
							thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_left, player, 2001 )
						}
						else
						{
							//OS_Print("debug riderz 4")
							int random = RandomInt( 2 )
							if ( random == 0 )
							{
								thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_dead, player, 2001 )
							}
							else
							{
								thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_deadgnrc, player, 2001 )
							}
							
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
						//OS_Print("debug riderz 5")
						thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_left, player, 2001 )
					}
					else
					{
						//OS_Print("debug riderz 6")
						int random = RandomInt( 2 )
						if(random == 0)
						{
							thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_dead, player, 2001 )
						}
						else
						{
							thread PlayOneLinerConversationOnEntWithPriority_custom( soundAlias_deadgnrc, player, 2001 )
						}
					}
				}
			}

			hostileOnBoard = false
			prevrider = null
			BoardedWithBattery = false

		}
		else if ( rider != null )
		{
			if ( rider.GetTeam() != player.GetTeam() )
			{
				if( !hostileOnBoard )
				{
					//OS_Print( "debug riderz 7" )
					BoardedWithBattery = CheckPlayerNameBattery( rider.GetPlayerName())

					//OS_Print( "the current rider is " + rider + " with battery? " + CheckPlayerNameBattery( rider.GetPlayerName() ) )
					prevrider = rider
				}
				hostileOnBoard = true
			}
		}
		WaitFrame()
	}
	OS_Print( "Rodeo checker has ended" )
}

bool function CheckPlayerNameBattery(string name)
{
	array<entity> batteries = GetClientEntArrayBySignifier( "item_titan_battery" )
	entity player_found
	foreach ( player in GetPlayerArray() )
	{
		if ( name == player.GetPlayerName() )
		{
			if ( !IsValid( player ) )
				return false

			player_found = player
		}
	}

	if( !IsValid( player_found ) )
		return false

	foreach ( battery in batteries )
	{
		if ( battery.GetParent() != null )
		{
			if ( battery.GetParent().GetPlayerName() == player_found.GetPlayerName() )
				return true
		}
	}
	return false
}

void function PlayOneLinerConversationOnEntWithPriority_custom( string soundAlias, entity ent, int priority )
{
	//OS_Print( "PlayOneLinerConversationOnEntWithPriority, ConversationName: " + conversationName )

	if ( AbortConversationDueToPriority( priority ) )
	{
		//OS_Print( "Aborting conversation: " + conversationName + " due to higher priority conversation going on" )
		OS_Print(soundAlias + "aborted due to priority")
		return
	}

	CancelConversation( ent )

	thread PlayOneLinerConversationOnEntWithPriority_internal( soundAlias, ent, priority ) //Only thread this off once we've done the priority check since threading is expensive
}

void function OS_Print( string printString )
{
	if ( GetConVarBool( "OSR.Print" ) )
		printt( printString )
}

/*
void function battery_checker(entity player)
{
	while(player.IsTitan())
	{
		array<ArrayDistanceEntry> allResults = ArrayDistanceResults( file.batteries, player.GetOrigin() )
			allResults.sort( DistanceCompareClosest )
			if(allResults.len() == 0)
			{
				OS_Print("no batteries found")
			}
			else
			{
				for ( int i=0; i<allResults.len(); i++ )
				{
					OS_Print("nearest battery is in " + allResults [o])
				}
			}
			
	}
	

}
*/

