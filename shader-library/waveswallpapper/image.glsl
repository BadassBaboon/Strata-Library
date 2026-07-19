/*
float dist(vec2 p, float num, float dy){
    const float amp[6] = float[](1.,1.,1.,1.,1.,1.);
    
    float d = num*dy+sin((p.x-iTime))*amp[int(num)];
    return d;
}
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )

{

    vec2 uv = (fragCoord/iResolution.x);

    uv*=20.;
    uv+=1.5;
    float a = 3.1415/4.;
    uv*= mat2(cos(a), -sin(a), sin(a), cos(a));

    float dy = 20./4.5;
    
    vec3 col;  

    const vec3 mas[6] = vec3[](

    vec3(1.0, 1.0, 1.0), 

    vec3(0.9, 0.95, 1.0), 
    
    vec3(0.75, 0.9, 1.0),

    vec3(0.55, 0.8, 1.0),

    vec3(0.35, 0.7, 1.0),

    vec3(0.15, 0.6, 1.0)

);

    
    for(float num = 0.; num<6.; num++){

        float y1 = num*dy+sin((uv.x-iTime));
        float y2 = (num+1.)*dy+sin((uv.x-iTime));
        
        float c = step(y1,uv.y)*step(uv.y,y2);
 

        col += vec3(mas[int(num)]*c);

    }

    
    fragColor = vec4(col,1.0);

}