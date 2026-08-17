#!/usr/bin/env python3
"""
generate_balanced_waves.py
Rebalances all stage wave JSON configurations for Poly Guard 2D.
"""

import json
import os

WAVES_DIR = "/home/michael/projects/godot/poly-guard-2d/src/data/stages/waves"

def write_wave_file(filename: str, data: list):
    path = os.path.join(WAVES_DIR, filename)
    with open(path, "w") as fp:
        json.dump(data, fp, indent=2)
    print(f"Wrote {filename} ({len(data)} waves)")

# Stage 0 (Tutorial / Intro): 1 Spawner
stage0 = [
    {
        "wave_number": 1,
        "reward_energy": 50,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 6, "interval": 1.0, "delay": 0.5}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 100,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 2, "interval": 1.5, "delay": 0.5}, # Intro grunt (1-2)
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 10, "interval": 0.8, "delay": 3.0}
        ]
    }
]

# Stage 1: 1 Spawner
# Introduces: speeder (intro 2), heavy (intro 2), tank (intro 1)
stage1 = [
    {
        "wave_number": 1,
        "reward_energy": 120,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 8, "interval": 1.0, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 12, "interval": 0.7, "delay": 2.0}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 500,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 12, "interval": 0.9, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 16, "interval": 0.6, "delay": 2.0}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 300,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 16, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 2, "interval": 0.5, "delay": 2.0}, # Intro speeder
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 2, "interval": 1.5, "delay": 3.5},   # Intro heavy
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 1, "interval": 2.5, "delay": 6.5}     # Intro tank
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 6, "interval": 0.4, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 6, "interval": 1.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 2, "interval": 2.5, "delay": 7.0}
        ]
    }
]

# Stage 2: 1 Spawner
# Introduces: splitter (intro 1 in wave 2, 2 in wave 3, 3 in wave 4)
stage2 = [
    {
        "wave_number": 1,
        "reward_energy": 150,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 10, "interval": 0.9, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 14, "interval": 0.6, "delay": 2.0}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 200,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 15, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 6, "interval": 0.4, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 5, "interval": 1.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 1, "interval": 1.2, "delay": 5.0} # Intro splitter (1)
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 250,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 18, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 16, "interval": 0.6, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 7, "interval": 1.2, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 2, "interval": 1.2, "delay": 5.0},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 2, "interval": 2.5, "delay": 7.0}
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 22, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 8, "interval": 0.35, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 9, "interval": 1.2, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.2, "delay": 5.0},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 3, "interval": 2.5, "delay": 7.0}
        ]
    }
]

# Stage 3: 1 Spawner
# Introduces: ghost (intro 2), sniper (intro 2)
stage3 = [
    {
        "wave_number": 1,
        "reward_energy": 180,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 14, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 15, "interval": 0.6, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 5, "interval": 1.3, "delay": 3.5}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 220,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 16, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 8, "interval": 0.4, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 7, "interval": 1.2, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 2, "interval": 1.2, "delay": 5.0}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 280,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 18, "interval": 0.55, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 9, "interval": 1.2, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.2, "delay": 5.0},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 3, "interval": 2.5, "delay": 7.0}
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 24, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 10, "interval": 1.1, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 10, "interval": 0.35, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 2, "interval": 1.0, "delay": 4.5}, # Intro ghost (2)
            {"spawner_id": "Spawner", "enemy_type": "sniper", "count": 2, "interval": 1.5, "delay": 6.0}, # Intro sniper (2)
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 7.5},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 4, "interval": 2.0, "delay": 9.0}
        ]
    }
]

