#include "flow_field.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>
#include <vector>

namespace godot {

static const Vector2i NEIGHBORS[8] = {
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1)
};

static const Vector2 NEIGHBOR_DIRS[8] = {
	Vector2(0.0f, -1.0f),
	Vector2(-1.0f, 0.0f),
	Vector2(1.0f, 0.0f),
	Vector2(0.0f, 1.0f),
	Vector2(-0.70710678f, -0.70710678f),
	Vector2(0.70710678f, -0.70710678f),
	Vector2(-0.70710678f, 0.70710678f),
	Vector2(0.70710678f, 0.70710678f)
};

static const float NEIGHBOR_DIST[8] = {
	1.0f,
	1.0f,
	1.0f,
	1.0f,
	1.41421356f,
	1.41421356f,
	1.41421356f,
	1.41421356f
};

void FlowField::_bind_methods() {
	ClassDB::bind_method(D_METHOD("init_grid", "width", "height", "cell_size", "origin"), &FlowField::init_grid, DEFVAL(Vector2(0, 0)));

	ClassDB::bind_method(D_METHOD("get_width"), &FlowField::get_width);
	ClassDB::bind_method(D_METHOD("set_width", "val"), &FlowField::set_width);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "width"), "set_width", "get_width");

	ClassDB::bind_method(D_METHOD("get_height"), &FlowField::get_height);
	ClassDB::bind_method(D_METHOD("set_height", "val"), &FlowField::set_height);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "height"), "set_height", "get_height");

	ClassDB::bind_method(D_METHOD("get_cell_size"), &FlowField::get_cell_size);
	ClassDB::bind_method(D_METHOD("set_cell_size", "val"), &FlowField::set_cell_size);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "cell_size"), "set_cell_size", "get_cell_size");

	ClassDB::bind_method(D_METHOD("get_origin"), &FlowField::get_origin);
	ClassDB::bind_method(D_METHOD("set_origin", "val"), &FlowField::set_origin);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "origin"), "set_origin", "get_origin");

	ClassDB::bind_method(D_METHOD("get_cost_grid"), &FlowField::get_cost_grid);
	ClassDB::bind_method(D_METHOD("set_cost_grid", "val"), &FlowField::set_cost_grid);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "cost_grid"), "set_cost_grid", "get_cost_grid");

	ClassDB::bind_method(D_METHOD("get_integration_grid"), &FlowField::get_integration_grid);
	ClassDB::bind_method(D_METHOD("set_integration_grid", "val"), &FlowField::set_integration_grid);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "integration_grid"), "set_integration_grid", "get_integration_grid");

	ClassDB::bind_method(D_METHOD("get_field"), &FlowField::get_field);
	ClassDB::bind_method(D_METHOD("set_field", "val"), &FlowField::set_field);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "field"), "set_field", "get_field");

	ClassDB::bind_method(D_METHOD("get_targets"), &FlowField::get_targets);
	ClassDB::bind_method(D_METHOD("set_targets", "val"), &FlowField::set_targets);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "targets", PROPERTY_HINT_ARRAY_TYPE, "Vector2i"), "set_targets", "get_targets");

	ClassDB::bind_method(D_METHOD("get_index", "pos"), &FlowField::get_index);
	ClassDB::bind_method(D_METHOD("_index", "pos"), &FlowField::_index);
	ClassDB::bind_method(D_METHOD("is_in_bounds", "pos"), &FlowField::is_in_bounds);
	ClassDB::bind_method(D_METHOD("world_to_grid", "world_pos"), &FlowField::world_to_grid);
	ClassDB::bind_method(D_METHOD("get_cost", "target"), &FlowField::get_cost);

	ClassDB::bind_method(D_METHOD("add_target", "target"), &FlowField::add_target);
	ClassDB::bind_method(D_METHOD("query", "world_pos"), &FlowField::query);
	ClassDB::bind_method(D_METHOD("set_cost", "target", "cost"), &FlowField::set_cost);
	ClassDB::bind_method(D_METHOD("set_impassable", "target"), &FlowField::set_impassable);
	ClassDB::bind_method(D_METHOD("set_obstructed", "target"), &FlowField::set_obstructed);
	ClassDB::bind_method(D_METHOD("reset", "target"), &FlowField::reset, DEFVAL(Variant()));
	ClassDB::bind_method(D_METHOD("clear_targets"), &FlowField::clear_targets);
	ClassDB::bind_method(D_METHOD("is_walkable", "target"), &FlowField::is_walkable);
	ClassDB::bind_method(D_METHOD("is_reachable", "world_pos"), &FlowField::is_reachable);
	ClassDB::bind_method(D_METHOD("is_obstructed", "world_pos"), &FlowField::is_obstructed);
	ClassDB::bind_method(D_METHOD("get_integration_cost", "world_pos"), &FlowField::get_integration_cost);
	ClassDB::bind_method(D_METHOD("trace_path", "start_pos", "step_size", "max_steps", "goal_targets"), &FlowField::trace_path, DEFVAL(16.0f), DEFVAL(300), DEFVAL(Array()));
	ClassDB::bind_method(D_METHOD("rebuild"), &FlowField::rebuild);

	BIND_CONSTANT(COST_DEFAULT);
	BIND_CONSTANT(COST_OBSTRUCTED);
	BIND_CONSTANT(COST_IMPASSABLE);
	BIND_CONSTANT(INTEGRATION_MAX);
	BIND_CONSTANT(PADDING_RADIUS);
}

