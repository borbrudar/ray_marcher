#version 450 core

uniform vec2 u_resolution;
//uniform vec2 u_mouse;
//uniform float u_time;


in vec2 fragCoord;
out vec4 fragColor;

#include src/hg_sdf.glsl
#include src/material.glsl

#include src/light.glsl
#include src/ray_march.glsl // moot dependency, just for testing

#include src/render.glsl


vec2 getUV(vec2 offset){
    return (2.0 * (gl_FragCoord.xy + offset) - u_resolution.xy) / u_resolution.y;
}

//anti-aliasing
vec3 renderAAx4(){
    vec4 e = vec4(0.125,-0.125,0.375,-0.375);
    vec3 colAA = render(getUV(e.xz)) + render(getUV(e.yw)) +
    render(getUV(e.wx)) + render(getUV(e.zy));
    return colAA/=4.0;
}

void main() {
    //vec3 col = renderAAx4(); //anti-aliasing
    vec3 col = render(getUV(vec2(0.0,0.0)));

    //gamma correction
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}