async function require(href) {
  const res = await fetch(href);
  const text = await res.text();
  return text;
}

async function main() {
  // Get A WebGL context
  /** @type {HTMLCanvasElement} */
  const canvas = document.querySelector("#canvas");
  const gl = canvas.getContext("webgl2");
  if (!gl) {
    return;
  }

  let isStabilized = 0;

  const btnEl = document.getElementById('btn');
  
  document.getElementById('btn').addEventListener("click", function() {
    isStabilized = +!isStabilized;
    time = 0;
    if (btnEl.innerHTML === "Estabilizar") {
      btnEl.innerHTML = "Desestabilizar";
    } else {
      btnEl.innerHTML = "Estabilizar";
    }

  });

  const vs = await require('shaders/vertex.glsl')
  const fs = await require('shaders/fragment.glsl')

  const program = webglUtils.createProgramFromSources(gl, [vs, fs]);

  const positionAttributeLocation = gl.getAttribLocation(program, "a_position");

  const resolutionLocation = gl.getUniformLocation(program, "iResolution");
  const timeLocation = gl.getUniformLocation(program, "iTime");
  const stabilizedLocation = gl.getUniformLocation(program, "iStabilized");

  const vao = gl.createVertexArray();

  gl.bindVertexArray(vao);

  const positionBuffer = gl.createBuffer();

  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,  
     1, -1,
    -1,  1,
    -1,  1,  
     1, -1,
     1,  1,
  ]), gl.STATIC_DRAW);

  gl.enableVertexAttribArray(positionAttributeLocation);

  gl.vertexAttribPointer(
    positionAttributeLocation,
    2,          
    gl.FLOAT,   
    false,      
    0,          
    0,          
  );

  let then = 0;
  let time = 0;
  function render(now) {
    now *= 0.001;  
    const elapsedTime = Math.min(now - then, 0.1);
    time += elapsedTime;
    then = now;

    webglUtils.resizeCanvasToDisplaySize(gl.canvas);

    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

    gl.useProgram(program);

    gl.bindVertexArray(vao);

    gl.uniform2f(resolutionLocation, gl.canvas.width, gl.canvas.height);
    gl.uniform1f(timeLocation, time);
    gl.uniform1i(stabilizedLocation, isStabilized);

    gl.drawArrays(
      gl.TRIANGLES,
      0,    
      6,     
    );

    requestAnimationFrame(render);
  }

  requestAnimationFrame(render);
}

main();
