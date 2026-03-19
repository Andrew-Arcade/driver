shader_type canvas_item;

uniform vec4 wave_color : source_color = vec4(1.0);

uniform float speed = 2.0;
uniform float frequency = 6.0;
uniform float width = 0.05;
uniform float fade = 0.7;

uniform vec2 center = vec2(0.5, 0.5);


uniform float sine_scale = 10.0;
uniform float sine_speed = 1.0;
uniform float sine_strength = 0.04;


uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float noise_scale = 2.0;
uniform float noise_strength = 0.015;


uniform float noise_speed = 0.05;

void fragment() {
    vec2 centered_uv = UV - center;

    float dist = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);

    float sine_distortion =
        sin(angle * sine_scale + TIME * sine_speed) +
        0.5 * sin(angle * sine_scale * 2.3 - TIME * sine_speed * 1.7);

    vec2 polar_uv = vec2(
        angle / 6.2831853,
        dist
    );

    polar_uv += vec2(0.0, TIME * noise_speed);

    float noise = texture(noise_tex, polar_uv * noise_scale).r;

    noise = noise * 2.0 - 1.0;

     float distortion =
        sine_distortion * sine_strength +
        noise * noise_strength;

    dist += distortion;

    float wave = fract(dist * frequency - TIME * speed);

    float ring = smoothstep(0.0, width, wave) *
                 (1.0 - smoothstep(width, width * 2.0, wave));

   float max_dist = length(max(center, 1.0 - center));
    float edge_fade = smoothstep(max_dist, max_dist * fade, dist);

    float alpha = ring * edge_fade;

    COLOR = vec4(wave_color.rgb, alpha);
}