# Stage 4: 1 Spawner (5 waves)
stage4 = [
    {
        "wave_number": 1,
        "reward_energy": 180,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 14, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 16, "interval": 0.6, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 6, "interval": 1.3, "delay": 3.5}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 220,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 18, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 8, "interval": 0.4, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 8, "interval": 1.2, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 2, "interval": 1.2, "delay": 5.0}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 260,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 10, "interval": 1.1, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 10, "interval": 0.35, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 3, "interval": 0.9, "delay": 4.5},
            {"spawner_id": "Spawner", "enemy_type": "sniper", "count": 3, "interval": 1.3, "delay": 6.0},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 7.0},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 3, "interval": 2.0, "delay": 8.5}
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 300,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 25, "interval": 0.5, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 22, "interval": 0.7, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 12, "interval": 1.1, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 4.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "sniper", "count": 4, "interval": 1.2, "delay": 6.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 7.5},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 4, "interval": 2.0, "delay": 8.5}
        ]
    },
    {
        "wave_number": 5,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 26, "interval": 0.7, "delay": 0.5},
            {"spawner_id": "Spawner", "enemy_type": "light", "count": 25, "interval": 0.5, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 14, "interval": 1.0, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 4.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "sniper", "count": 5, "interval": 1.2, "delay": 6.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 7.5},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 5, "interval": 2.0, "delay": 8.5}
        ]
    }
]

# Stage 5: 2 Spawners (Spawner, Spawner2) (5 waves)
stage5 = [
    {
        "wave_number": 1,
        "reward_energy": 180,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 14, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 18, "interval": 0.55, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 6, "interval": 1.3, "delay": 3.0}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 220,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 18, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 8, "interval": 0.4, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 8, "interval": 1.2, "delay": 3.0},
            {"spawner_id": "Spawner2", "enemy_type": "splitter", "count": 2, "interval": 1.2, "delay": 4.5}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 260,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 20, "interval": 0.5, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 10, "interval": 1.1, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 10, "interval": 0.35, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 3, "interval": 0.9, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 3, "interval": 1.3, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 3, "interval": 2.0, "delay": 7.5}
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 300,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 22, "interval": 0.7, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 24, "interval": 0.5, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 12, "interval": 1.1, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 4, "interval": 1.2, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 4, "interval": 2.0, "delay": 7.5}
        ]
    },
    {
        "wave_number": 5,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 26, "interval": 0.7, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 28, "interval": 0.45, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 14, "interval": 1.0, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 5, "interval": 1.2, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 5, "interval": 2.0, "delay": 7.5}
        ]
    }
]

# Stage 6: 2 Spawners (Spawner, Spawner2) (5 waves)
# Introduces citadel in Wave 5 (intro 1)
stage6 = [
    {
        "wave_number": 1,
        "reward_energy": 180,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 16, "interval": 0.8, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 20, "interval": 0.55, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 7, "interval": 1.3, "delay": 3.0}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 220,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.75, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 10, "interval": 0.4, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 9, "interval": 1.2, "delay": 3.0},
            {"spawner_id": "Spawner2", "enemy_type": "ghost", "count": 3, "interval": 0.9, "delay": 4.0},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 2, "interval": 1.0, "delay": 5.0},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 3, "interval": 2.0, "delay": 6.0}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 260,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 22, "interval": 0.7, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 24, "interval": 0.5, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 11, "interval": 1.1, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 12, "interval": 0.35, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 4, "interval": 1.3, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 4, "interval": 2.0, "delay": 7.5}
        ]
    },
    {
        "wave_number": 4,
        "reward_energy": 300,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 24, "interval": 0.7, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 28, "interval": 0.45, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 13, "interval": 1.1, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 5, "interval": 0.8, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 5, "interval": 1.2, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 5, "interval": 2.0, "delay": 7.5}
        ]
    },
    {
        "wave_number": 5,
        "reward_energy": 0,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 28, "interval": 0.65, "delay": 0.5},
            {"spawner_id": "Spawner2", "enemy_type": "light", "count": 30, "interval": 0.4, "delay": 1.5},
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 15, "interval": 1.0, "delay": 2.5},
            {"spawner_id": "Spawner2", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 5, "interval": 0.8, "delay": 4.5},
            {"spawner_id": "Spawner2", "enemy_type": "sniper", "count": 5, "interval": 1.2, "delay": 5.5},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5},
            {"spawner_id": "Spawner2", "enemy_type": "tank", "count": 6, "interval": 1.8, "delay": 7.5},
            {"spawner_id": "Spawner", "enemy_type": "citadel", "count": 1, "interval": 4.0, "delay": 9.0} # Intro citadel (1)
        ]
    }
]

