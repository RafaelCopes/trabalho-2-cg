#version 300 es
precision highp float;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURFACE_DIST .01

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;

out vec4 outColor;

/**
 * Rotation matrix around the X axis.
 */
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
      vec3(1, 0, 0),
      vec3(0, c, -s),
        vec3(0, s, c)
    );
}

/**
 * Rotation matrix around the Y axis.
 */
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
      vec3(c, 0, s),
      vec3(0, 1, 0),
      vec3(-s, 0, c)
    );
}

/**
 * Rotation matrix around the Z axis.
 */
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
      vec3(c, -s, 0),
      vec3(s, c, 0),
      vec3(0, 0, 1)
    );
}

float unionSmoothSDF( float d1, float d2, float k ) {
  float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float differenceSmoothSDF( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float sminSDF( float a, float b, float k ) {
  float res = exp2( -k*a ) + exp2( -k*b );
  return -log2( res )/k;
}

/**
 * Constructive solid geometry intersection operation on SDF-calculated distances.
 */
float intersectSDF(float distA, float distB) {
  return max(distA, distB);
}

/**
 * Constructive solid geometry union operation on SDF-calculated distances.
 */
float unionSDF(float distA, float distB) {
  return min(distA, distB);
}

/**
 * Constructive solid geometry difference operation on SDF-calculated distances.
 */
float differenceSDF(float distA, float distB) {
  return max(distA, -distB);
}

float sdSphere( vec3 p, float s ) {
  return length(p) - s;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat2 rot(float a) {
  float s = sin(a);
  float c = cos(a);

  return mat2(c, -s, s, c);
}

float getDist(vec3 p) {
  float dPlane = p.y;

  vec3 bp = p - vec3(0, 0.5, 6);
  
  bp.xz *= rot(iTime);
  
  float distortion = sin(5.0 * p.x + iTime*2.) * (sin(5.0 * p.y + iTime*2.) * cos(5.0 * p.y + iTime*3.)) * sin(5.0 * p.z + iTime*2.) * 0.25;  

  float dSphere = sdSphere(bp + vec3(0, -1, 0), 0.8) + distortion;

  float d = unionSDF(dPlane, dSphere);

  d *= 2. + 0.5;

  return d;
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
  lightPos.xz += vec2(sin(iTime), cos(iTime))*4.;

  vec3 lightVector = normalize(lightPos - p);
  vec3 normal = getNormal(p);

  float diffuse = clamp(dot(normal, lightVector), 0., 1.);
  float d = rayMarch(p + normal * SURFACE_DIST * 2., lightVector);

  if (d < length(lightPos - p)) diffuse *= .1;  

  return diffuse;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
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