void FlowField::init_grid(int p_width, int p_height, int p_cell_size, const Vector2 &p_origin) {
	width = p_width;
	height = p_height;
	cell_size = p_cell_size;
	origin = p_origin;

	int total = width * height;
	cost_grid.resize(total);
	cost_grid.fill((float)COST_DEFAULT);

	integration_grid.resize(total);
	integration_grid.fill((float)INTEGRATION_MAX);

	field.resize(total);
	field.fill(Vector2(0, 0));
}

void FlowField::add_target(const Variant &p_target) {
	set_cost(p_target, 0.0f);

	if (p_target.get_type() == Variant::VECTOR2) {
		Vector2 pos = p_target;
		Vector2i grid_pos = _world_to_grid(pos);
		if (_is_in_bounds(grid_pos) && !targets.has(grid_pos)) {
			targets.append(grid_pos);
		}
	} else if (p_target.get_type() == Variant::VECTOR2I) {
		Vector2i grid_pos = p_target;
		if (_is_in_bounds(grid_pos) && !targets.has(grid_pos)) {
			targets.append(grid_pos);
		}
	} else if (p_target.get_type() == Variant::RECT2) {
		Rect2 r = p_target;
		Vector2i top_left = _world_to_grid(r.position);
		Vector2i bottom_right = _world_to_grid(r.position + r.size);
		int min_x = Math::clamp(top_left.x, 0, width);
		int max_x = Math::clamp(bottom_right.x, 0, width);
		int min_y = Math::clamp(top_left.y, 0, height);
		int max_y = Math::clamp(bottom_right.y, 0, height);
		for (int y = min_y; y < max_y; ++y) {
			for (int x = min_x; x < max_x; ++x) {
				Vector2i cell(x, y);
				if (!targets.has(cell)) {
					targets.append(cell);
				}
			}
		}
	} else if (p_target.get_type() == Variant::RECT2I) {
		Rect2i r = p_target;
		int min_x = Math::clamp(r.position.x, 0, width);
		int max_x = Math::clamp(r.position.x + r.size.x, 0, width);
		int min_y = Math::clamp(r.position.y, 0, height);
		int max_y = Math::clamp(r.position.y + r.size.y, 0, height);
		for (int y = min_y; y < max_y; ++y) {
			for (int x = min_x; x < max_x; ++x) {
				Vector2i cell(x, y);
				if (!targets.has(cell)) {
					targets.append(cell);
				}
			}
		}
	}
}

