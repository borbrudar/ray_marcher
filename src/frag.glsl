#version 330 core
//#include hg_sdf.glsl

uniform vec2 u_resolution;
in vec2 fragCoord;
out vec4 fragColor;

const float EPSILON = 0.001;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;


float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
	return dot(p, n) + distanceFromOrigin;
}

vec2 fOpUnionID(vec2 res1,vec2 res2){
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 map(vec3 p){
    //plane
    float planeDist= fPlane(p,vec3(0.0,1.0,0.0),1.0);
    //float planeDist= 2;
    float planeID = 2.0;
    vec2 plane = vec2(planeDist,planeID);
    //sphere
    //p = mod(p,4.0) - 4.0 * 0.5; // infinite repetition
    float sphereDist = length(p) - 1.0;
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist,sphereID);

    //result
    vec2 res = fOpUnionID(sphere,plane);
    //vec2 res = sphere;
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

vec3 getNormal(vec3 p){
    vec2 e = vec2(EPSILON,0.0);
    vec3 n = vec3(map(p).x) - vec3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x);
    return normalize(n);
}

vec3 getLight(vec3 p, vec3 rd,vec3 color){
    vec3 lightPos = vec3(20.0,40.0,-30.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);

    vec3 diffuse = color * clamp(dot(L,N),0.0,1.0);
    return diffuse;
}

void render(inout vec3 col, in vec2 uv){
    vec3 ro = vec3(0.0,0.0,-3.0);
    vec3 rd = normalize(vec3(uv,FOV));

    vec2 object = rayMarch(ro,rd);

    if(object.x < MAX_DIST){
        vec3 p = ro + object.x * rd;
        col += getLight(p,rd,vec3(1));
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