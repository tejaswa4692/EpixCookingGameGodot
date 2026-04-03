shader_type canvas_item;
render_mode unshaded;

/* SAME UNIFORMS */
uniform sampler2D tex : filter_linear;
uniform int mask_type : hint_enum(
	"Dots:1",
	"Aperture Grille:2",
	"Wide Grille:3",
	"Wide Soft Grille:4",
	"Slot Mask:5",
	"Null:0") = 1;
uniform float curve : hint_range(0.0, 0.5) = 0.0;
uniform float color_offset : hint_range(-0.5, 0.5) = 0.0;
uniform float mask_brightness : hint_range(0, 1) = 1.0;
uniform float aspect : hint_range(0.5, 1.0) = 0.75;


/* ------------------ FUNCTIONS ------------------ */

vec2 warp(vec2 uv, float _aspect, float _curve){
	uv -= 0.5;
	uv.x /= _aspect;
	float warping = dot(uv, uv) * _curve;
	warping -= _curve * 0.25;
	uv /= 1.0 - warping;
	uv.x *= _aspect;
	uv += 0.5;
	return uv;
}

vec3 linear_to_srgb(vec3 col){
	return mix(
		(pow(col, vec3(1.0 / 2.4)) * 1.055) - 0.055,
		col * 12.92,
		lessThan(col, vec3(0.0031318))
	);
}

vec3 srgb_to_linear(vec3 col){
	return mix(
		pow((col + 0.055) / 1.055, vec3(2.4)),
		col / 12.92,
		lessThan(col, vec3(0.04045))
	);
}


/* --------- GODOT 4 FIX: texelFetch → texture w/ pixel coord ---------- */

vec3 sfetch(vec2 ipos){
	ivec2 size = textureSize(tex);
	vec2 uv = (ipos + 0.5) / vec2(size);
	return texture(tex, uv).rgb;
}


/* ------------------ SAMPLE FUNCTION ------------------ */

vec3 sample(vec2 uv){
	ivec2 size = textureSize(tex);

	uv *= vec2(size);

	int y = int(uv.y + 0.5) - 1;

	float x = floor(uv.x);
	float ax = x - 1.0;
	float dx = x + 1.0;

	// fetch using fixed integer coords
	vec3 upper_a = srgb_to_linear(sfetch(vec2(ax, y)));
	vec3 upper_b = srgb_to_linear(sfetch(vec2(x,  y)));
	vec3 upper_c = srgb_to_linear(sfetch(vec2(dx, y)));

	y += 1;

	vec3 lower_a = srgb_to_linear(sfetch(vec2(ax, y)));
	vec3 lower_b = srgb_to_linear(sfetch(vec2(x,  y)));
	vec3 lower_c = srgb_to_linear(sfetch(vec2(dx, y)));

	vec3 beam = vec3(uv.x - 0.5);
	beam.r -= color_offset;
	beam.b += color_offset;

	vec3 weight_a = smoothstep(1.0, 0.0, (beam - ax));
	vec3 weight_b = smoothstep(1.0, 0.0, abs(beam - x));
	vec3 weight_c = smoothstep(1.0, 0.0, (dx - beam));

	vec3 upper_col = (
		upper_a * weight_a +
		upper_b * weight_b +
		upper_c * weight_c
	);

	vec3 lower_col = (
		lower_a * weight_a +
		lower_b * weight_b +
		lower_c * weight_c
	);

	float sawtooth = (uv.y + 0.5) - float(y);
	sawtooth = smoothstep(0.0, 1.0, sawtooth);

	return mix(upper_col, lower_col, sawtooth);
}


/* ------------------ MASK GENERATION ------------------ */

vec4 generate_mask(vec2 fragcoord){
	switch (mask_type){
		case 1:
			const vec3 pattern1[] = {
				vec3(1,0,0), vec3(0,1,0),
				vec3(0,0,1), vec3(0,0,0)
			};
			ivec2 ic1 = ivec2(fragcoord);
			return vec4(pattern1[(ic1.y * 2 + ic1.x) % 4], 0.25);

		case 2:
			const vec3 pattern2[] = { vec3(0,1,0), vec3(1,0,1) };
			return vec4(pattern2[int(fragcoord.x) % 2], 0.5);

		case 3:
			const vec3 pattern3[] = {
				vec3(1,0,0), vec3(0,1,0),
				vec3(0,0,1), vec3(0,0,0)
			};
			return vec4(pattern3[int(fragcoord.x) % 4], 0.25);

		case 4:
			const vec3 pattern4[] = {
				vec3(1.0,0.125,0.0),
				vec3(0.125,1.0,0.125),
				vec3(0.0,0.125,1.0),
				vec3(0.125,0.0,0.125)
			};
			return vec4(pattern4[int(fragcoord.x) % 4], 0.3125);

		case 5:
			const vec3 pattern5[] = {
				vec3(1,0,1), vec3(0,1,0),
				vec3(1,0,1), vec3(0,1,0),
				vec3(0,0,1), vec3(0,1,0),
				vec3(1,0,0), vec3(0,0,0),
				vec3(1,0,1), vec3(0,1,0),
				vec3(1,0,1), vec3(0,1,0),
				vec3(1,0,0), vec3(0,0,0),
				vec3(0,0,1), vec3(0,1,0)
			};
			ivec2 ic5 = ivec2(fragcoord) % 4;
			return vec4(pattern5[ic5.y * 4 + ic5.x], 0.375);

		default:
			return vec4(0.5);
	}
}

vec3 apply_mask(vec3 col, vec2 fragcoord){
	vec4 mask = generate_mask(fragcoord);

	col *= mix(mask.w, 1.0, mask_brightness);

	vec3 target_color = col / mask.w;
	vec3 primary = clamp(target_color, 0.0, 1.0);

	vec3 secondary = (target_color - primary) / (1.0 / mask.w - 1.0);

	primary *= mask.rgb;
	primary += secondary * (1.0 - mask.rgb);

	return primary;
}


/* ------------------ FRAGMENT ------------------ */

void fragment(){
	vec2 warped = warp(UV, aspect, curve);

	vec3 col = sample(warped);

	col = apply_mask(col, FRAGCOORD.xy);

	col = linear_to_srgb(col);

	COLOR = vec4(col, 1.0);
}
