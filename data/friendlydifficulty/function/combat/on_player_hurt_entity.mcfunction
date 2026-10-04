advancement revoke @s only friendlydifficulty:provoke
execute unless score $enabled fd.global matches 1 run return 0
execute as @e[type=#friendlydifficulty:affected,distance=..12,nbt={HurtTime:10s},limit=1,sort=nearest] run function friendlydifficulty:combat/provoke
