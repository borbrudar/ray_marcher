#version 450 core

uniform vec2 u_resolution;
uniform vec2 u_mouse;
//uniform float u_time;

in vec2 fragCoord;
out vec4 fragColor;


#include src/hg_sdf.glsl
#include src/material.glsl

#include src/custom_union.glsl
#include src/ray_march.glsl
// light relies on the map function, so we cant put it before it
#include src/light.glsl


mat3 getCam(vec3 ro,vec3 lookAt){
    vec3 camF = normalize(vec3(lookAt-ro));
    vec3 camR = normalize(cross(camF,vec3(0.0,1.0,0.0)));
    vec3 camU = cross(camR,camF);
    return mat3(camR,camU,camF);
}

void mouseControl(inout vec3 ro){
    vec2 m = u_mouse / u_resolution;
    pR(ro.yz,m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}

vec3 render(in vec2 uv){
    vec3 col;
    vec3 ro = vec3(30.0,30.0,-3.0);
    mouseControl(ro);
    vec3 lookAt = vec3(0,0,0);
    //vec3 rd = normalize(vec3(uv,FOV));
    vec3 rd = getCam(ro,lookAt) * normalize(vec3(uv,FOV));

    vec2 object = rayMarch(ro,rd);

    vec3 background = vec3(0.5,0.8,0.9);

    if(object.x < MAX_DIST){
        vec3 p = ro + object.x * rd;
        vec3 material = getMaterial(p,object.y);
        col += getLight(p,rd,material);

        //fog
        col = mix(col,background,1.0 - exp(-0.00008 * object.x * object.x));
    }else{
        col += background - max(0.95 * rd.y, 0.0);
    }
    return col;
}

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