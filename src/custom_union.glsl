vec2 fOpUnionID(vec2 res1,vec2 res2){
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1,vec2 res2){
    return (res1.x > -res2.x) ? res1 : vec2(-res2.x,res2.y);
}

vec2 fOpDifferenceColumnsID(vec2 res1,vec2 res2,float r,float n){
    float dist = fOpDifferenceColumns(res1.x,res2.x,r,n);
    return (res1.x > -res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}

vec2 fOpUnionStairsID(vec2 res1,vec2 res2,float r,float n){
    float dist = fOpUnionStairs(res1.x,res2.x,r,n);
    return (res1.x < res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}

vec2 fOpUnionChamferID(vec2 res1,vec2 res2,float r){
    float dist = fOpUnionChamfer(res1.x,res2.x,r);
    return (res1.x < res2.x) ? vec2(dist,res1.y) : vec2(dist,res2.y);
}