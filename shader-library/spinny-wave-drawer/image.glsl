#define TAU 6.283185307179586
#define PI 3.141592653589793
#define RPS 0.1
#define SEGMENTS 10.0
#define RADIUS 1.0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 rotationCenter = iResolution.xy / 2.0;
    vec2 centeredCoord = fragCoord - rotationCenter;
    float distanceFromCenter = length(centeredCoord);
    float distanceTimeValue = (iTime - distanceFromCenter*0.01);
    float rpsX = -TAU*RPS*sin(distanceTimeValue)*10.0;
    vec2 rotationVector = vec2(cos(rpsX), sin(rpsX));
    float cosAngle = dot(rotationVector, centeredCoord) / distanceFromCenter;
    float side = dot(rotationVector, vec2(-centeredCoord[1], centeredCoord[0]));
    float angle = acos(cosAngle);
    float val = angle/TAU;
    if (side > 0.0) {
        val = 1.0 - val;
    }
    float colorVal = sin(SEGMENTS*PI*val);
    fragColor = vec4(0.1 + val*0.7, 0.3 + val*0.7, (0.5 + 0.5*val), 1.0);
}