#!/usr/bin/env python3
import os
import re

TOWERS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "towers"))

MAPPINGS = {
    "acid_wall.tres": {
        "vitriol_melter": "res://src/textures/towers/variants/acid_wall_vitriol.png",
        "caustic_sludge": "res://src/textures/towers/variants/acid_wall_sludge.png"
    },
    "archer_tower.tres": {
        "arcane_infusion": "res://src/textures/towers/variants/archer_tower_arcane.png",
        "true_piercer": "res://src/textures/towers/variants/archer_tower_piercer.png"
    },
    "arrow_wall.tres": {
        "arcane_infusion": "res://src/textures/towers/variants/arrow_wall_arcane.png",
        "true_piercer": "res://src/textures/towers/variants/arrow_wall_piercer.png"
    },
    "wind_wall.tres": {
        "hurricane_force": "res://src/textures/towers/variants/wind_wall_tempest.png",
        "gale_vortex": "res://src/textures/towers/variants/wind_wall_vortex.png"
    },
    "artillery.tres": {
        "thermite_carpet": "res://src/textures/towers/variants/artillery_thermite.png",
        "heavy_salvo": "res://src/textures/towers/variants/artillery_salvo.png"
    },
    "barricade.tres": {
        "reinforced_spikes": "res://src/textures/towers/variants/barricade_spikes.png",
        "spectral_barrier": "res://src/textures/towers/variants/barricade_spectral.png"
    },
    "bomb_tower.tres": {
        "incendiary_shells": "res://src/textures/towers/variants/bomb_tower_incendiary.png",
        "heavy_concussion": "res://src/textures/towers/variants/bomb_tower_concussion.png"
    },
    "brimstone.tres": {
        "hellfire_core": "res://src/textures/towers/variants/brimstone_hellfire.png",
        "nether_void": "res://src/textures/towers/variants/brimstone_void.png"
    },
    "corrosive_vapor.tres": {
        "concentrated_acid": "res://src/textures/towers/variants/corrosive_vapor_acid.png",
        "volatile_dispersion": "res://src/textures/towers/variants/corrosive_vapor_volatile.png"
    },
    "crossbow.tres": {
        "spectral_bolt": "res://src/textures/towers/variants/crossbow_spectral.png",
        "quick_windlass": "res://src/textures/towers/variants/crossbow_windlass.png"
    },
    "displacer.tres": {
        "warp_amplifier": "res://src/textures/towers/variants/displacer_warp.png",
        "mass_displacement": "res://src/textures/towers/variants/displacer_mass.png"
    },
    "flamethrower.tres": {
        "napalm_catalyst": "res://src/textures/towers/variants/flamethrower_napalm.png",
        "turbo_compressor": "res://src/textures/towers/variants/flamethrower_turbo.png"
    },
    "freeze_trap.tres": {
        "permafrost_seal": "res://src/textures/towers/variants/ice_trap_permafrost.png",
        "sub_zero_glaze": "res://src/textures/towers/variants/ice_trap_glaze.png"
    },
    "poison_trap.tres": {
        "rapid_dispersion": "res://src/textures/towers/variants/poison_trap_rapid.png",
        "broad_plume": "res://src/textures/towers/variants/poison_trap_plume.png"
    },
    "soul_lantern.tres": {
        "soul_split": "res://src/textures/towers/variants/soul_lantern_split.png",
        "ethereal_focus": "res://src/textures/towers/variants/soul_lantern_focus.png"
    },
    "sparkler.tres": {
        "prismatic_array": "res://src/textures/towers/variants/sparkler_prismatic.png",
        "arcane_overcharge": "res://src/textures/towers/variants/sparkler_overcharge.png"
    },
    "spike_trap.tres": {
        "serrated_spikes": "res://src/textures/towers/variants/spike_trap_serrated.png",
        "hydraulic_spring": "res://src/textures/towers/variants/spike_trap_hydraulic.png"
    },
    "tar_trap.tres": {
        "hex_pitch": "res://src/textures/towers/variants/tar_trap_hex.png",
        "acid_tar": "res://src/textures/towers/variants/tar_trap_acid.png"
    },
    "tesla_tower.tres": {
        "superconductor": "res://src/textures/towers/variants/tesla_tower_superconductor.png",
        "overcharge_volt": "res://src/textures/towers/variants/tesla_tower_overcharge.png"
    }
}

def verify_and_fix():
    for filename, cmap in MAPPINGS.items():
        filepath = os.path.join(TOWERS_DIR, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        # Parse ext_resources
        ext_map = {} # path -> id
        for l in lines:
            m = re.match(r'\[ext_resource\s+type="Texture2D"\s+path="([^"]+)"\s+id="([^"]+)"\]', l.strip())
            if m:
                ext_map[m.group(1)] = m.group(2)
        
        # Ensure all variant textures are in ext_map
        new_ext_lines = []
        for choice_id, tex_path in cmap.items():
            if tex_path not in ext_map:
                ext_id = f"ext_var_{choice_id}"
                ext_map[tex_path] = ext_id
                new_ext_lines.append(f'[ext_resource type="Texture2D" path="{tex_path}" id="{ext_id}"]\n')

        if new_ext_lines:
            # insert after last ext_resource
            last_ext = 0
            for idx, l in enumerate(lines):
                if l.startswith("[ext_resource"):
                    last_ext = idx
            for n_l in reversed(new_ext_lines):
                lines.insert(last_ext + 1, n_l)

        # Now check each sub_resource block
        content = "".join(lines)
        blocks = re.split(r'(\n\[sub_resource|\n\[resource\])', content)
        
        # Rebuild content
        for i in range(len(blocks)):
            block = blocks[i]
            for choice_id, tex_path in cmap.items():
                if f'id = "{choice_id}"' in block and "icon = ExtResource" not in block:
                    ext_id = ext_map[tex_path]
                    # Append icon line to block
                    block = block.rstrip() + f'\nicon = ExtResource("{ext_id}")\n'
                    blocks[i] = block
        
        fixed_content = "".join(blocks)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(fixed_content)
        print(f"Verified & Fixed {filename}")

if __name__ == "__main__":
    verify_and_fix()
