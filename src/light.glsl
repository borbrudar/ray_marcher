#include src/ray_march.glsl

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
