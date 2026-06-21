float angleMix(float a,float b,float v){
    return clamp((v-a)/max(b-a,.0001),0.,1.);
}

float sideFade(float xNorm,float fadeLeft,float fadeRight){
    float leftMask=fadeLeft>0.?smoothstep(-fadeLeft,0.,xNorm):1.;
    float rightMask=fadeRight>0.?1.-smoothstep(0.,fadeRight,xNorm):1.;
    return leftMask*rightMask;
}

vec3 radialColor(vec2 uv){
    float angleDeg=mod(degrees(atan(uv.y,uv.x))+0.0+360.,360.);
    
    float p1=mod(0.0+360.,360.);
    float p2=mod(82.+360.,360.);
    float p3=mod(258.9+360.,360.);
    float p4=mod(360.+360.,360.);
    if(p2<=p1)p2+=360.;
    if(p3<=p2)p3+=360.;
    if(p4<=p3)p4+=360.;
    if(angleDeg<p1)angleDeg+=360.;
    
    vec3 color;
    if(angleDeg<p2){
        color=mix(vec3(0.68, 0.97, 0.97),vec3(0.04, 0.76, 0.81),angleMix(p1,p2,angleDeg));
    }else if(angleDeg<p3){
        color=mix(vec3(0.04, 0.76, 0.81),vec3(0.01, 0.05, 0.1),angleMix(p2,p3,angleDeg));
    }else if(angleDeg<p4){
        color=mix(vec3(0.01, 0.05, 0.1),vec3(0, 0, 0),angleMix(p3,p4,angleDeg));
    }else{
        color=mix(vec3(0, 0, 0),vec3(0.68, 0.97, 0.97),angleMix(p4,p1+360.,angleDeg));
    }
    return color;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
    vec2 center1=iResolution.xy*vec2(0.28, 0.5);
    vec2 center2=iResolution.xy*vec2(0.72, 0.5);
    vec2 uv1=fragCoord.xy-center1;
    vec2 uv2=fragCoord.xy-center2;
    vec3 colorA=radialColor(uv1);
    vec3 colorB=radialColor(vec2(-uv2.x,uv2.y));
    float fadeA=sideFade(uv1.x/iResolution.x,0.,0.51);
    float fadeB=sideFade(uv2.x/iResolution.x,0.51,0.);
    float alphaA=1.*fadeA;
    float alphaB=1.*fadeB;
    vec4 layerA=vec4(colorA*alphaA,alphaA);
    vec4 layerB=vec4(colorB*alphaB,alphaB);
    vec3 rgb=layerB.rgb+layerA.rgb*(1.-layerB.a);
    float outAlpha=layerB.a+layerA.a*(1.-layerB.a);
    fragColor=vec4(rgb,outAlpha);
}