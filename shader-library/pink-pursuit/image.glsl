//Diatribes orb: https://www.shadertoy.com/view/N323DV
//Xor article: https://mini.gmshaders.com/p/design-choices

// Tonemapping (ACES Filmic Approximation)
// Reference: Academy Color Encoding System (ACES) 
// http://www.oscars.org/science-technology/sci-tech-projects/aces
// ShaderToy reference implementation: https://www.shadertoy.com/view/Xc3yzM
vec3 a(vec3 color) {	
    const mat3 M1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    const mat3 M2 = mat3(
        1.60475, -0.10208, -0.00327,
       -0.53108,  1.10813, -0.07276,
       -0.07367, -0.00605,  1.07602
    );
    vec3 v = M1 * color;    
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;   
    return M2 * (a / b); 
}

// Dot Noise (XorDev, cheap irrational-domain field)
// Reference: https://mini.gmshaders.com/p/phi
float n(vec3 p) {
    const float PHI = 1.618033988; // golden ratio
    const mat3 GOLD = mat3(
        -0.571464913, +0.814921382, +0.096597072,
        -0.278044873, -0.303026659, +0.911518454,
        +0.772087367, +0.494042493, +0.399753815
    );
    // Gyroid-like irrational rotations and scales
    return dot(cos(GOLD * p), sin(PHI * p * GOLD)); // [-3, +3]
}

//2d rotation matrix
mat2 r(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s,
                s,  c);
}

void mainImage(out vec4 o, in vec2 U) {
    float t = -iTime,s,i;

    vec2 R=iResolution.xy,uv=(2.*U.xy-R)/R.y;

    vec3 d = normalize(vec3(2.*U,0) - R.xyy),
    p,l;
    
    d.x=abs(d.x);
    d.xy*=r(d.z-.5);

    for (; i++< 150.;) {
        s = abs(n(p/8.+t)*8. - (p.y+20.)) * .2+ .009;

        p += d * s;
        l += sin(p.z * .05+4.5 - vec3(.1, .8, .9)) / 
             (s * .001 + 1e-6) 
             //Glowing orb/gradient inspired by Diatribes
             + .3 * vec3(9, 4, 8) / 
             (length(uv + vec2(2.5,.9)) 
              * (1e-4 * .2));
    }
    o =pow(a(l * l / 1e14), vec3(1./2.2)).rgbr;
}
