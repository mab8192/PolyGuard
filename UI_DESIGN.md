# Poly Guard 2D - UI & UX Design Spec

This document details the interface layout, screen flows, and interactive UX mechanics for **Poly Guard 2D**, designed for portrait mobile displays (1080×1920 aspect ratio).

---

## 1. Key Design Principles

1. **No In-Game Upgrades**: All tower and trap upgrades are managed out-of-game (between levels in the **Armory**). In-game decisions focus purely on placement, economy, and timing.
2. **Pre-Level Loadout Selection**: Before entering a level, players pick a loadout of $N$ equipped towers/traps (e.g. 4 to 6 slots depending on stage level).
3. **Centered Pie / Radial Build Menu**: The primary **BUILD** button sits in the bottom-center of the screen. Pressing or holding it opens a radial pie menu centered right above it.
4. **Top Controls & Dynamic Wave Button**:
   - Speed toggle (Fast Forward `⏩`) sits in the top header bar next to Pause (`⏸`).
   - The `NEXT WAVE ▶` button only appears at the bottom-right during intermissions between waves.
5. **Two-Phase Placement**: 
   - **Phase 1 (Select)**: Hold/drag or tap on the Pie Menu to choose a tower.
   - **Phase 2 (Position & Confirm)**: A ghost tower spawns in the play area. Drag to reposition, then tap the checkmark/confirm button or tap the tile to finalize placement.

---

## 2. Screen Architecture & Node Structure

```text
[ Main Menu ] ---> [ Stage Select & Loadout Prep ] ---> [ In-Game Battle HUD ]
     |                      ^
     v                      |
[ Tower Armory ] -----------+ (Global Upgrades between levels)
```

### Godot Node Tree Strategy (`HUD.tscn`)

```text
CanvasLayer (HUD Layer)
├── TopBar (MarginContainer)
│   └── HBoxContainer [Lives | Gold | Wave | Fast Forward ⏩ | Pause ⏸]
├── MainPlayfieldArea (Control - Mouse Filter: PASS)
│   └── GhostPreviewOverlay (Node2D / Control)
│       └── ConfirmPlacementButtons (HBoxContainer [✓ Confirm | ✕ Cancel])
├── BottomBar (MarginContainer)
│   └── Control / HBoxContainer
│       ├── CenteredBuildButton (TextureButton / Button)
│       └── NextWaveButton (Button - Visible only between waves)
└── PieMenuOverlay (Control - Visible on Build Button press/hold)
    └── RadialContainer / CenterContainer
        └── TowerPieButtons (Radial arrangement centered above Build Button)
```

---

## 3. Visual Layout Previews (Rendered HTML)

### Screen A: Main Menu & Level Loadout Screen

<div style="width: 360px; height: 640px; border: 4px solid #333; border-radius: 24px; background: #1a1a2e; color: #fff; font-family: system-ui, sans-serif; display: flex; flex-direction: column; justify-content: space-between; padding: 20px; box-sizing: border-box; margin: 20px 0; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
  <div style="text-align: center; margin-top: 10px;">
    <h1 style="margin: 0; color: #e94560; font-size: 26px; letter-spacing: 2px;">POLY GUARD 2D</h1>
    <p style="margin: 5px 0; color: #8d99ae; font-size: 12px;">Mobile Tower Defense</p>
  </div>
  <div style="background: #16213e; padding: 15px; border-radius: 14px; border: 1px solid #0f3460;">
    <h3 style="margin: 0 0 8px 0; font-size: 15px; color: #4ecca3;">Stage 3: Polygon Pass</h3>
    <p style="font-size: 12px; color: #aaa; margin: 0 0 12px 0;">Select Loadout (Max 4 Towers):</p>
    <div style="display: flex; gap: 8px; justify-content: center;">
      <div style="width: 50px; height: 50px; background: #0f3460; border: 2px solid #4ecca3; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; text-align: center;">Arrow</div>
      <div style="width: 50px; height: 50px; background: #0f3460; border: 2px solid #4ecca3; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; text-align: center;">Cannon</div>
      <div style="width: 50px; height: 50px; background: #0f3460; border: 2px solid #4ecca3; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; text-align: center;">Slow</div>
      <div style="width: 50px; height: 50px; background: #0f3460; border: 2px dashed #e94560; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; color: #888;">+ Equip</div>
    </div>
  </div>
  <div style="display: flex; flex-direction: column; gap: 10px; align-items: center; margin-bottom: 10px;">
    <button style="width: 85%; padding: 14px; background: #e94560; border: none; border-radius: 12px; color: white; font-weight: bold; font-size: 15px; cursor: pointer;">START LEVEL</button>
    <button style="width: 85%; padding: 11px; background: #0f3460; border: 1px solid #4ecca3; border-radius: 12px; color: white; font-size: 13px; cursor: pointer;">TOWER ARMORY (UPGRADES)</button>
    <button style="width: 85%; padding: 10px; background: transparent; border: 1px solid #444; border-radius: 12px; color: #8d99ae; font-size: 12px; cursor: pointer;">SETTINGS</button>
  </div>
</div>

---

### Screen B: In-Game HUD & Centered Radial Pie Menu

