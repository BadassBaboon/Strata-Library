float opUnion(float a, float b) { return min(a, b); }
float opSubtract(float a, float b) { return max(-b, a); }

float sceneDistance(vec3 point) {
    float outer = cylinderDistance(point, vec3(0.0, 0.0, -0.15), vec3(0.0, 0.0, 0.15), 1.0);
    float inner = cylinderDistance(point, vec3(0.0, 0.0, -0.2), vec3(0.0, 0.0, 0.2), 0.8);
    
    float mesa = boxDistance(point - vec3(0.13, -0.255, 0.0), vec3(0.40, 0.3, 0.15));
    float ground = boxDistance(point - vec3(0.0, -0.6, 0.0), vec3(0.735, 0.08, 0.15));
    float groundBaseA = boxDistance(point - vec3(0.0, -0.72, 0.0), vec3(0.574, 0.1, 0.15));
    float groundBaseB = boxDistance(point - vec3(0.0, -0.82, 0.0), vec3(0.38, 0.1, 0.15));
    
    float groundBase = opUnion(groundBaseA, groundBaseB);
    
    mat4 slantRotation = rotateZ(-0.9110619);
    vec3 rotatedPoint = (slantRotation * vec4(point - vec3(0.55, -0.315, 0.0), 1.0)).xyz;
    float groundSlant = boxDistance(rotatedPoint, vec3(0.3, 0.2, 0.15));
    
    return opUnion(
        opUnion(mesa, opUnion(ground, opUnion(groundBase, groundSlant))),
        opSubtract(outer, inner)
	);
}

vec3 sceneNormal(vec3 point) {
	const float epsilon = 0.01;
    const vec3 xOffset = vec3(epsilon, 0.0, 0.0);
    const vec3 yOffset = vec3(0.0, epsilon, 0.0);
    const vec3 zOffset = vec3(0.0, 0.0, epsilon);
    vec3 direction = vec3(
    	sceneDistance(point + xOffset) - sceneDistance(point - xOffset),
    	sceneDistance(point + yOffset) - sceneDistance(point - yOffset),
    	sceneDistance(point + zOffset) - sceneDistance(point - zOffset)
	);
        
    return normalize(direction);
}

vec3 materialColor(vec3 viewDirection, vec3 normal) {
    vec3 bounceDirection = reflect(viewDirection, normal);
    return texture(iChannel0, bounceDirection).xxx;
}

vec3 sceneColor(vec2 uv) {
    mat4 rotation = rotateY(iTime * -2.5);
    
	vec3 origin = vec3(0.0, 0.0, -2.0);
    vec3 direction = normalize(vec3(uv.x, uv.y, 0.68));
    origin = (rotation * vec4(origin, 0.0)).xyz;
    direction = (rotation * vec4(direction, 0.0)).xyz;
    
    bool hit = false;
    vec3 testPoint;
    for (float time = 0.0; time < 4.0; time += 0.001) {
		testPoint = origin + direction * time;
        float dist = sceneDistance(testPoint);
        time += dist;
        
        if (dist < 0.001) {
            hit = true;
            break;
        }
    }
    
    return hit
        ? materialColor(direction, sceneNormal(testPoint))
        : vec3(0.0);
}

vec2 coordToUv(vec2 coord) {
 	return (coord - iResolution.xy * 0.5) / iResolution.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    const float a = (3.0 / 8.0);
    const float b = (1.0 / 8.0);
    vec3 acc = vec3(0.0);
    acc += sceneColor(coordToUv(fragCoord + vec2(-a, b)));
    acc += sceneColor(coordToUv(fragCoord + vec2(-b, -a)));
    acc += sceneColor(coordToUv(fragCoord + vec2(a, -b)));
    acc += sceneColor(coordToUv(fragCoord + vec2(b, a)));
    acc /= 4.0;
    
    fragColor = vec4(acc, 1.0);
}