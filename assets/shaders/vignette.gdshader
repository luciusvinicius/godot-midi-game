shader_type canvas_item;

uniform float STRETCH = 0.8;
uniform float MULTIPLIER = 0.8;
uniform float MIN = 0.3;
uniform float MAX = 0.9;

void fragment(){
	float val = distance(vec2(UV.x , UV.y * STRETCH), vec2(0.5 , 0.5 * STRETCH));
	val = val / MULTIPLIER;
	float vignette = smoothstep(MIN, MAX, val);
	
	COLOR = vec4(COLOR.rgb , vignette);
}