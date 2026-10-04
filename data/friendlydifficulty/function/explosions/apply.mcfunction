# Off
execute if score $explosions fd.global matches 0 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 0
execute if score $explosions fd.global matches 0 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 0.0d
execute if score $explosions fd.global matches 0 as @e[type=minecraft:wither_skull] run data modify entity @s dangerous set value 0b

# Reduced
execute if score $explosions fd.global matches 1 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 1
execute if score $explosions fd.global matches 1 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 0.5d

# Full — restore common defaults
execute if score $explosions fd.global matches 2 as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 3
execute if score $explosions fd.global matches 2 as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 1.0d
