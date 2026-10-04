scoreboard players enable @a fd.settings
execute as @a[scores={fd.settings=1..}] run function friendlydifficulty:options/open
execute as @a[scores={fd.settings=1..}] run scoreboard players set @s fd.settings 0