Vector2 FlowField::query(const Vector2 &p_world_pos) const {
	if (width <= 0 || height <= 0 || cell_size <= 0) {
		return Vector2(0, 0);
	}

	Vector2 local = (p_world_pos - origin) / (float)cell_size - Vector2(0.5f, 0.5f);
	int x0 = (int)Math::floor(local.x);
	int y0 = (int)Math::floor(local.y);
	float fx = local.x - (float)x0;
	float fy = local.y - (float)y0;

	int x1 = x0 + 1;
	int y1 = y0 + 1;

	bool in00 = (x0 >= 0 && x0 < width && y0 >= 0 && y0 < height);
	bool in10 = (x1 >= 0 && x1 < width && y0 >= 0 && y0 < height);
	bool in01 = (x0 >= 0 && x0 < width && y1 >= 0 && y1 < height);
	bool in11 = (x1 >= 0 && x1 < width && y1 >= 0 && y1 < height);

	if (!in00 && !in10 && !in01 && !in11) {
		return Vector2(0, 0);
	}

	const float *cost_ptr = cost_grid.ptr();
	const Vector2 *field_ptr = field.ptr();

	bool open00 = in00 && (cost_ptr[y0 * width + x0] < (float)COST_IMPASSABLE);
	bool open10 = in10 && (cost_ptr[y0 * width + x1] < (float)COST_IMPASSABLE);
	bool open01 = in01 && (cost_ptr[y1 * width + x0] < (float)COST_IMPASSABLE);
	bool open11 = in11 && (cost_ptr[y1 * width + x1] < (float)COST_IMPASSABLE);

	float w00 = open00 ? (1.0f - fx) * (1.0f - fy) : 0.0f;
	float w10 = open10 ? fx * (1.0f - fy) : 0.0f;
	float w01 = open01 ? (1.0f - fx) * fy : 0.0f;
	float w11 = open11 ? fx * fy : 0.0f;

	float total_w = w00 + w10 + w01 + w11;
	if (total_w > 0.001f) {
		Vector2 v00 = open00 ? field_ptr[y0 * width + x0] : Vector2(0, 0);
		Vector2 v10 = open10 ? field_ptr[y0 * width + x1] : Vector2(0, 0);
		Vector2 v01 = open01 ? field_ptr[y1 * width + x0] : Vector2(0, 0);
		Vector2 v11 = open11 ? field_ptr[y1 * width + x1] : Vector2(0, 0);

		Vector2 blended = (v00 * w00 + v10 * w10 + v01 * w01 + v11 * w11) / total_w;
		if (blended.length_squared() > 0.0001f) {
			return blended.normalized();
		}
	}

	Vector2i nearest_cell = _world_to_grid(p_world_pos);
	if (_is_in_bounds(nearest_cell)) {
		return field_ptr[_index(nearest_cell)];
	}
	return Vector2(0, 0);
}

void FlowField::set_cost(const Variant &p_target, float p_cost) {
	float *cost_ptr = cost_grid.ptrw();

	if (p_target.get_type() == Variant::VECTOR2) {
		Vector2i grid_pos = _world_to_grid(p_target);
		if (_is_in_bounds(grid_pos)) {
			cost_ptr[_index(grid_pos)] = p_cost;
		}
	} else if (p_target.get_type() == Variant::VECTOR2I) {
		Vector2i grid_pos = p_target;
		if (_is_in_bounds(grid_pos)) {
			cost_ptr[_index(grid_pos)] = p_cost;
		}
	} else if (p_target.get_type() == Variant::RECT2) {
		Rect2 r = p_target;
		Vector2i top_left = _world_to_grid(r.position);
		Vector2i bottom_right = _world_to_grid(r.position + r.size);
		int min_x = Math::clamp(top_left.x, 0, width);
		int max_x = Math::clamp(bottom_right.x, 0, width);
		int min_y = Math::clamp(top_left.y, 0, height);
		int max_y = Math::clamp(bottom_right.y, 0, height);
		for (int y = min_y; y < max_y; ++y) {
			for (int x = min_x; x < max_x; ++x) {
				cost_ptr[y * width + x] = p_cost;
			}
		}
	} else if (p_target.get_type() == Variant::RECT2I) {
		Rect2i r = p_target;
		int min_x = Math::clamp(r.position.x, 0, width);
		int max_x = Math::clamp(r.position.x + r.size.x, 0, width);
		int min_y = Math::clamp(r.position.y, 0, height);
		int max_y = Math::clamp(r.position.y + r.size.y, 0, height);
		for (int y = min_y; y < max_y; ++y) {
			for (int x = min_x; x < max_x; ++x) {
				cost_ptr[y * width + x] = p_cost;
			}
		}
	}
}

