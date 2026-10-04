$scoreboard players set $enabled fd.global $(enabled)
$scoreboard players set $explosions fd.global $(explosions)
$scoreboard players set $world_damage fd.global $(world_damage)
execute unless score $enabled fd.global matches 1 run function friendlydifficulty:explosions/restore
execute if score $enabled fd.global matches 1 if score $explosions fd.global matches 2 run function friendlydifficulty:explosions/restore
execute if score $enabled fd.global matches 1 run difficulty easy
tellraw @s {"text":"Friendly Difficulty settings applied.","color":"green"}
