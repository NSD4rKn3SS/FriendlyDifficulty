scoreboard objectives add fd.global dummy
scoreboard objectives add fd.provoke dummy

# Defaults only if never set
execute unless score $enabled fd.global = $enabled fd.global run scoreboard players set $enabled fd.global 0
execute unless score $explosions fd.global = $explosions fd.global run scoreboard players set $explosions fd.global 1
execute unless score $world_damage fd.global = $world_damage fd.global run scoreboard players set $world_damage fd.global 2
scoreboard players set $const_provoke fd.global 600

tellraw @a [{"text":"[Friendly Difficulty] ","color":"green"},{"text":"loaded · ","color":"gray"},{"text":"[Settings]","color":"aqua","clickEvent":{"action":"run_command","value":"/function friendlydifficulty:options/open"}}]
