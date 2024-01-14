shader_type canvas_item;
render_mode unshaded;

uniform float NOISE_TILE : hint_range(0.0, 5.0) = 3.0;
uniform float SMOOTH : hint_range(0.0, 1.0) = 0.6;
uniform float MIN : hint_range(0.0, 1.0) = 0.6;
uniform float MAX : hint_range(0.0, 1.0) = 0.6;
uniform float STRETCH : hint_range(0.0, 2.0) = 0.6;
uniform float MULTIPLIER : hint_range(0.0, 1.0) = 0.1;
uniform sampler2D mask: repeat_enable;

void fragment()
{
	vec2 testVec = vec2(NOISE_TILE, NOISE_TILE);
	float mask_value = texture(mask, UV * testVec).r;
	
	float dist = distance(vec2(UV.x , UV.y * STRETCH), vec2(0.5 , 0.5 * STRETCH));
	dist = dist / MULTIPLIER;
	float vignette = smoothstep((dist+MIN), (dist-MAX), mask_value * (1.0 - SMOOTH) + SMOOTH);
	
	COLOR = vec4(COLOR.rgb , vignette);
}