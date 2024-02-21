#version 330 core

uniform vec2 u_resolution;
in vec2 fragCoord;
out vec4 fragColor;

const float EPSILON = 0.001;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;

vec2 map(vec3 p){
    p = mod(p,4.0) - 4.0 * 0.5;
    //sphere
    float sphereDist = length(p) - 1.0;
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist,sphereID);
    //result
    vec2 res = sphere;
    return res;
}

vec2 rayMarch(vec3 ro, vec3 rd){
    vec2 hit,object;
    for(int i = 0;i < MAX_STEPS;i++){
        vec3 p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.y = hit.y;
        if(abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
    }
    return object;
}


void render(inout vec3 col, in vec2 uv){
    vec3 ray_origin = vec3(0.0,0.0,-3.0);
    vec3 ray_dir = normalize(vec3(uv,FOV));

    vec2 object = rayMarch(ray_origin,ray_dir);
    if(object.x < MAX_DIST){
        col += 3.0/ object.x;
    }
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;
    //vec2 uv = gl_FragCoord.xy/vec2(800.0,600.0);
    //vec2 uv = gl_FragCoord.xy/u_resolution;
    vec3 col;
    render(col,uv);

    //render(col,u_resolution);
    fragColor = vec4(col, 1.0);
}