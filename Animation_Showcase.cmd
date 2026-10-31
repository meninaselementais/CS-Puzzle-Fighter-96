@echo off
cd /d "%~dp0"
start "" "ferramentas\godot_4.7.2\Godot_v4.7.2-stable_win64.exe" --path "%~dp0godot" res://animation_showcase.tscn