float FlowField::get_cost(const Variant &p_target) const {
	if (cost_grid.is_empty()) return (float)COST_DEFAULT;
	Vector2i pos;
	if (p_target.get_type() == Variant::VECTOR2) {
		pos = _world_to_grid(p_target);
	} else if (p_target.get_type() == Variant::VECTOR2I) {
		pos = p_target;
	} else {
		return (float)COST_DEFAULT;
	}
	if (!_is_in_bounds(pos)) return (float)COST_IMPASSABLE;
	return cost_grid.ptr()[_index(pos)];
}

bool FlowField::is_walkable(const Variant &p_target) const {
	return get_cost(p_target) < (float)COST_IMPASSABLE;
}

void FlowField::set_impassable(const Variant &p_target) {
	set_cost(p_target, (float)COST_IMPASSABLE);
}

void FlowField::set_obstructed(const Variant &p_target) {
	set_cost(p_target, (float)COST_OBSTRUCTED);
}

void FlowField::reset(const Variant &p_target) {
	if (p_target.get_type() == Variant::NIL) {
		cost_grid.fill((float)COST_DEFAULT);
	} else {
		set_cost(p_target, (float)COST_DEFAULT);
	}
}

void FlowField::clear_targets() {
	targets.clear();
}

bool FlowField::is_reachable(const Vector2 &p_world_pos) const {
	Vector2i grid_cell = _world_to_grid(p_world_pos);
	if (!_is_in_bounds(grid_cell)) {
		return false;
	}
	return integration_grid.ptr()[_index(grid_cell)] < (float)INTEGRATION_MAX;
}

bool FlowField::is_obstructed(const Vector2 &p_world_pos) const {
	Vector2i grid_cell = _world_to_grid(p_world_pos);
	if (!_is_in_bounds(grid_cell)) {
		return true;
	}
	float cost = integration_grid.ptr()[_index(grid_cell)];
	return cost >= (float)COST_OBSTRUCTED && cost < (float)INTEGRATION_MAX;
}

float FlowField::get_integration_cost(const Vector2 &p_world_pos) const {
	Vector2i grid_cell = _world_to_grid(p_world_pos);
	if (!_is_in_bounds(grid_cell)) {
		return (float)INTEGRATION_MAX;
	}
	return integration_grid.ptr()[_index(grid_cell)];
}

PackedVector2Array FlowField::trace_path(const Vector2 &p_start_pos, float p_step_size, int p_max_steps, const Array &p_goal_targets) const {
	if (!is_reachable(p_start_pos)) {
		return PackedVector2Array();
	}

	PackedVector2Array path;
	path.append(p_start_pos);

	Vector2 curr_pos = p_start_pos;
	std::vector<Vector2> goal_positions;
	std::vector<Rect2> goal_rects;

	for (int i = 0; i < p_goal_targets.size(); ++i) {
		Variant g = p_goal_targets[i];
		if (g.get_type() == Variant::VECTOR2) {
			goal_positions.push_back((Vector2)g);
		} else if (g.get_type() == Variant::RECT2) {
			goal_rects.push_back((Rect2)g);
		} else if (g.get_type() == Variant::OBJECT) {
			Object *obj = g;
			if (obj) {
				if (obj->has_method("get_global_rect")) {
					goal_rects.push_back(obj->call("get_global_rect"));
				} else if (obj->is_class("Node2D")) {
					goal_positions.push_back(obj->get("global_position"));
				}
			}
		}
	}

	for (int step = 0; step < p_max_steps; ++step) {
		bool arrived = false;
		for (const Rect2 &gr : goal_rects) {
			if (gr.has_point(curr_pos)) {
				arrived = true;
				break;
			}
		}
		if (arrived) break;

		for (const Vector2 &gp : goal_positions) {
			if (curr_pos.distance_to(gp) <= p_step_size) {
				path.append(gp);
				arrived = true;
				break;
			}
		}
		if (arrived) break;

		Vector2i grid_pos = _world_to_grid(curr_pos);
		if (goal_positions.empty() && goal_rects.empty() && targets.has(grid_pos)) {
			break;
		}

		Vector2 k1 = query(curr_pos);
		if (k1.length_squared() < 0.0001f) {
			break;
		}

		Vector2 mid_pos = curr_pos + k1 * (p_step_size * 0.5f);
		Vector2 k2 = query(mid_pos);
		Vector2 step_dir = (k2.length_squared() > 0.0001f) ? k2 : k1;

		Vector2 next_pos = curr_pos + step_dir * p_step_size;
		if (next_pos.distance_squared_to(curr_pos) < 0.01f) {
			break;
		}

		path.append(next_pos);
		curr_pos = next_pos;
	}

	return path;
}

