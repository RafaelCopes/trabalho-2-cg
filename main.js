function main() {
  // Get A WebGL context
  /** @type {HTMLCanvasElement} */
  const canvas = document.querySelector("#canvas");
  const gl = canvas.getContext("webgl2");
  if (!gl) {
    return;
  }

  const vs = `#version 300 es
    in vec4 a_position;

    void main() {
      gl_Position = a_position;
    }
  `;

  const fs = `#version 300 es
    precision highp float;

    #define MAX_STEPS 100
    #define MAX_DIST 100.
    #define SURFACE_DIST .01

    uniform vec2 iResolution;
    uniform vec2 iMouse;
    uniform float iTime;

    out vec4 outColor;

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

      float dBox = sdBox(bp, vec3(.5));

      float d = min(dPlane, dBox);
      
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
      vec3 lightPos = vec3(0, 5, 6);
      lightPos.xz += vec2(sin(iTime), cos(iTime))*2.;

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
  `;

  // setup GLSL program
  const program = webglUtils.createProgramFromSources(gl, [vs, fs]);

  // look up where the vertex data needs to go.
  const positionAttributeLocation = gl.getAttribLocation(program, "a_position");

  // look up uniform locations
  const resolutionLocation = gl.getUniformLocation(program, "iResolution");
  const timeLocation = gl.getUniformLocation(program, "iTime");

  // Create a vertex array object (attribute state)
  const vao = gl.createVertexArray();

  // and make it the one we're currently working with
  gl.bindVertexArray(vao);

  // Create a buffer to put three 2d clip space points in
  const positionBuffer = gl.createBuffer();

  // Bind it to ARRAY_BUFFER (think of it as ARRAY_BUFFER = positionBuffer)
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

  // fill it with a 2 triangles that cover clip space
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  // first triangle
     1, -1,
    -1,  1,
    -1,  1,  // second triangle
     1, -1,
     1,  1,
  ]), gl.STATIC_DRAW);

  // Turn on the attribute
  gl.enableVertexAttribArray(positionAttributeLocation);

  // Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
  gl.vertexAttribPointer(
      positionAttributeLocation,
      2,          // 2 components per iteration
      gl.FLOAT,   // the data is 32bit floats
      false,      // don't normalize the data
      0,          // 0 = move forward size * sizeof(type) each iteration to get the next position
      0,          // start at the beginning of the buffer
  );

  let then = 0;
  let time = 0;
  function render(now) {
    now *= 0.001;  // convert to seconds
    const elapsedTime = Math.min(now - then, 0.1);
    time += elapsedTime;
    then = now;

    webglUtils.resizeCanvasToDisplaySize(gl.canvas);

    // Tell WebGL how to convert from clip space to pixels
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

    // Tell it to use our program (pair of shaders)
    gl.useProgram(program);

    // Bind the attribute/buffer set we want.
    gl.bindVertexArray(vao);

    gl.uniform2f(resolutionLocation, gl.canvas.width, gl.canvas.height);
    gl.uniform1f(timeLocation, time);

    gl.drawArrays(
        gl.TRIANGLES,
        0,     // offset
        6,     // num vertices to process
    );

    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);
}

main();
