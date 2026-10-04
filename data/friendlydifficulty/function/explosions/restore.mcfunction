# Restore vanilla explosion-related entity NBT (when Friendly is off or explosions Full)
execute as @e[type=minecraft:creeper] run data modify entity @s ExplosionRadius set value 3
execute as @e[type=minecraft:fireball] run data modify entity @s explosion_power set value 1.0d
execute as @e[type=minecraft:small_fireball] run data modify entity @s explosion_power set value 1.0d
execute as @e[type=minecraft:wither_skull] run data modify entity @s dangerous set value 1b
