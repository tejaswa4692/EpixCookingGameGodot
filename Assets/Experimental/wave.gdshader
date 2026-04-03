shader_type spatial;
render_mode cull_disabled;

uniform vec4 pink_color : source_color = vec4(1.0, 0.75, 0.85, 1.0);
uniform vec4 white_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float stripe_count : hint_range(1.0, 50.0) = 10.0;

uniform float amplitude : hint_range(0.0, 2.0) = 0.3;
uniform float frequency : hint_range(0.0, 10.0) = 2.0;
uniform float speed : hint_range(0.0, 20.0) = 1.0;

void vertex() {
    float wave = sin(VERTEX.x * frequency + TIME * speed) * amplitude;
    VERTEX.y += wave;
}

void fragment() {

    // Vertical stripes → based on UV.x
    float stripe = step(0.5, fract(UV.x * stripe_count));
    vec4 color = mix(pink_color, white_color, stripe);

    ALBEDO = color.rgb;
    ALPHA = color.a;
}
