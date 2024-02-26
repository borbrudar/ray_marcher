extern crate sdl2;
extern crate gl;

pub mod render_gl;
use sdl2::pixels::Color;
use sdl2::event::{Event, self};
use sdl2::keyboard::Keycode;
use std::time::Duration;
use render_gl::Uniform;
use std::time::Instant;
use std::env;
use std::fs;
use std::file;
use std::io::{Read, Write};

pub fn main() {
    //std::env::set_var("RUST_BACKTRACE", "full");    
    let sdl_context = sdl2::init().unwrap();
    let video_subsystem = sdl_context.video().unwrap();
    
    // set opengl version 4.5
    let gl_attr = video_subsystem.gl_attr();
    
    gl_attr.set_context_profile(sdl2::video::GLProfile::Core);
    gl_attr.set_context_version(4,5);
    
    let window = video_subsystem
    .window("Ray marcher fr", 1080, 720)
    .opengl()
    .resizable()
    .position_centered()
    .build()
        .unwrap();
    
    let gl_context = window.gl_create_context().unwrap();
    let gl = gl::load_with(|s| video_subsystem.gl_get_proc_address(s) as *const std::os::raw::c_void);
    
    unsafe{
        gl::Viewport(0,0,1080,720);
        gl::ClearColor(0.3,0.3,0.5,1.0);
    }
    
    let mut event_pump = sdl_context.event_pump().unwrap();

    let vert_shader = render_gl::Shader::from_vert_file(
        "src/vert.glsl".to_string()
    ).unwrap();
    
    let frag_shader = render_gl::Shader::from_frag_file(
        "src/frag.glsl".to_string()
    ).unwrap();
    
    let shader_program = render_gl::Program::from_shaders(
        &[vert_shader,frag_shader]
    ).unwrap();

    
    /**/
    let vertices: Vec<f32> = vec![
        // positions      
        1.0, -1.0, 0.0,   // bottom right
    -1.0, -1.0, 0.0,  // bottom left
    -1.0,  1.0, 0.0,   // top
    
    -1.0,  1.0, 0.0,   // top
    1.0,  1.0, 0.0, // top right
    1.0, -1.0, 0.0,   // bottom right
    ];
    
    let mut vbo: gl::types::GLuint = 0;
    unsafe {
        gl::GenBuffers(1, &mut vbo);
    }

    unsafe{
        gl::BindBuffer(gl::ARRAY_BUFFER,vbo);
        gl::BufferData(
            gl::ARRAY_BUFFER,
            (vertices.len() * std::mem::size_of::<f32>()) as gl::types::GLsizeiptr, // size of data in bytes
            vertices.as_ptr() as *const gl::types::GLvoid, // pointer to data
            gl::STATIC_DRAW, // usage
        );
        gl::BindBuffer(gl::ARRAY_BUFFER, 0); // unbind the buffer
    }
    
    let mut vao: gl::types::GLuint = 0;
    unsafe {
        gl::GenVertexArrays(1, &mut vao);
        gl::BindVertexArray(vao);
        gl::BindBuffer(gl::ARRAY_BUFFER, vbo);
        
        gl::EnableVertexAttribArray(0); // this is "layout (location = 0)" in vertex shader
        gl::VertexAttribPointer(
            0, // index of the generic vertex attribute ("layout (location = 0)")
            3, // the number of components per generic vertex attribute
            gl::FLOAT, // data type
            gl::FALSE, // normalized (int-to-float conversion)
            (3 * std::mem::size_of::<f32>()) as gl::types::GLint, // stride (byte offset between consecutive attributes)
            std::ptr::null() // offset of the first component
        );
        
        
        gl::BindBuffer(gl::ARRAY_BUFFER, 0);
        gl::BindVertexArray(0);
    }
    /**/
    
    let u_resolution : Uniform = Uniform::new(shader_program.id(),"u_resolution").unwrap();
    let u_mouse : Uniform = Uniform::new(shader_program.id(),"u_mouse").unwrap();
    //let u_time : Uniform = Uniform::new(shader_program.id(),"u_time").unwrap();
    let now = Instant::now();
    
    
    'main: loop {
        for event in event_pump.poll_iter() {
            match event {
                Event::Quit {..} |
                Event::KeyDown { keycode: Some(Keycode::Escape), .. } => {
                    break 'main
                },
                _ => {}
            }
        }
        unsafe{ 
            gl::Uniform2f(u_resolution.id, 1080.0, 720.0);
            gl::Uniform2f(u_mouse.id,
            event_pump.mouse_state().x() as f32,
            event_pump.mouse_state().y() as f32);
            //gl::Uniform1f(u_time.id,now.elapsed().as_secs_f32());
        }
        shader_program.set_used();
        
        unsafe{
            //gl::Clear(gl::COLOR_BUFFER_BIT);
            gl::BindVertexArray(vao);
            gl::DrawArrays(
                gl::TRIANGLES, // mode
                0, //starting index in the enabled arrays
                6 // number of indices to be rendered
            );
        }
        window.gl_swap_window();
        
        ::std::thread::sleep(Duration::new(0, 1_000_000_000u32 / 60));
    }
}