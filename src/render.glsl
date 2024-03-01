
uniform vec3 cam_pos;
uniform vec3 cam_target;
uniform vec3 cam_up;


mat3 lookAt(vec3 pos,vec3 target, vec3 up){
    vec3 camF = normalize(vec3(target-pos));
    vec3 camR = normalize(cross(camF,up));
    vec3 camU = cross(camR,camF);
    return mat3(camR,camU,camF);
}

/*
void mouseControl(vec3 ro){
    vec2 m = u_mouse / u_resolution;
    pR(ro.yz,m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}
*/


vec3 render(in vec2 uv){
    vec3 col;
    //vec3 ro = vec3(30.0,30.0,-3.0);
    //mouseControl(cam_pos);
    //vec3 lookAt = vec3(0,0,0);
    //vec3 rd = normalize(vec3(uv,FOV));
    //vec3 rd = getCam(ro,lookAt) * normalize(vec3(uv,FOV));
    vec3 rd = lookAt(cam_pos,cam_pos + cam_target,cam_up) * normalize(vec3(uv,FOV));

    vec2 object = rayMarch(cam_pos,rd);

    vec3 background = vec3(0.5,0.8,0.9);

    if(object.x < MAX_DIST){
        vec3 p = cam_pos + object.x * rd;
        vec3 material = getMaterial(p,object.y);
        col += getLight(p,rd,material);

        //fog
        col = mix(col,background,1.0 - exp(-0.00008 * object.x * object.x));
    }else{
        col += background - max(0.95 * rd.y, 0.0);
    }
    return col;
}
