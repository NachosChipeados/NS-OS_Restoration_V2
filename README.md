An overhaul of the original [Os Restoration](https://thunderstore.io/c/northstar/p/Northstar_Archive/OS_Restoration/) mod by Fragyeeter with various bug fixes, crash fixes and some new features.

# Original features

- Restored Disembark voicelines.
- Restored Battery received voicelines when a friendly Pilot gives you a battery.
- Restored Battery Nearby voicelines.
- Restored Hostile rodeo voicelines, with respect to when a battery is stolen or when the rider is killed or detached from hull.
- Restored the warning alarm from TF1.

# 2.0.0 - New features and fixes

- Fixed BT playing disembark voicelines when the timeline is frozen in Effect and Cause.
- Fixed crashes with Spectre rodeo.
- Fixed crashes in the campaign related to "BatteryNearby" voicelines (BT doesn't have them).
- Fixed console spam in the campaign related to batteries.
- Fixed voicelines having no delay for when they can play again, playing multiple times in a single frame and spamming the subtitles.

- "BatteryNearby" voicelines now play when outside your Titan.
- "CoreOffline" voicelines now play if trying to use a core ability when it's not charged.
- Added consistent spark effects while doomed. This was technically added in an update to the original mod, but afaik it was never posted outside of the Northstar discord.
- Generic "BatteryStolen", "KillEnemyRodeo" and "RodeoWarning" voicelines now play when a Non-Pilot entity is rodeoing you. They also have a chance of playing anyways even if it's a Pilot.
- Completely restructured the way new voicelines are registered and triggered internally.
- More voicelines can now trigger the Damage alarm. The same voicelines that triggered it in TF1 + some other ones added in TF2, can now do it.
	- It can also be forced to play on EVERY voiceline, if you really want to for some reason.
- Restored "BatteryGotShieldActivated" and "BatteryGotShieldEnabled" voicelines, which have a chance of playing when receiving batteries. Only multiplayer titans have them.
	- Also restored "BatteryUsed" voicelines, which only BT has.
- Restored "DoomEjectRec" voicelines, which have a 1/3 chance of playing when you get doomed. Only multiplayer titans have them.
- Restored "EnemyTitanfall" voicelines, which play when you're right below an enemy Titanfall spot.
- Restored the Doomed alarm from TF1. Same story as the doomed sparks.
	- Since the game has infinite doomed state, the alarm will fade out after a few seconds so it isn't too annoying.
- Restored the unused Rodeo alarm from TF1.

Some of these features can be turned on/off in mod settings.

