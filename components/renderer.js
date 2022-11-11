import React from 'react'

import * as twgl from 'twgl.js'

import vertex_shader from "../shaders/vs.glsl";
import optimizer_vertex_shader from "../shaders/optimizer_vertex_shader.glsl";

import fragment_shader_header from "../shaders/header.glsl";
import auto_diff_funcs from "../shaders/auto_diff.glsl";
import optimizer_fragment_shader from "../shaders/optimizer.glsl";
import gradient_calculator_fragment_shader from "../shaders/gradient_calculator.glsl";
import gradient_adder_fragment_shader from "../shaders/gradient_adder.glsl";
import image_fragment_shader from "../shaders/image_fs.glsl";
import surface_function from "../shaders/surfaces/torus.glsl";
import scene_funcs from "../shaders/scene.glsl";

function get_attachments(uniforms){
  return Object.fromEntries(Object.entries(uniforms).map(([key, value]) => [key, value.attachments[0]]));
}

function concat_shaders(...shaders){
  return shaders.join("\n");
}

const ADAM_PARAMS = {
  alpha: "0.1",
  b1: 0.9,
  b2: 0.999
}

function defines(params){
  return (
    Object.entries(params)
    .map(([key, value]) => `#define ${key} ${value}`)
    .join("\n")
  );
}

function consts(params){
  return (
    Object.entries(params)
    .map(([key, value]) => `const ${key} = ${value};`)
    .join("\n")
  );
}

export default class Renderer extends React.Component{
  constructor(props) {
    super(props);

    this.canvas_ref = React.createRef();
    this.width = props.width;
    this.height = props.height;

    this.angles = [0, 0];

    this.b1_pow_i = 1;
    this.b2_pow_i = 1;
  }

  render() {
    const handleMouseMove = event => {
      if(this.is_mouse_down)
      {
        this.angles = [
          this.angles[0] + 2.*Math.PI * event.movementX / this.resolution[0],
          this.angles[1] - 2.*Math.PI * event.movementY / this.resolution[1],
        ];
      }
    };

    const handleMouseDown = event => {
      this.is_mouse_down = true;
    }
    const handleMouseUp = event => {
      this.is_mouse_down = false;
    }

    return <canvas ref={this.canvas_ref} onMouseMove={handleMouseMove} onMouseDown={handleMouseDown} onMouseUp={handleMouseUp} style={{width: this.width, height: this.height}}></canvas>
  }

  draw(gl, program, to, uniforms, buffer_info=null, instanceCount=undefined)
  {
    if(buffer_info === null) buffer_info = this.triangles_buffer_info;

    gl.bindFramebuffer(gl.FRAMEBUFFER, to?.framebuffer);

    gl.useProgram(program.program);
    twgl.setBuffersAndAttributes(gl, program, buffer_info);
    twgl.setUniforms(program, uniforms);
    twgl.drawBufferInfo(gl, buffer_info, undefined, undefined, undefined, instanceCount);
  }

