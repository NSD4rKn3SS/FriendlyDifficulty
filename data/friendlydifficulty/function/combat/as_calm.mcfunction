tag @s add fd.self
execute on target if entity @s[type=player] as @e[tag=fd.self,limit=1] run function friendlydifficulty:combat/clear_player_target
tag @s remove fd.self

# Calm creepers: defuse if ignited near players
execute if entity @s[type=minecraft:creeper] if data entity @s {ignited:1b} on target if entity @s[type=player] as @e[type=minecraft:creeper,tag=!fd.provoked,limit=1,sort=nearest] run data modify entity @s ignited set value 0b
