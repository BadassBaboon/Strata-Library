// https://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

// feature
bool eyelid;
bool iris;
bool pupil;
#define pi 3.141592653589793

// 2D heightmap with input theta: angle around the helix-arm and psi: angle around y-axle
float radial_offset( in float theta, in float psi )
{
    float eye_ridge = 0.7 + 0.1*sin(iTime);
    float eye_crater = 0.6 + 0.1*sin(iTime);
    float eye_pupil = 0.7;
    
    float x = theta+psi+iTime/10.0;
    float y = psi;
    
    float height = (pow(sin(10.0*x), 2.0) + pow(sin(23.0*y), 2.0))/2.0;
    
    if (height > eye_ridge)
    {
        eyelid = true;
        height = 2.0*eye_ridge - height;
        
        if (height < eye_crater)
        {
            iris = true;
            height = 2.0*eye_crater - height;
            
            if ( height > eye_pupil ) pupil = true;
        }
    }
    else {
        // simple roughness
        height += 0.0025*(sin(100.0*x) + sin(300.0*y));
        height += 0.0012*(sin(232.0*x+123.0) + sin(600.0*y+789.0));
    }
    
    return (1.0 - clamp(height, 0.1, 1.0));
}

// adapted from https://www.shadertoy.com/view/ttB3DV
float helix_sdf( in vec3 pos, in float rad, in float vert )
{
    // horizontal distance
    float h = length(pos.xz) - rad;
    
    // vertical distance from spiral
    float t = pos.y / vert * 2.0 * pi;
    float v = vert * asin(sin(t + 0.5*atan(pos.x, pos.z))) / 2.0 / pi;
    
    // distance = distance from arm with thickness given by constant + offset map
    return sqrt(h*h + v*v) - 9.0 + radial_offset( atan(v, h), atan(pos.x, pos.z));
}

// [a, b] -> [0, 1], with clamping.
float lerp( in float x, in float a, in float b )
{
    return (clamp(x, a, b) - a)/(b-a);
}

// https://iquilezles.org/articles/fog/
vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    float fogAmount = 1.0 - exp( -distance*0.005 );
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   float ratio = iResolution.y / iResolution.x;
   vec2 uv = (fragCoord / iResolution.xy - vec2(0.5, 0.5)) * vec2(1.0, ratio);
   
   // setup ray
   vec3 o = vec3(0.0,0.0,-0.5);
   vec3 d = normalize(vec3(uv, 0.0) - o);
   o = vec3(uv,0.0);
   
   // rotate camera
   float xtilt = -0.4;
   
   mat4 xrot = rotationMatrix(vec3(1.0,0.0,0.0), xtilt);
   o = (xrot * vec4(o,1.0)).xyz;
   d = (xrot * vec4(d,1.0)).xyz;
   
   // translate camera
   
   o += vec3(-7.0,-0.0,-25.0);
   
   // helix settings
   
   float coil = 60.0;
   float rad = 20.0;
   
   // raymarch https://iquilezles.org/articles/raymarchingdf/
   float dist = 0.0;
   bool hit = false;
   float h;
   int i = 0;
   
   for(; i < 100 && dist < 100.0; i++)
   {
       // reset features
       eyelid = false;
       iris = false;
       pupil = false;
       
       h = helix_sdf(o,rad,coil);
       if (h < 0.001)
       {
           hit = true;
           break;
       }
       
       dist += 0.9*h;
       o += 0.9*h*d;
   }
   
   
   if (hit) 
   {
       // approximate surface normal
       float dDdx = (helix_sdf(o + vec3(0.001, 0.0, 0.0), rad, coil) - h)/0.001;
       float dDdy = (helix_sdf(o + vec3(0.0, 0.001, 0.0), rad, coil) - h)/0.001;
       vec3 n = normalize(vec3(dDdx, dDdy, 1));
       
       // primary smooth-shading 
       float normal = dot(n, normalize(vec3(-1.0, 0.6, 0.5)));
       float shader = lerp(clamp(normal, 0.0, 1.0), -0.02, 2.0);
       
       // highlight
       vec3 highlight = 1.0 * smoothstep(0.47, 0.5, shader) * vec3(0.396, 0.718, 0.996);
       
       // AmBient Occlusion
       float abo = exp(-float(i)*0.05);
       
       // left arm-highlight
       float left_highlight = 3.0*smoothstep(0.5, 1.0, dot(n, normalize(vec3(-0.4, 1.0, 0.0)))); // direction + amp
       left_highlight *= smoothstep(0.3, 1.0, dot(normalize(o.xz), vec2(-1.0, -0.0))); // sector bias/filter
       left_highlight = 1.2*lerp(left_highlight, 0.0, 1.0); // compress and amplify
       vec3 lh = left_highlight * vec3(0.667, 0.875, 0.969);
       
       // underside glow
       vec3 light_source = vec3(0.0, -40.0, 30.0);
       float height = 1.0 - lerp(o.y, -40.0, -20.0); // height bias/filter
       float lightcomp = dot(n, normalize(light_source - o)); // light direction
       vec3 light = 5.0 * height * lerp(lightcomp, 0.0, 1.0) * vec3(0.8,0.75,1.0);
       
       // material color
       vec3 base_color = 0.5 * vec3(0.8,0.8,1.0);
       if (pupil)
       {
           base_color = vec3(-1.0,-1.0,-1.0); // make them really dark
       }
       else if (iris)
       {
           base_color = vec3(2.0, 2.0, 2.0); // have them pop out
       }
       else if (eyelid)
       {
           base_color = vec3(0.8, 0.1, 0.1);
       }
       
       
       base_color = lh + highlight + abo * 0.5*shader * base_color + light;
       fragColor = vec4(applyFog(base_color, dist), 1.0);
   } 
   else 
   {
       fragColor = vec4(vec3(0.0), 1.0);
   
   }
}