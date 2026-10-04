tag @s add fd.self
execute on target if entity @s[type=player] run scoreboard players operation @e[tag=fd.self,limit=1] fd.provoke = $const_provoke fd.global
tag @s remove fd.self
execute if data entity @s {HurtTime:10s} run scoreboard players operation @s fd.provoke = $const_provoke fd.global
scoreboard players remove @s fd.provoke 1
execute if score @s fd.provoke matches ..0 run tag @s remove fd.provoked
execute if score @s fd.provoke matches ..0 run scoreboard players reset @s fd.provoke
