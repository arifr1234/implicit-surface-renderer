import React from 'react'

import * as twgl from 'twgl.js'

import vertex_shader from "../shaders/vs.glsl";

import fragment_shader_header from "../shaders/header.glsl";
import auto_diff_funcs from "../shaders/auto_diff.glsl";
import buffer_A_fragment_shader from "../shaders/buffer_A_fs.glsl";
import image_fragment_shader from "../shaders/image_fs.glsl";
import surface_function from "../shaders/surfaces/torus.glsl";
import scene_funcs from "../shaders/scene.glsl";

function get_attachments(uniforms){
  return Object.fromEntries(Object.entries(uniforms).map(([key, value]) => [key, value.attachments[0]]));
}

function concat_shaders(...shaders){
  return shaders.join("\n");
}

export default class Renderer extends React.Component{
  constructor(props) {
    super(props);

    this.canvas_ref = React.createRef();
    this.width = props.width;
    this.height = props.height;

    this.angles = [0, 0];
  }

  render() {
    const handleMouseMove = event => {
      if(self.is_mouse_down)
      {
        this.angles = [
          this.angles[0] + 2.*Math.PI * event.movementX / this.resolution[0],
          this.angles[1] - 2.*Math.PI * event.movementY / this.resolution[1],
        ];
      }
    };

    const handleMouseDown = event => {
      self.is_mouse_down = true;
    }
    const handleMouseUp = event => {
      self.is_mouse_down = false;
    }

    return <canvas ref={this.canvas_ref} onMouseMove={handleMouseMove} onMouseDown={handleMouseDown} onMouseUp={handleMouseUp} style={{width: this.width, height: this.height}}></canvas>
  }

  draw(gl, program, to, uniforms)
  {
    twgl.bindFramebufferInfo(gl, to);

    gl.useProgram(program.program);
    twgl.setBuffersAndAttributes(gl, program, self.triangles_buffer_info);
    twgl.setUniforms(program, uniforms);
    twgl.drawBufferInfo(gl, self.triangles_buffer_info);
  }

  componentDidMount() {
    const gl = this.canvas_ref.current.getContext("webgl2");
    gl.getExtension('EXT_color_buffer_float');

    twgl.resizeCanvasToDisplaySize(gl.canvas);
    this.resolution = [gl.canvas.width, gl.canvas.height];
    console.log(this.resolution);

    const image = {};
    const A = {};

    image.program = twgl.createProgramInfo(gl, [vertex_shader, concat_shaders(fragment_shader_header, scene_funcs, auto_diff_funcs, surface_function, image_fragment_shader)], err => {
      throw Error(err);
    });

    A.program = twgl.createProgramInfo(gl, [vertex_shader, concat_shaders(fragment_shader_header, scene_funcs, auto_diff_funcs, surface_function, buffer_A_fragment_shader)], err => {
      throw Error(err);
    });

    const attachments = [
      { format: gl.RGBA, internalFormat: gl.RGBA32F, type: gl.FLOAT, mag: gl.NEAREST, min: gl.NEAREST },
    ];

    A.in_buffer = twgl.createFramebufferInfo(gl, attachments);
    A.out_buffer = twgl.createFramebufferInfo(gl, attachments);

    self.triangles_buffer_info = twgl.createBufferInfoFromArrays(gl, {
      position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
    });
    

    const render = (time) => {
      if (this.start === undefined) {
        this.start = time;
      }    

      const uniforms = {
        time: (time - this.start) * 0.001,
        resolution: this.resolution,
        angles: this.angles,
      };

      gl.viewport(0, 0, this.resolution[0], this.resolution[1]);
  
      this.draw(gl, A.program,     A.out_buffer, {...uniforms, ...get_attachments({buffer_A: A.in_buffer})});
      this.draw(gl, image.program, null,         {...uniforms, ...get_attachments({buffer_A: A.in_buffer})});

      [A.out_buffer, A.in_buffer] = [A.in_buffer, A.out_buffer]
  
      requestAnimationFrame(render);
    }
    requestAnimationFrame(render);
  }
}
