#version 330 core

uniform vec2 u_resolution;
in vec2 fragCoord;
out vec4 fragColor;


void main()
{
    //vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;
    vec2 uv = fragCoord/u_resolution.xy;
    vec3 col = vec3(uv,0.0);
    //render(col,u_resolution);
    fragColor = vec4(col, 1.0);
}