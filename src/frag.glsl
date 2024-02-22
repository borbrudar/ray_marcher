#version 330 core
//#include hg_sdf.glsl

uniform vec2 u_resolution;
uniform vec2 u_mouse;

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
    vec3 V = -rd;
    vec3 R = reflect(-L,N);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R,V), 0.0,1.0),10.0);
    vec3 diffuse = color * clamp(dot(L,N),0.0,1.0);
    vec3 ambient = color * 0.05;

    //shadows 
    float d = rayMarch(p + N*0.02, normalize(lightPos)).x;
    if(d < length(lightPos-p)) return vec3(0.0);

    return diffuse + ambient + specular;
}

vec3 getMaterial(vec3 p, float id){
    vec3 m;
    switch(int(id)){
        case 1: 
        m = vec3(0.9,0.0,0.0); break;
        case 2: 
        m = vec3(0.2 + 0.4 *mod(floor(p.x) + floor(p.z),2.0)); 
        break;
    }
    return m;
}

mat3 getCam(vec3 ro,vec3 lookAt){
    vec3 camF = normalize(vec3(lookAt-ro));
    vec3 camR = normalize(cross(camF,vec3(0.0,1.0,0.0)));
    vec3 camU = cross(camR,camF);
    return mat3(camR,camU,camF);
}

#define PI 3.14159265
#define TAU (2*PI)

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

void mouseControl(inout vec3 ro){
    vec2 m = u_mouse / u_resolution;
    pR(ro.yz,m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}

void render(inout vec3 col, in vec2 uv){
    vec3 ro = vec3(3.0,3.0,-3.0);
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
        col = mix(col,background,1.0 - exp(-0.0008 * object.x * object.x));
    }else{
        col += background - max(0.95 * rd.y, 0.0);
    }
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;
    //vec2 uv = gl_FragCoord.xy/vec2(800.0,600.0);
    //vec2 uv = gl_FragCoord.xy/u_resolution;
    vec3 col;
    render(col,uv);

    //render(col,u_resolution);
    //gamma correction
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}