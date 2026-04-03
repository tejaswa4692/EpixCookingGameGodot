shader_type spatial;
render_mode cull_disabled;

uniform vec4 leaf_color : source_color = vec4(0.533, 0.659, 0.255, 1.0); // #88A841

uniform float amplitude : hint_range(0.0, 1.0) = 0.15;
uniform float frequency : hint_range(0.0, 10.0) = 2.5;
uniform float speed : hint_range(0.0, 5.0) = 1.2;

void vertex() {
    // Height-based mask (top moves more than bottom)
    float height_mask = clamp(VERTEX.y, 0.0, 1.0);

    float wave = sin(
        VERTEX.x * frequency +
        TIME * speed
    ) * amplitude * height_mask;

    // Sway sideways like wind
    VERTEX.x += wave;
}

void fragment() {
    ALBEDO = leaf_color.rgb;
    ALPHA = leaf_color.a;
}