void FlowField::rebuild() {
	integration_grid.fill((float)INTEGRATION_MAX);
	_integrate();
	_calculate_flow();
}

void FlowField::_integrate() {
	if (width <= 0 || height <= 0) return;

	int total_cells = width * height;
	const float *cost_ptr = cost_grid.ptr();

	// Local effective costs with soft obstacle dilation
	std::vector<float> effective_costs(total_cells);
	std::copy(cost_ptr, cost_ptr + total_cells, effective_costs.begin());

	if (PADDING_RADIUS > 0 && PADDING_ADDED_COST > 0.0f) {
		for (int y = 0; y < height; ++y) {
			for (int x = 0; x < width; ++x) {
				int idx = y * width + x;
				if (cost_ptr[idx] >= PADDING_MIN_OBSTACLE_COST) {
					for (int dy = -PADDING_RADIUS; dy <= PADDING_RADIUS; ++dy) {
						for (int dx = -PADDING_RADIUS; dx <= PADDING_RADIUS; ++dx) {
							if (dx == 0 && dy == 0) continue;
							int nx = x + dx;
							int ny = y + dy;
							if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
								int n_idx = ny * width + nx;
								if (cost_ptr[n_idx] < PADDING_MIN_OBSTACLE_COST) {
									float dist = std::sqrt((float)(dx * dx + dy * dy));
									float penalty = PADDING_ADDED_COST / dist;
									effective_costs[n_idx] = std::max(effective_costs[n_idx], (float)COST_DEFAULT + penalty);
								}
							}
						}
					}
				}
			}
		}
	}

	float *integ_ptr = integration_grid.ptrw();
	std::vector<int> queue;
	queue.reserve(total_cells);

	for (int i = 0; i < targets.size(); ++i) {
		Vector2i target = targets[i];
		if (_is_in_bounds(target)) {
			int idx = _index(target);
			integ_ptr[idx] = 0.0f;
			queue.push_back(idx);
		}
	}

	size_t head = 0;
	while (head < queue.size()) {
		int curr_idx = queue[head++];
		float curr_cost = integ_ptr[curr_idx];
		Vector2i curr_pos(curr_idx % width, curr_idx / width);

		for (int i = 0; i < 8; ++i) {
			Vector2i neighbor_pos = curr_pos + NEIGHBORS[i];
			if (!_is_in_bounds(neighbor_pos)) continue;

			int n_idx = _index(neighbor_pos);
			if (cost_ptr[n_idx] >= (float)COST_IMPASSABLE) continue;

			float step_cost = effective_costs[n_idx];
			if (i >= 4) {
				int idx_o1 = _index(Vector2i(neighbor_pos.x, curr_pos.y));
				int idx_o2 = _index(Vector2i(curr_pos.x, neighbor_pos.y));
				float c_o1 = cost_ptr[idx_o1];
				float c_o2 = cost_ptr[idx_o2];
				if (c_o1 >= (float)COST_IMPASSABLE || c_o2 >= (float)COST_IMPASSABLE) {
					continue;
				}
				step_cost = std::max(step_cost, std::max(effective_costs[idx_o1], effective_costs[idx_o2]));
			}

			float cost = curr_cost + step_cost * NEIGHBOR_DIST[i];
			if (integ_ptr[n_idx] > cost) {
				integ_ptr[n_idx] = cost;
				queue.push_back(n_idx);
			}
		}
	}
}

