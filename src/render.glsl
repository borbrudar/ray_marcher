
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
