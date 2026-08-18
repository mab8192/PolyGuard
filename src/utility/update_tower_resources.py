#!/usr/bin/env python3
import os
import re

TOWERS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "towers"))

MAPPINGS = {
    "archer_tower.tres": {
        "arcane_infusion": "res://src/textures/towers/variants/archer_tower_arcane.png",
        "true_piercer": "res://src/textures/towers/variants/archer_tower_piercer.png"
    },
    "arrow_wall.tres": {
        "arcane_infusion": "res://src/textures/towers/variants/arrow_wall_arcane.png",
        "true_piercer": "res://src/textures/towers/variants/arrow_wall_piercer.png"
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
    "ice_trap.tres": {
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

def update_file(filename, choices_map):
    filepath = os.path.join(TOWERS_DIR, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Find highest ext_resource id number or make new unique IDs
    existing_ext = re.findall(r'\[ext_resource[^\]]+id="([^"]+)"\]', content)
    ext_count = 100
    
    choice_ext_ids = {}
    ext_lines = []
    
    for choice_id, tex_path in choices_map.items():
        ext_id = f"ext_var_{choice_id}"
        choice_ext_ids[choice_id] = ext_id
        # Check if already in content
        if tex_path not in content:
            ext_lines.append(f'[ext_resource type="Texture2D" path="{tex_path}" id="{ext_id}"]')
        else:
            # find existing id
            m = re.search(r'\[ext_resource[^\]]+path="' + re.escape(tex_path) + r'"[^\]]+id="([^"]+)"\]', content)
            if m:
                choice_ext_ids[choice_id] = m.group(1)

    # Insert ext_resource lines after existing ext_resources
    if ext_lines:
        last_ext_idx = content.rfind("[ext_resource")
        if last_ext_idx != -1:
            end_of_last_ext = content.find("]", last_ext_idx) + 1
            content = content[:end_of_last_ext] + "\n" + "\n".join(ext_lines) + content[end_of_last_ext:]
        else:
            # right after gd_resource line
            first_nl = content.find("\n\n")
            if first_nl != -1:
                content = content[:first_nl] + "\n\n" + "\n".join(ext_lines) + content[first_nl:]

    # Now add `icon = ExtResource("...")` to each choice sub_resource
    # We find blocks starting with [sub_resource type="Resource" and containing id = "choice_id"
    for choice_id, ext_id in choice_ext_ids.items():
        pattern = re.compile(r'(\[sub_resource\s+type="Resource"[^\]]*\]\s*script\s*=\s*ExtResource\([^\)]+\)\s*id\s*=\s*"' + re.escape(choice_id) + r'"[^\[]*?)(?=\n\[|\Z)', re.DOTALL)
        m = pattern.search(content)
        if m:
            block = m.group(1)
            if "icon = ExtResource" not in block:
                # Add icon right after id line or at end of block
                new_block = block.rstrip() + f'\nicon = ExtResource("{ext_id}")\n'
                content = content[:m.start()] + new_block + content[m.end():]

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Updated {filename}")

def main():
    for fname, cmap in MAPPINGS.items():
        update_file(fname, cmap)

if __name__ == "__main__":
    main()
