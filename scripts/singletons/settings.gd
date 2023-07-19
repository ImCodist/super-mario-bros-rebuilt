extends Node


# === VISUALS ===
## If Mario should be rendered in front or behind the HUD layer.
## In SMB he is rendered in front of everything.
var mario_behind_hud := false


# === HARD CODED BUGS ===
## In SMB multiple powerups cannot exist at the same time.
## So the old one is removed by default.
## I think this happens because of technical limitations but it's not a problem here.
## like.... obviously (https://twitter.com/ImCodist/status/1681095400676110336?s=20)
var only_allow_one_powerup := true

## When collecting a powerup you are able to jump a frame afterwards.
## This behaviour is not intended but important when recreating SMB.
var powerup_jump_bug := true

## Technically not a bug but a limitation of the NES.
## Makes one of the audio channels mute when a SFX is being played to make "room".
## Obviously this isn't needed because Godot, so it is a hardcoded thing.
var mute_music_channel_on_sfx := false
