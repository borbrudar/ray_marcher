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

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

vec2 fOpUnionID(vec2 res1,vec2 res2){
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1,vec2 res2){
    return (res1.x > -res2.x) ? res1 : vec2(-res2.x,res2.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float vmax(vec2 v) {
	return max(v.x, v.y);
}

float fBox2(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/n/2.0;
		columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2)/2*r;
		p.x += -columnradius*sqrt(2)/2;

		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

vec2 fOpDifferenceColumnsID(vec2 res1,vec2 res2,float r,float n){
    float dist = fOpDifferenceColumns(res1.x,res2.x,r,n);
    return (res1.x > -res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}


vec2 map(vec3 p){
    //plane
    float planeDist= fPlane(p,vec3(0.0,1.0,0.0),10.0);
    //float planeDist= 2;
    float planeID = 2.0;
    vec2 plane = vec2(planeDist,planeID);
    //sphere
    //p = mod(p,4.0) - 4.0 * 0.5; // infinite repetition
    float sphereDist = length(p) - 1.0;
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist,sphereID);

    //float box
    float boxDist = fBox(p, vec3(3,9,4));
    float boxID = 3.0;
    vec2 box = vec2(boxDist,boxID);

    //cylinder
    vec3 pc = p;
    pc.y -= 9.0;
    float cylinderDist = fCylinder(pc.yxz,4,3);
    float cylinderID = 3.0;
    vec2 cylinder = vec2(cylinderDist, cylinderID);

    //wall
    float wallDist = fBox2(p.xy, vec2(1,15));
    float wallID = 3.0;
    vec2 wall = vec2(wallDist,wallID);


    //result
    vec2 res;
    res = box;
    res = fOpUnionID(res,cylinder);
    res = fOpDifferenceColumnsID(wall,res,0.6,3.0);
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
        case 3:
        m = vec3(0.7,0.8,0.9);break;
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
    vec3 ro = vec3(10.0,10.0,-3.0);
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