# Helper to build mid/late stages
def make_mid_late_stage(stage_num: int, num_waves: int, spawners: list, base_reward: int = 200, reward_step: int = 30):
    waves = []
    stage_scale = (stage_num - 6) / 14.0 # 0.0 to 1.0
    
    for w in range(1, num_waves + 1):
        wave_scale = (w - 1) / float(max(1, num_waves - 1)) # 0.0 to 1.0
        combined_scale = 0.5 * stage_scale + 0.5 * wave_scale
        is_final_wave = (w == num_waves)
        reward = 0 if is_final_wave else (base_reward + (w - 1) * reward_step)
        
        spawns = []
        s_count = len(spawners)
        
        # 1. Main swarm of grunts & lights
        grunt_count = int(18 + 18 * combined_scale)
        light_count = int(20 + 25 * combined_scale)
        heavy_count = int(8 + 14 * combined_scale)
        tank_count = int(2 + 10 * combined_scale)
        
        spawns.append({
            "spawner_id": spawners[0 % s_count],
            "enemy_type": "grunt",
            "count": grunt_count,
            "interval": round(max(0.45, 0.8 - 0.25 * combined_scale), 2),
            "delay": 0.5
        })
        
        spawns.append({
            "spawner_id": spawners[1 % s_count],
            "enemy_type": "light",
            "count": light_count,
            "interval": round(max(0.3, 0.6 - 0.25 * combined_scale), 2),
            "delay": 1.0
        })
        
        spawns.append({
            "spawner_id": spawners[0 % s_count],
            "enemy_type": "heavy",
            "count": heavy_count,
            "interval": round(max(0.8, 1.3 - 0.4 * combined_scale), 2),
            "delay": 2.0
        })
        
        # 2. Speeder burst squad (max 12)
        speeder_count = min(12, int(6 + 6 * combined_scale))
        spawns.append({
            "spawner_id": spawners[1 % s_count],
            "enemy_type": "speeder",
            "count": speeder_count,
            "interval": round(max(0.25, 0.45 - 0.15 * combined_scale), 2),
            "delay": 3.0
        })
        
        # 3. Ghosts (up to 15 on late stages)
        ghost_count = min(15, int(3 + 10 * combined_scale))
        spawns.append({
            "spawner_id": spawners[0 % s_count],
            "enemy_type": "ghost",
            "count": ghost_count,
            "interval": round(max(0.6, 0.9 - 0.25 * combined_scale), 2),
            "delay": 4.0
        })
        
        # 4. Snipers (5-10)
        sniper_count = min(10, max(3, int(3 + 7 * combined_scale)))
        spawns.append({
            "spawner_id": spawners[(2 if s_count > 2 else 0) % s_count],
            "enemy_type": "sniper",
            "count": sniper_count,
            "interval": round(max(1.0, 1.4 - 0.3 * combined_scale), 2),
            "delay": 5.0
        })
        
        # 5. Splitters (strictly <= 3 per group)
        splitter_spawner = spawners[(2 if s_count > 2 else 1) % s_count]
        spawns.append({
            "spawner_id": splitter_spawner,
            "enemy_type": "splitter",
            "count": 3,
            "interval": 0.9,
            "delay": 6.0
        })
        
        # If there are 3+ or 4 spawners and it's a late wave, add another tight 2-3 splitter group on another lane
        if s_count >= 3 and combined_scale > 0.6:
            spawns.append({
                "spawner_id": spawners[3 % s_count if s_count >= 4 else 0],
                "enemy_type": "splitter",
                "count": 2,
                "interval": 1.0,
                "delay": 7.0
            })
            
        # 6. Tanks (core siege push)
        spawns.append({
            "spawner_id": spawners[1 % s_count],
            "enemy_type": "tank",
            "count": tank_count,
            "interval": round(max(1.4, 2.2 - 0.6 * combined_scale), 2),
            "delay": 7.5
        })
        
        # 7. Citadel on boss / late waves (1-2 per group)
        if is_final_wave or (combined_scale > 0.75 and w >= num_waves - 1):
            citadel_count = 2 if (stage_num >= 16 and is_final_wave) else 1
            spawns.append({
                "spawner_id": spawners[0 % s_count],
                "enemy_type": "citadel",
                "count": citadel_count,
                "interval": 3.5,
                "delay": 9.0
            })
            if s_count > 1 and stage_num >= 17 and is_final_wave:
                spawns.append({
                    "spawner_id": spawners[1 % s_count],
                    "enemy_type": "citadel",
                    "count": 1,
                    "interval": 3.5,
                    "delay": 11.0
                })
        
        waves.append({
            "wave_number": w,
            "reward_energy": reward,
            "spawns": spawns
        })
        
    return waves

