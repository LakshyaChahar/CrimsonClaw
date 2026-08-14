# CrimsonClaw Combat Implementation Guide: Hitboxes & Hurtboxes

Welcome! This guide explains how to properly configure enemies so they can deal and receive damage in the CrimsonClaw project. 

The project uses a decoupled combat system consisting of two main components:
- **Hitbox (`Scripts/Core/hitbox.gd`)**: An `Area2D` that **DEALS** damage. It actively scans for Hurtboxes.
- **Hurtbox (`Scripts/Core/hurtbox.gd`)**: An `Area2D` that **RECEIVES** damage. It is entirely passive.

---

## 1. Collision Layer Standard

To ensure that enemies, players, and traps interact without bugs, we have standardized physics layers defined in `project.godot`. 

When setting up enemies, you will primarily use:
- **Layer 2: Player** (Target for your enemy hitboxes)
- **Layer 4: Enemies** (Layer for your enemy hurtboxes)
- **Layer 5: Hazards** (Layer for your enemy hitboxes and traps)

---

## 2. Setting up the Enemy's HURTBOX (Receiving Damage)

The `Hurtbox` allows the enemy to take damage from the player's attacks.

### Node Setup
1. Add an `Area2D` node named `Hurtbox` as a child of your Enemy root node.
2. Attach the **`Scripts/Core/hurtbox.gd`** script to it.
3. Add a `CollisionShape2D` as a child of the `Hurtbox` and define its shape (usually covering the enemy's sprite).

### Collision Properties
- **Collision Layer**: `Layer 4 (Enemies)` 
- **Collision Mask**: `None` (Leave completely empty! Hurtboxes are passive and do not scan).

### Required Enemy Methods
For the `hurtbox.gd` script to pass damage to your enemy, the root enemy node (e.g., your `CharacterBody2D` script) **MUST** implement the following methods:

```gdscript
func take_damage(amount: float) -> void:
    # Apply damage, trigger hit flash, check for death, etc.
    health -= amount

func stun(duration: float) -> void:
    # Optional but recommended.
    # Transition your state machine to the Stun state.
    pass
```

*Note: The `hurtbox.gd` automatically provides Invincibility Frames (i-frames) by disabling its collision shape temporarily after being hit. You can tweak the `invincibility_duration` in the inspector.*

---

## 3. Setting up the Enemy's HITBOX (Dealing Damage)

The `Hitbox` allows the enemy to deal damage to the player.

### Node Setup
1. Add an `Area2D` node named `Hitbox` as a child of your Enemy root node.
2. Attach the **`Scripts/Core/hitbox.gd`** script to it.
3. Add a `CollisionShape2D` as a child of the `Hitbox` and define its shape (e.g., over the enemy's weapon or attack area).
4. **Important:** By default, check `Disabled` on this `CollisionShape2D`. You should only enable it during an attack animation (using an `AnimationPlayer` or your State Machine).

### Collision Properties
- **Collision Layer**: `Layer 5 (Hazards)`
- **Collision Mask**: `Layer 2 (Player)` (This allows it to detect the Player's Hurtbox).

### Inspector Variables (`hitbox.gd`)
- `Damage`: The amount of damage dealt.
- `Knockback Force`: The power of the knockback applied to the player.
- `Knockback Direction`: Leave at `(0,0)` for it to automatically calculate knockback direction away from the attacker.
- `Stun Duration`: How long the target is stunned.

---

## 4. Key Takeaways & Rules
1. **Script Behavior**: 
   - `hitbox.gd` automatically sets `monitoring = true` and `monitorable = false` on `_ready()`.
   - `hurtbox.gd` automatically sets `monitoring = false` and `monitorable = true` on `_ready()`.
2. **Dashing Immunity**: The `hurtbox.gd` checks if the root entity has a property `is_dashing = true`. If so, hits are ignored. Keep this in mind if you create enemies that can dash/dodge.
3. **Signals**: If you need to trigger particle effects or sounds, use the signals emitted by these nodes:
   - Hitbox emits: `hit_registered(hurtbox)`
   - Hurtbox emits: `hit_received(damage, knockback, stun_duration, attacker)`