<div style="width: 360px; height: 640px; border: 4px solid #333; border-radius: 24px; background: #181818; color: #fff; font-family: system-ui, sans-serif; position: relative; overflow: hidden; margin: 20px 0; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
  <div style="position: absolute; top: 15px; left: 10px; right: 10px; height: 45px; background: rgba(0,0,0,0.75); border-radius: 12px; display: flex; align-items: center; justify-content: space-between; padding: 0 12px; font-size: 13px; box-sizing: border-box;">
    <div>❤️ <b>20</b></div>
    <div>🪙 <b>150</b></div>
    <div>🌊 <b>Wave 3/10</b></div>
    <div style="display: flex; gap: 6px; align-items: center;">
      <div style="background: #0f3460; border: 1px solid #4ecca3; padding: 4px 8px; border-radius: 6px; cursor: pointer; font-size: 12px;">⏩ 1x</div>
      <div style="background: #333; padding: 4px 8px; border-radius: 6px; cursor: pointer; font-size: 12px;">⏸</div>
    </div>
  </div>
  <div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: #333; font-size: 14px; text-transform: uppercase; font-weight: bold; letter-spacing: 1px;">
    [ Game Playfield Grid ]
  </div>
  <div style="position: absolute; top: 220px; left: 135px; text-align: center; pointer-events: none;">
    <div style="width: 80px; height: 80px; border: 2px dashed #4ecca3; border-radius: 50%; background: rgba(78, 204, 163, 0.15); display: flex; align-items: center; justify-content: center;">
      <span style="font-size: 26px;">🏹</span>
    </div>
    <div style="display: flex; gap: 12px; margin-top: 8px; justify-content: center; pointer-events: auto;">
      <button style="background: #e94560; border: none; color: white; width: 32px; height: 32px; border-radius: 50%; font-weight: bold; cursor: pointer;">✕</button>
      <button style="background: #4ecca3; border: none; color: white; width: 32px; height: 32px; border-radius: 50%; font-weight: bold; cursor: pointer;">✓</button>
    </div>
  </div>
  <div style="position: absolute; bottom: 15px; left: 10px; right: 10px; height: 60px; display: flex; justify-content: center; align-items: center; box-sizing: border-box;">
    <button style="width: 80px; height: 60px; background: #e94560; border: none; border-radius: 16px; color: white; font-weight: bold; font-size: 11px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; cursor: pointer; box-shadow: 0 4px 12px rgba(233, 69, 96, 0.5); z-index: 10;">
      <span style="font-size: 20px;">🔨</span> BUILD
    </button>
    <div style="position: absolute; right: 0; bottom: 5px;">
      <button style="height: 48px; padding: 0 12px; background: #4ecca3; border: none; border-radius: 12px; color: #111; font-weight: bold; font-size: 11px; cursor: pointer; box-shadow: 0 2px 8px rgba(78, 204, 163, 0.4);">NEXT WAVE ▶<br><span style="font-size: 8px; font-weight: normal;">(Between Waves Only)</span></button>
    </div>
  </div>
  <div style="position: absolute; bottom: 80px; left: 90px; width: 180px; height: 180px; background: rgba(15, 52, 96, 0.92); border: 2px solid #4ecca3; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 20px rgba(78, 204, 163, 0.3);">
    <div style="position: absolute; top: 12px; left: 70px; text-align: center;">
      <div style="width: 40px; height: 40px; background: #e94560; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; box-shadow: 0 2px 5px rgba(0,0,0,0.4);">🏹</div>
      <span style="font-size: 9px; background: #000; padding: 1px 5px; border-radius: 4px; display: inline-block; margin-top: 2px;">50g</span>
    </div>
    <div style="position: absolute; right: 12px; top: 70px; text-align: center;">
      <div style="width: 40px; height: 40px; background: #e94560; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; box-shadow: 0 2px 5px rgba(0,0,0,0.4);">💣</div>
      <span style="font-size: 9px; background: #000; padding: 1px 5px; border-radius: 4px; display: inline-block; margin-top: 2px;">100g</span>
    </div>
    <div style="position: absolute; bottom: 12px; left: 70px; text-align: center;">
      <div style="width: 40px; height: 40px; background: #e94560; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; box-shadow: 0 2px 5px rgba(0,0,0,0.4);">❄️</div>
      <span style="font-size: 9px; background: #000; padding: 1px 5px; border-radius: 4px; display: inline-block; margin-top: 2px;">75g</span>
    </div>
    <div style="position: absolute; left: 12px; top: 70px; text-align: center;">
      <div style="width: 40px; height: 40px; background: #e94560; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; box-shadow: 0 2px 5px rgba(0,0,0,0.4);">⚡</div>
      <span style="font-size: 9px; background: #000; padding: 1px 5px; border-radius: 4px; display: inline-block; margin-top: 2px;">125g</span>
    </div>
    <div style="width: 32px; height: 32px; background: #16213e; border: 2px solid #4ecca3; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 9px; color: #4ecca3; font-weight: bold;">
      DRAG
    </div>
  </div>
</div>

---

## 4. Summary of In-Game Interaction Steps

1. **Top Bar Controls**:
   - Player can toggle speed (`⏩ 1x / 2x`) or Pause (`⏸`) at any time in the top-right header.
2. **Intermission Phase**:
   - Between waves, the `NEXT WAVE ▶` button appears on the bottom-right. Once tapped, the wave starts and the button hides.
3. **Build Execution**:
   - Player holds or taps the central **BUILD** button at the bottom.
   - The radial pie menu opens centered right above the build button.
   - Player drags-and-releases over a pie slice to choose a tower.
4. **Ghost Positioning & Tile Placement**:
   - A ghost tower appears on the map grid.
   - Player drags to move the ghost tower and taps `✓` to finalize placement.