void FlowField::_calculate_flow() {
	if (width <= 0 || height <= 0) return;

	const float *integ_ptr = integration_grid.ptr();
	const float *cost_ptr = cost_grid.ptr();
	Vector2 *field_ptr = field.ptrw();

	for (int grid_y = 0; grid_y < height; ++grid_y) {
		for (int grid_x = 0; grid_x < width; ++grid_x) {
			Vector2i curr_pos(grid_x, grid_y);
			int cell_idx = _index(curr_pos);
			float curr_cost = integ_ptr[cell_idx];

			if (curr_cost >= (float)INTEGRATION_MAX || curr_cost == 0.0f) {
				field_ptr[cell_idx] = Vector2(0, 0);
				continue;
			}

			Vector2 flow_vec(0, 0);

			for (int i = 0; i < 8; ++i) {
				Vector2i neighbor_pos = curr_pos + NEIGHBORS[i];
				if (!_is_in_bounds(neighbor_pos)) continue;

				int n_idx = _index(neighbor_pos);
				if (cost_ptr[n_idx] >= (float)COST_IMPASSABLE) continue;

				if (i >= 4) {
					float c_o1 = cost_ptr[_index(Vector2i(neighbor_pos.x, curr_pos.y))];
					float c_o2 = cost_ptr[_index(Vector2i(curr_pos.x, neighbor_pos.y))];
					if (c_o1 >= (float)COST_IMPASSABLE || c_o2 >= (float)COST_IMPASSABLE) {
						continue;
					}
				}

				float n_cost = integ_ptr[n_idx];
				if (n_cost < curr_cost) {
					float drop = (curr_cost - n_cost) / NEIGHBOR_DIST[i];
					flow_vec += NEIGHBOR_DIRS[i] * drop;
				}
			}

			// Convex Corner Stagnation Deflection
			if (flow_vec.length_squared() > 0.0001f) {
				int sx = (flow_vec.x > 0.15f) ? 1 : ((flow_vec.x < -0.15f) ? -1 : 0);
				int sy = (flow_vec.y > 0.15f) ? 1 : ((flow_vec.y < -0.15f) ? -1 : 0);
				if (sx != 0 && sy != 0) {
					Vector2i diag_pos = curr_pos + Vector2i(sx, sy);
					if (_is_in_bounds(diag_pos) && cost_ptr[_index(diag_pos)] >= (float)COST_IMPASSABLE) {
						Vector2i ox_pos = curr_pos + Vector2i(sx, 0);
						Vector2i oy_pos = curr_pos + Vector2i(0, sy);
						bool ox_open = _is_in_bounds(ox_pos) && (cost_ptr[_index(ox_pos)] < (float)COST_IMPASSABLE);
						bool oy_open = _is_in_bounds(oy_pos) && (cost_ptr[_index(oy_pos)] < (float)COST_IMPASSABLE);
						if (ox_open && oy_open) {
							float c_ox = integ_ptr[_index(ox_pos)];
							float c_oy = integ_ptr[_index(oy_pos)];
							if (c_ox < c_oy) {
								flow_vec = Vector2((float)sx, 0.0f);
							} else {
								flow_vec = Vector2(0.0f, (float)sy);
							}
						} else if (ox_open) {
							flow_vec = Vector2((float)sx, 0.0f);
						} else if (oy_open) {
							flow_vec = Vector2(0.0f, (float)sy);
						}
					}
				}

				field_ptr[cell_idx] = flow_vec.normalized();
			} else {
				field_ptr[cell_idx] = Vector2(0, 0);
			}
		}
	}
}

} // namespace godot
