#version 450 core
//#include hg_sdf.glsl

uniform vec2 u_resolution;
uniform vec2 u_mouse;
//uniform float u_time;

in vec2 fragCoord;
out vec4 fragColor;

const float EPSILON = 0.001;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;


void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

/*
float fDisplace(vec3 p){
    pR(p.yx,sin(2.0*u_time));
    return (sin(p.x+4.0*u_time)*sin(p.y+sin(2.0*u_time))*sin(p.z+6.0*u_time));
}
*/

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

float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2 * s)) - s)));
}

vec2 fOpUnionStairsID(vec2 res1,vec2 res2,float r,float n){
    float dist = fOpUnionStairs(res1.x,res2.x,r,n);
    return (res1.x < res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}

float fOpUnionChamfer(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

vec2 fOpUnionChamferID(vec2 res1,vec2 res2,float r){
    float dist = fOpUnionChamfer(res1.x,res2.x,r);
    return (res1.x < res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}


float sgn(float x) {
	return (x<0)?-1.0:1.0;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0)?-1:1, (v.y<0)?-1:1);
}

float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

float fSphere(vec3 p, float r) {
	return length(p) - r;
}

vec2 map(vec3 p){
    //plane
    float planeDist= fPlane(p,vec3(0.0,1.0,0.0),10.0);
    //float planeDist= 2;
    float planeID = 2.0;
    vec2 plane = vec2(planeDist,planeID);
    //sphere
    //p = mod(p,4.0) - 4.0 * 0.5; // infinite repetition
    //float sphereDist = fSphere(p,9.0+fDisplace(p));
    //float sphereID = 1.0;
    //vec2 sphere = vec2(sphereDist,sphereID);
    
    // red cube
    float cdist = fBox(p,vec3(6.0));
    float cid = 1.0;
    vec2 b = vec2(cdist,cid);
    
    //manipulation ops
    pMirrorOctant(p.xz,vec2(50,50));
    p.x = -abs(p.x) + 20;
    pMod1(p.z,15);

    //roof
    vec3 pr = p;
    pr.y-=15.5;
    pR(pr.xy,0.6);
    pr.x-=18;
    float roofDist = fBox2(pr.xy,vec2(20,0.3));
    float roofID = 4.0;
    vec2 roof = vec2(roofDist,roofID);

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
    res = fOpUnionStairsID(res,plane,4.0,5.0);
    res = fOpUnionChamferID(res,roof,0.9);
    res = fOpUnionID(res,b);
    //res=plane;
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

float getSoftShadow(vec3 p, vec3 lightPos){
    float res = 1.0;
    float dist = 0.01;
    float lightSize = 0.1;
    for(int i = 0; i < MAX_STEPS; i++){
        float hit = map(p + lightPos * dist).x;
        res = min(res, hit/ (dist*lightSize));
        dist += hit;
        if(hit < 0.0001 || dist > 60.0) break;
    }
    return clamp(res,0.0,1.0);
}

float getAmbientOcclusion(vec3 p,vec3 normal){
    float occ = 0.0;
    float weight = 1.0;
    for(int i =0;i < 8;i++){
        float len = 0.01 + 0.02 * float(i*i);
        float dist = map(p + normal*len).x;
        occ += (len-dist)*weight;
        weight *= 0.85;
    }

    return 1.0 - clamp(0.6 * occ,0.0,1.0);
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
    vec3 fresnel = 0.25 * color * pow(1.0 + dot(rd,N),3.0);

    //shadows 
    float shadow= getSoftShadow(p + N*0.02, normalize(lightPos)).x;
    // occ
    float occ = getAmbientOcclusion(p,N);
    vec3 back = 0.05 * color * clamp(dot(N,-L),0.0,1.0);
    return (back+fresnel + ambient)*occ + (specular*occ + diffuse)*shadow;
}

vec3 getMaterial(vec3 p, float id){
    vec3 m;
    switch(int(id)){
        case 1: 
        m = vec3(0.9,0.0,0.0); break;
        case 2: 
        m = vec3(0.2 + 0.4 *mod(floor(p.x) + floor(p.z),2.0));  break;
        case 3:
        m = vec3(0.7,0.8,0.9);break;
        case 4:
        vec2 i = step(fract(0.5*p.xz),vec2(1.0/10.0));
        m=((1.0-i.x)*(1.0-i.y))*vec3(0.37,0.12,0.0);
        break;
        default:
        m = vec3(0.4);break;
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

vec3 renderAAx4(){
    vec4 e = vec4(0.125,-0.125,0.375,-0.375);
    vec3 colAA = render(getUV(e.xz)) + render(getUV(e.yw)) +
    render(getUV(e.wx)) + render(getUV(e.zy));
    return colAA/=4.0;
}

void main() {
    //vec2 uv = gl_FragCoord.xy/vec2(800.0,600.0);
    //vec2 uv = gl_FragCoord.xy/u_resolution;
    //vec3 col = renderAAx4(); //anti-aliasing
    vec3 col = render(getUV(vec2(0.0,0.0)));

    //render(col,u_resolution);
    //gamma correction
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}