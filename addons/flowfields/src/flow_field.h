#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include <vector>

namespace godot {

class FlowField : public RefCounted {
	GDCLASS(FlowField, RefCounted);

public:
	static constexpr int COST_DEFAULT = 1;
	static constexpr int COST_OBSTRUCTED = 1000;
	static constexpr int COST_IMPASSABLE = 10000;
	static constexpr int INTEGRATION_MAX = 2147483647;

	static constexpr int PADDING_RADIUS = 1;
	static constexpr float PADDING_ADDED_COST = 1.0f;
	static constexpr float PADDING_MIN_OBSTACLE_COST = 10.0f;

private:
	int width = 0;
	int height = 0;
	int cell_size = 32;
	Vector2 origin = Vector2(0, 0);

	PackedFloat32Array cost_grid;
	PackedFloat32Array integration_grid;
	PackedVector2Array field;
	TypedArray<Vector2i> targets;

	_FORCE_INLINE_ int _index(const Vector2i &p_pos) const {
		return p_pos.y * width + p_pos.x;
	}

	_FORCE_INLINE_ bool _is_in_bounds(const Vector2i &p_pos) const {
		return p_pos.x >= 0 && p_pos.x < width && p_pos.y >= 0 && p_pos.y < height;
	}

	_FORCE_INLINE_ Vector2i _world_to_grid(const Vector2 &p_world_pos) const {
		Vector2 local = (p_world_pos - origin) / (float)cell_size;
		return Vector2i((int)Math::floor(local.x), (int)Math::floor(local.y));
	}

	void _integrate();
	void _calculate_flow();

protected:
	static void _bind_methods();

public:
	FlowField() = default;
	~FlowField() override = default;

	void init_grid(int p_width, int p_height, int p_cell_size, const Vector2 &p_origin = Vector2(0, 0));

	// Getters and Setters
	int get_width() const { return width; }
	void set_width(int p_val) { width = p_val; }

	int get_height() const { return height; }
	void set_height(int p_val) { height = p_val; }

	int get_cell_size() const { return cell_size; }
	void set_cell_size(int p_val) { cell_size = p_val; }

	Vector2 get_origin() const { return origin; }
	void set_origin(const Vector2 &p_val) { origin = p_val; }

	PackedFloat32Array get_cost_grid() const { return cost_grid; }
	void set_cost_grid(const PackedFloat32Array &p_val) { cost_grid = p_val; }

	PackedFloat32Array get_integration_grid() const { return integration_grid; }
	void set_integration_grid(const PackedFloat32Array &p_val) { integration_grid = p_val; }

	PackedVector2Array get_field() const { return field; }
	void set_field(const PackedVector2Array &p_val) { field = p_val; }

	TypedArray<Vector2i> get_targets() const { return targets; }
	void set_targets(const TypedArray<Vector2i> &p_val) { targets = p_val; }

	int get_index(const Vector2i &p_pos) const { return _index(p_pos); }
	bool is_in_bounds(const Vector2i &p_pos) const { return _is_in_bounds(p_pos); }
	Vector2i world_to_grid(const Vector2 &p_world_pos) const { return _world_to_grid(p_world_pos); }
	float get_cost(const Variant &p_target) const;

	// Public API
	void add_target(const Variant &p_target);
	Vector2 query(const Vector2 &p_world_pos) const;
	void set_cost(const Variant &p_target, float p_cost);
	void set_impassable(const Variant &p_target);
	void set_obstructed(const Variant &p_target);
	void reset(const Variant &p_target = Variant());
	void clear_targets();
	bool is_walkable(const Variant &p_target) const;
	bool is_reachable(const Vector2 &p_world_pos) const;
	bool is_obstructed(const Vector2 &p_world_pos) const;
	float get_integration_cost(const Vector2 &p_world_pos) const;
	PackedVector2Array trace_path(const Vector2 &p_start_pos, float p_step_size = 16.0f, int p_max_steps = 300, const Array &p_goal_targets = Array()) const;
	void rebuild();
};

} // namespace godot
