data remove entity @s Brain.memories."minecraft:attack_target"
data remove entity @s AngryAt
data modify entity @s AngerTime set value 0
execute if entity @s[type=minecraft:creeper] run data modify entity @s ignited set value 0b
execute if entity @s[type=minecraft:creeper] run data modify entity @s Fuse set value 30
