/*
	Toon Shader by Firerabbit
	Godot 4.5 conversion

	MIT License
*/

shader_type spatial;
render_mode unshaded, ambient_light_disabled;

uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D tex : source_color, hint_default_white;

uniform float shadow : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_width : hint_range(0.001, 0.5) = 0.0;
uniform vec4 shadow_color : source_color = vec4(0.705);

uniform float specular_smoothness : hint_range(0.0, 0.5) = 0.01;
uniform float specular_strength : hint_range(0.0, 0.25) = 0.075;
uniform float glossiness : hint_range(0.001, 0.5) = 0.1;

uniform float rim_size : hint_range(0.0, 1.0) = 0.5;
uniform float rim_smoothness : hint_range(0.0, 0.5) = 0.01;

void fragment() {
	vec3 tex_color = texture(tex, UV).rgb;
	ALBEDO = pow(tex_color, vec3(2.2)) * color.rgb;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	NdotL = smoothstep(shadow - shadow_width, shadow + shadow_width, NdotL);

	/* Specular */
	vec3 H = normalize(VIEW + LIGHT);
	float NdotH = max(0.0, dot(NORMAL, H));
	float specular_intensity = pow(NdotH, 1.0 / glossiness);
	vec3 specular = vec3(
		smoothstep(
			0.5 - specular_smoothness,
			0.5 + specular_smoothness,
			specular_intensity
		)
	);

	/* Rim */
	float rimDot = 1.0 - dot(VIEW, NORMAL);
	float rim_intensity = rimDot * NdotL;
	vec3 rim = vec3(
		smoothstep(
			1.0 - rim_size - rim_smoothness,
			1.0 - rim_size + rim_smoothness,
			rim_intensity
		)
	);

	DIFFUSE_LIGHT =
		mix(
			ALBEDO * shadow_color.rgb,
			(ALBEDO + (rim + specular) * specular_strength)
				* LIGHT_COLOR.rgb * 0.33,
			NdotL + 0.33 * smoothstep(
				1.0 - rim_size - rim_smoothness,
				1.0 - rim_size + rim_smoothness,
				rimDot
			)
		);
}
