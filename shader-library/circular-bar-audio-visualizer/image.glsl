#define pi 3.14159265359
#define rot(a) mat2( cos(a),-sin(a),sin(a),cos(a) )

//Inspired by this random gif I saw in someone's steam workshop icon
//https://steamuserimages-a.akamaihd.net/ugc/1774952891092106678/2D0BC0B276D7C72CA57E2ED2BAA2A55652BD9F0F/

//Mouse click mirrors, mouse x controls smoothing, mouse y controls wobble.


//Song
//https://soundcloud.com/surrealrecordings/babokon-laces
//https://soundcloud.com/insan3lik3/hai

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iTime;
    vec2 R = iResolution.xy;
    vec2 uv = (fragCoord-.5*R.xy)/R.y;
    vec2 mXY=(iMouse.xy)/iResolution.y; 
    float r = length(uv);
    
    if(iMouse.z == 0.0){
    mXY = vec2(0.5,0.5);
    }
    
    //uv*=rot(iTime*0.3); //SPIIN
    
    //wavey
    uv*=rot(3.0*mXY.y*0.03*sin(t+18.0*(1.0-length(uv))));
    
    //converting to polar coordinates 0<->360 -> 0<->1.0
    //If you know a more elegant way to do this let me know
    
    /*
    float th = atan(uv.y/uv.x);
    th += pi*step(0.0,-uv.x)+2.0*pi*step(0.0,-uv.y)*step(0.0,uv.x);
    th /= 2.0*pi;
    */
   
    //I found a more elegant way :D
    float th = atan(-uv.y,-uv.x)/(2.0*pi)+0.5;
    
    
    float c = 120.0; //bar count (looks pretty cool with low bar counts as well)
    
    //c += floor(30.0*pow(sin(t*0.25),2.0)); //bar count changing
    
    if(iMouse.z>0.0){
    th = fract(th*(2.0));
    }
    
    
    float thID = floor(th*c)/c;
    th = fract(th*c);
    
    float w = (0.12/100.0)*c; //bar gap (try using 0.0)
    float st = 0.15; //center circle size
    
    float aa = c/R.y*step(0.01,w);
    float aa2 = (0.005)*450.0/R.y;

    //averaging the sound sample from the range of each bar(s) so it's smoother
    float afft = 0.0;
    float lps = 0.0;
    for(int i=int((thID-((1.0+mXY.x*2.0-1.0)/c))*512.0); i<int((thID+(1.0/c))*512.0); i++){
        afft+=texelFetch( iChannel0, ivec2(clamp(float(i),0.0,512.0),0), 0 ).x;
        lps++;
    }
    afft/=lps;
    
    float sen = 2.9; //log scale adjustment
    float end = (log(0.001+afft*sen)+st)/(log(sen)*2.0);
    end = (end+afft*0.6)/2.0;
    //end = clamp(end,0.0,0.50);
    
    vec3 col1 = vec3(256.0,66.0,66.0)/256.0;
    vec3 col2 = vec3(66.0,66.0,245.0)/256.0;
    vec3 col3 = mix(col1,col2,r*2.6);
    float li1 = smoothstep(w-aa,w,th)-smoothstep(1.0-w-aa,1.0-w,th);
    float li2 = smoothstep(st-aa2,st,r)-smoothstep(end-aa2,end,r);
    float o = min(li1,li2);
    col3*= o;
    col3 += (1.0-o)*mix(vec3(0),vec3(32.0,4.0,64.0)/256.0,length(uv));
    
    fragColor = vec4(col3,1.0);
}