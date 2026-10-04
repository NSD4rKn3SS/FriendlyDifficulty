advancement revoke @s only friendlydifficulty:world_hazard_hit
execute unless score $enabled fd.global matches 1 run return 0
execute if score $world_damage fd.global matches 2 run return 0

# Off: negate — resistance + heal recent damage aggressively
execute if score $world_damage fd.global matches 0 run effect give @s minecraft:resistance 1 4 true
execute if score $world_damage fd.global matches 0 run effect give @s minecraft:instant_health 1 0 true

# Reduced: light resistance
execute if score $world_damage fd.global matches 1 run effect give @s minecraft:resistance 1 1 true
