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

## 🚀 The Backstory & Hardware Optimization
This is my **very first video game project**, and I deliberately chose one of the most mechanically complex genres in software development: a 3D fighting engine. 

The entire initial framework was researched, designed, and coded in just **3 months**, running on an extremely limited low-end laptop:
* **CPU:** AMD A6-9225 Radeon R4 (2 Cores, 2.60 GHz)
* **RAM:** 4.00 GB (3.89 GB usable)
* **GPU:** AMD Radeon(TM) R4 Graphics (68 MB VRAM)
* **Storage:** 119 GB Samsung SSD

Developing under these severe hardware restrictions forced me to focus heavily on memory efficiency, strict code separation, and engine optimization from day one. 

### ⚡ What's Next?
I am currently **transitioning to a much more powerful PC setup**, which will allow me to scale up the project significantly. New updates, advanced combat mechanics, and graphical implementations will be published regularly as development continues!
---
*Note: This repository serves as a technical portfolio to demonstrate architectural design and clean code practices in game development.*
