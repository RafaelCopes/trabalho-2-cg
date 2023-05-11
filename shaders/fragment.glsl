#version 300 es
precision highp float;

// feito com base nos artigos deste site: https://iquilezles.org/articles
// e nos videos deste canal: https://www.youtube.com/@TheArtofCodeIsCool

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURFACE_DIST .01

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform int iStabilized;

out vec4 outColor;

float sdSphere( vec3 p, float s ) {
  return length(p) - s;
}

float sdLine(vec3 p, vec3 a, vec3 b) {
  vec3 ap = p - a;
  vec3 ab = b - a;

  float t = dot(ap, ab) / dot(ab, ab);
  vec3 c = a + ab * t;
  return length(p - c);            
}

float sdCylinder( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float getDist(vec3 p) {
  float dPlane = p.y;

  vec3 bp = p - vec3(0, 0.5, 6);

  float dCylinder = sdCylinder(bp + vec3(-3, 0.1, 1), 1.7, 0.25);
  float dCylinder2 = sdCylinder(bp + vec3(3, 0.1, 1), 1.7, 0.25);

  float distortion = sin(5.0 * p.x + iTime*2.) * (sin(5.0 * p.y + iTime*2.) * cos(5.0 * p.y + iTime*3.)) * sin(5.0 * p.z + iTime*2.) * 0.25;  

  if (iStabilized == 1) {
    float dLine = sdLine(bp.xyz, vec3(-3, 1.6, -1), vec3(3, 0.5, -1)) - 0.001;
    float dLine2 = sdLine(bp.xyz, vec3(3, 1.6, -1), vec3(-3, 0.5, -1)) - 0.001;

    dLine = max(dLine, bp.x - 0.5);
    dLine = max(dLine, -bp.x - 3.);

    dLine2 = max(dLine2, bp.x - 3.);
    dLine2 = max(dLine2, -bp.x - 0.5);
    

    float dSphere = sdSphere(bp + vec3(0, -1, 1), 0.8) + distortion / 20.;
    float dSphere2 = sdSphere(bp + vec3(0, -1, 1), 0.8) + distortion;

    float transition = smoothstep(0.0, 3., iTime);
    dSphere = mix(dSphere2, dSphere, transition);

    float d = min(dPlane, dSphere);

    d *= 2. + 0.5;

    d = min(d, dCylinder);
    d = min(d, dCylinder2);
    d = min(d, dLine);
    d = min(d, dLine2);

    return d;
  } else {
    float dSphere = sdSphere(bp + vec3(0, -1, 1), 0.8) + distortion;
    float dSphere2 = sdSphere(bp + vec3(0, -1, 1), 0.8);

    float transition = smoothstep(0.0, 3., iTime);
    dSphere = mix(dSphere2, dSphere, transition);

    float d = min(dPlane, dSphere);

    d *= 2. + 0.5;

    d = min(d, dCylinder);
    d = min(d, dCylinder2);

    return d;
  }
}

float rayMarch(vec3 ro, vec3 rd) {
  float dO = 0.;

  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + dO * rd;
    float dS = getDist(p);
    dO += dS;
    if (dS < SURFACE_DIST || dS >  MAX_DIST) break;
  }

  return dO;
}

vec3 getNormal(vec3 p) {
  float d = getDist(p);

  vec2 e = vec2(.01, 0);

  vec3 normal = d - vec3(
    getDist(p-e.xyy),
    getDist(p-e.yxy),
    getDist(p-e.yyx));
  
  return normalize(normal);
}

float getLight(vec3 p) {
  vec3 lightPos = vec3(0, 10, 6);
  lightPos.xz += vec2(sin(iTime), cos(iTime))*2.;

  vec3 lightVector = normalize(lightPos - p);
  vec3 normal = getNormal(p);

  float diffuse = clamp(dot(normal, lightVector), 0., 1.);
  float d = rayMarch(p + normal * SURFACE_DIST * 2., lightVector);

  if (d < length(lightPos - p)) diffuse *= .1;  

  return diffuse;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
  
  vec3 col = vec3(0,0,0);

  vec3 ro = vec3(0, 2, 0);
  vec3 rd = normalize(vec3(uv.x, uv.y-.2, 1));

  float d = rayMarch(ro, rd);

  vec3 p = ro + rd * d;

  float diffuse = getLight(p);

  col = vec3(diffuse);

  fragColor = vec4(col, 1.0);
}

void main() {
  mainImage(outColor, gl_FragCoord.xy);
}