# Generate stages 0 to 6
write_wave_file("Stage0.json", stage0)
write_wave_file("Stage1.json", stage1)
write_wave_file("Stage2.json", stage2)
write_wave_file("Stage3.json", stage3)
write_wave_file("Stage4.json", stage4)
write_wave_file("Stage5.json", stage5)
write_wave_file("Stage6.json", stage6)

# Stage 7 to 20 configs
stage_configs = {
    7: (6, ["Spawner", "Spawner2"], 200, 30),
    8: (6, ["Spawner", "Spawner2", "Spawner3", "Spawner4"], 200, 30),
    9: (6, ["Spawner", "Spawner2"], 220, 30),
    10: (6, ["Spawner", "Spawner2"], 220, 35),
    11: (7, ["Spawner", "Spawner2", "Spawner3", "Spawner4"], 220, 35),
    12: (7, ["Spawner", "Spawner2"], 220, 35),
    13: (7, ["Spawner"], 240, 35),
    14: (8, ["Spawner", "Spawner2", "Spawner3", "Spawner4"], 240, 35),
    15: (8, ["Spawner", "Spawner2"], 240, 35),
    16: (8, ["Spawner", "Spawner2", "Spawner3"], 240, 35),
    17: (9, ["Spawner", "Spawner2", "Spawner3"], 250, 40),
    18: (9, ["Spawner", "Spawner2"], 250, 40),
    19: (9, ["Spawner", "Spawner2", "Spawner3"], 250, 40),
    20: (10, ["Spawner", "Spawner2"], 250, 40),
}

for s_num, (n_waves, spws, base_rew, rew_step) in stage_configs.items():
    wdata = make_mid_late_stage(s_num, n_waves, spws, base_rew, rew_step)
    write_wave_file(f"Stage{s_num}.json", wdata)

# TestStageData.json
test_stage = [
    {
        "wave_number": 1,
        "reward_energy": 400,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 15, "interval": 0.8, "delay": 0.0},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 4, "interval": 0.8, "delay": 2.0}
        ]
    },
    {
        "wave_number": 2,
        "reward_energy": 600,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "grunt", "count": 20, "interval": 0.7, "delay": 0.0},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 10, "interval": 0.35, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "ghost", "count": 6, "interval": 0.7, "delay": 3.5},
            {"spawner_id": "Spawner", "enemy_type": "sniper", "count": 5, "interval": 1.2, "delay": 5.0},
            {"spawner_id": "Spawner", "enemy_type": "splitter", "count": 3, "interval": 1.0, "delay": 6.5}
        ]
    },
    {
        "wave_number": 3,
        "reward_energy": 1000,
        "spawns": [
            {"spawner_id": "Spawner", "enemy_type": "heavy", "count": 15, "interval": 1.0, "delay": 0.0},
            {"spawner_id": "Spawner", "enemy_type": "speeder", "count": 12, "interval": 0.3, "delay": 2.0},
            {"spawner_id": "Spawner", "enemy_type": "tank", "count": 6, "interval": 1.8, "delay": 4.0},
            {"spawner_id": "Spawner", "enemy_type": "citadel", "count": 1, "interval": 3.0, "delay": 7.0}
        ]
    }
]
write_wave_file("TestStageData.json", test_stage)
print("All wave files generated successfully!")