  componentDidMount() {
    const gl = this.canvas_ref.current.getContext("webgl2");
    gl.getExtension('EXT_color_buffer_float');

    twgl.resizeCanvasToDisplaySize(gl.canvas);
    this.resolution = [gl.canvas.width, gl.canvas.height];
    console.log(this.resolution);

    const mipmap_resolutions = [this.resolution];
    const min_points = [[0, 0]];
    var size = this.resolution;
    var y_sum = 0;
    var pixel_num = 0;
    do {
      size = [Math.ceil(size[0]/2), Math.ceil(size[1]/2)];

      mipmap_resolutions.push(size);
      min_points.push([this.resolution[0], y_sum]);

      y_sum += size[1];
      pixel_num += size[0] * size[1];
    } while (size[0] != 1 || size[1] != 1);

    const image = {};
    const optimizer = {};
    const gradient = {};

    const min_points_const_glsl = consts({[
      `ivec2 min_points[${min_points.length}]`]: 
      `ivec2[](${
        min_points
        .map(v => `ivec2(${v[0]}, ${v[1]})`)
        .join(",")
      })`
    });

    image.program = twgl.createProgramInfo(gl, 
      [
        vertex_shader, 
        concat_shaders(
          fragment_shader_header, 
          scene_funcs, 
          auto_diff_funcs, 
          surface_function, 
          image_fragment_shader
        )
      ], 
      err => {
        throw Error(err);
      }
    );

    optimizer.program = twgl.createProgramInfo(gl, 
      [
        optimizer_vertex_shader, 
        concat_shaders(
          fragment_shader_header, 
          auto_diff_funcs, 
          defines(ADAM_PARAMS),
          optimizer_fragment_shader
        )
      ], 
      err => {
        throw Error(err);
      }
    );

    gradient.program = twgl.createProgramInfo(gl, 
      [
        vertex_shader, 
        concat_shaders(
          fragment_shader_header, 
          scene_funcs, 
          auto_diff_funcs, 
          surface_function, 
          min_points_const_glsl,
          gradient_calculator_fragment_shader
        )
      ], 
      err => {
        throw Error(err);
      }
    );

    const gradient_adder_program = twgl.createProgramInfo(gl, 
      [
        vertex_shader, 
        concat_shaders(
          fragment_shader_header, 
          gradient_adder_fragment_shader
        )
      ], 
      err => {
        throw Error(err);
      }
    );

    const attachments = [
      { format: gl.RGBA, internalFormat: gl.RGBA32F, type: gl.FLOAT, mag: gl.NEAREST, min: gl.NEAREST },
    ];

    const extended_resolution = [this.resolution[0] + mipmap_resolutions[1][0], Math.max(y_sum, this.resolution[1])];

    optimizer.in_buffer = twgl.createFramebufferInfo(gl, attachments, extended_resolution[0], extended_resolution[1]);
    optimizer.out_buffer = twgl.createFramebufferInfo(gl, attachments, extended_resolution[0], extended_resolution[1]);

    gradient.even_buffer = twgl.createFramebufferInfo(gl, attachments, extended_resolution[0], extended_resolution[1]);
    gl.clearBufferfv(gl.COLOR, 0, [0.0, 0.0, 0.0, 0.0]);
    gradient.odd_buffer = twgl.createFramebufferInfo(gl, attachments, extended_resolution[0], extended_resolution[1]);
    gl.clearBufferfv(gl.COLOR, 0, [0.0, 0.0, 0.0, 0.0]);

    this.triangles_buffer_info = twgl.createBufferInfoFromArrays(gl, {
      position: {numComponents: 3, data: new Float32Array([-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0])},
    });

    this.optimizer_instanced_draw_buffer_info = twgl.createBufferInfoFromArrays(gl, {
      position: this.triangles_buffer_info.attribs.position,
      optimization_min_point: {divisor: 1, numComponents: 2, data: new Float32Array(min_points.flat())},
      mipmap_resolution: {divisor: 1, numComponents: 2, data: new Float32Array(mipmap_resolutions.flat())},
      lod: {divisor: 1, numComponents: 1, data: new Uint32Array(mipmap_resolutions.map((v, i) => i))}
    });

    console.log(mipmap_resolutions.flat());
    console.log(min_points.flat());
    console.log(mipmap_resolutions.map((v, i) => i));

    const iteration = (uniforms) => {
      this.b1_pow_i *= ADAM_PARAMS.b1;
      this.b2_pow_i *= ADAM_PARAMS.b2;

      gl.viewport(0, 0, extended_resolution[0], extended_resolution[1]);
      this.draw(
        gl, 
        optimizer.program,
        optimizer.out_buffer, 
        {
          ...uniforms, 
          extended_resolution: extended_resolution,
          m_hat_normalization: 1 - this.b1_pow_i,
          v_hat_normalization: 1 - this.b2_pow_i,  
          ...get_attachments({
            optimization_parameters: optimizer.in_buffer,
            even_gradient: gradient.even_buffer,
            odd_gradient: gradient.odd_buffer
          })
        },
        this.optimizer_instanced_draw_buffer_info,
        mipmap_resolutions.length
      );
      [optimizer.out_buffer, optimizer.in_buffer] = [optimizer.in_buffer, optimizer.out_buffer]

      gl.viewport(0, 0, this.resolution[0], this.resolution[1]);
      this.draw(
        gl, 
        gradient.program,
        gradient.even_buffer, 
        {
          ...uniforms, 
          ...get_attachments({
            optimization_parameters: optimizer.in_buffer,
          })
        }
      );

      gradient.in_buffer = gradient.even_buffer;
      gradient.out_buffer = gradient.odd_buffer;

      mipmap_resolutions.forEach((_, i) => {
        if(i == 0) return;

        const current_resolution = mipmap_resolutions[i];
        const min_point = min_points[i];

        gl.viewport(min_point[0], min_point[1], current_resolution[0], current_resolution[1]);

        const previous_min_point = min_points[i - 1];
                
        this.draw(
          gl, 
          gradient_adder_program,
          gradient.out_buffer, 
          {
            min_point: min_point,
            previous_min_point: previous_min_point,
            ...get_attachments({
              gradient: gradient.in_buffer,
            })
          }
        );

        [gradient.out_buffer, gradient.in_buffer] = [gradient.in_buffer, gradient.out_buffer]
      });
    }
    
    self.frame = (time) => {
      if (this.start === undefined) {
        this.start = time;
      }

      const uniforms = {
        time: (time - this.start) * 0.001,
        resolution: this.resolution,
        angles: this.angles,
      };

      for(var i = 0; i < 1; i ++)
      {
        iteration(uniforms);
      }

      gl.viewport(0, 0, this.resolution[0], this.resolution[1]);

      this.draw(
        gl,
        image.program,
        null,
        {...uniforms, ...get_attachments({even_gradient: gradient.even_buffer})}
      );
  
      requestAnimationFrame(self.frame);
    }
    if(self.frame) requestAnimationFrame(self.frame);
    else gl.getExtension('WEBGL_lose_context').loseContext();
  }

  componentWillUnmount() {
    self.frame = null;
  }
}
