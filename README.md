# DARKSOLES

Open project.godot in Godot 4.7 and run the main scene with F5. The game uses a portrait viewport and the Compatibility renderer.

## Editing the game in Godot

Start with **game/scenes/main.tscn**. The scene tree contains the Dungeon generator, Player camera and hands, Fireball, HUD and both screen effects. Double-click an instanced scene's scene icon to edit its source. Changes apply to every new instance.

| To change | Open in the FileSystem dock | Edit in the Inspector or scene tree |
| --- | --- | --- |
| Shared enemy behavior | game/enemies/enemy_base.tscn | Select the root for health, attack damage, heavy attack chance, windups, recovery and stun damage. Move or scale Illustration and AttackGlow to change framing. |
| A particular enemy | game/enemies/skeleton.tscn or wraith.tscn | Both inherit Enemy. Override a property on the variant, or use its Inspector revert arrow to inherit the base value again. Each spawned enemy has its own health and flash material. |
| Player and equipment | game/player/player.tscn | The camera root exposes movement speed, starting health, action slots, cooldowns and attack/defense settings. Edit its height or FOV directly. The Hands node holds the arm rig, grip points and equipment scenes. |
| Dungeon layout | game/scenes/main.tscn → Dungeon | Set the spawn scenes, enemy chances, junction spacing and generation distance. The generator streams instances of game/world/corridor.tscn. |
| Architecture and lighting | game/world/corridor.tscn | Edit the deck, left/right openings, connecting passages and arch. Reusable wall, floor, candle and sconce scenes live under world/modules. A sconce's LightSource marker positions its gradient light. The shared wall finish is world/materials/masonry.tres. |
| Treasure and healing | game/encounters/treasure_chest.tscn or shrine.tscn | Adjust the chest art and reward pool, or edit the shrine's candle arrangement, healing and message. Its relic pool uses the existing action names. |
| Menus and touch controls | game/ui/hud.tscn | Title, Play, Treasure, Relic and Death are Control branches. Toggle their visibility in the editor to preview a screen, then select individual Labels, Buttons or artwork to edit them. Runtime state controls which branch is shown. |
| Screen palette and dither | game/scenes/main.tscn → Interface | Dither processes the world before the HUD, and Palette processes the composed frame. Shader sources are in game/rendering/shaders. |

Procedural route selection, input timing, skeletal posing, and the animated combat rings are scripted. To add an enemy variant, create an inherited scene from enemy_base.tscn, set its illustration and stats, then assign it to an enemy slot on Dungeon.

## Animating the first-person arms

Open **game/player/player.tscn**. The shared skeleton starts in the in-game grip pose, with the equipment attached to its palm bones.

1. Select **Hands → ClipLibrary**, create a named clip in the Animation panel, and key bone position, rotation, or scale on **Hands → Rig → Armature → Skeleton3D**. Scrub the clip to preview the equipment following the hands. Imported takes from **Rig → AnimationPlayer** also appear in the assignment lists. Local clips take precedence when names match.
2. Select **Hands → RightHand → Actions** and choose your swing clip for **Sword**. Select **Hands → LeftHand → Actions** and choose your guard clip for **Shield**. Locomotion and reaction slots work the same way.
3. Each channel plays its own bone hierarchy, so a right-hand swing and left-hand guard can overlap. For a two-handed action, assign the same clip to that action on both channels. Playback uses skeletal transform tracks. The equipment follows the grip sockets.
4. Idle and Walk repeat. Actions play once and return to locomotion. Slots start **Unassigned**, with the existing procedural poses available while you animate. The Player node controls gameplay timing independently of clip length.

Edit an item's local transform beneath **LeftGrip** or **RightGrip** to change how it sits in the fingers. Both are BoneAttachment3D nodes under Skeleton3D. The masks follow shoulder ancestry because several bones in the supplied FBX have crossed name suffixes.

## Dungeon transitions and route cues

Select Dungeon in the main scene to tune slime frequency, transition spacing, and the drop per stair flight. Slime inherits the enemy base and uses the Green Slime illustration. Doors open on approach. A door can reveal a three-section descending staircase; occasional stairways also occur in open corridors. Dungeon exposes the flight length, minimum spacing, and both chances. Stair flights always descend, with a clear landing before another roaming fight can stop the player. Adjust Stair Look Down on the player camera to change its pitch during descent.

A few glints at a fork hint at treasure. A soft flickering pool hints at a healing candle. Longer shadows stretch toward the player on a hostile route. Each cue uses the same reward assignment as the passage it marks.

## Playing and checking the game

Tap an action or press 1–3 (A/S/D). Tap the left, middle or right third of the corridor at a junction, or use the arrow keys. Open a chest to see the offered relic. The best descent is saved locally.

Run the mechanics regression from the project directory:

    godot --headless --path . --script res://tests/check_run.gd

Run the hand animation regression with:

    godot --headless --path . --script res://tests/check_arm_animations.gd
