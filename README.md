# Deterministic 3D Fighting Engine (Godot 4)

![Status](https://img.shields.io/badge/Status-In%20Development-orange)
![Engine](https://img.shields.io/badge/Engine-Godot%204.x-blue)

A modular, data-driven 3D fighting game engine framework built in Godot 4. This architecture is heavily inspired by classic scalable platforms like MUGEN, updated with modern software engineering patterns for precise 3D gameplay and deterministic frame management.

## 🛠️ Core Features (Implemented & WIP)
* **Modular State Machine:** Fully decoupled state management using an expandable node-based hierarchy (`FighterState` & `StateMachine`).
* **Data-Driven Move Management:** Fight statistics, attributes, and move data completely separated via custom Godot Resources (`CharacterData`).
* **Deterministic Frame Logic:** Physics loop separation inside `_physics_process` designed to safely freeze gameplay for frame-perfect Hitstop impacts.
* **Localized Health System:** Dynamic condition penalties based on skeletal hit zones (head, body, arms, legs) altering core character velocities (e.g., limping/running restriction thresholds).
* **Tekken-Style Neutral Guard:** Built-in context-aware automatic blocking for high/mid attacks during idle and backward movement.

## 📁 Repository Structure
Currently showcasing the core architectural layout (`/script/core/`):
* `fighter_base.gd`: Pure interface defining core properties, localized health pools, and global virtual hooks.
* `fighter_controller.gd`: Implementation layer handling localized damage calculation, dynamic pushback vectors, and spatial rotation tracking.
* `state_machine.gd` / `fighter_state.gd`: Modular framework for isolated state encapsulation.

---
*Note: This repository serves as a technical portfolio to demonstrate architectural design and clean code practices in game development.*
