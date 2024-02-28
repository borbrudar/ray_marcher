//#include src/custom_union.glsl -- error, words

const float EPSILON = 0.001;
const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;

vec2 map(vec3 p){
    //plane
    float planeDist= fPlane(p,vec3(0.0,1.0,0.0),10.0);
    //float planeDist= 2;
    float planeID = 2.0;
    vec2 plane = vec2(planeDist,planeID);
    //sphere
    //p = mod(p,4.0) - 4.0 * 0.5; // infinite repetition
    //float sphereDist = fSphere(p,1.0); //fSphere(p,9.0+fDisplace(p));
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
    //res=sphere;
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