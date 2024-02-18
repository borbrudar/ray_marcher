extern crate sdl2;
extern crate gl;

use sdl2::pixels::Color;
use sdl2::event::Event;
use sdl2::keyboard::Keycode;
use std::time::Duration;

pub fn main() {
    let sdl_context = sdl2::init().unwrap();
    let video_subsystem = sdl_context.video().unwrap();

    let window = video_subsystem
        .window("Ray marcher fr", 800, 600)
        .opengl()
        .resizable()
        .position_centered()
        .build()
        .unwrap();
    
    let gl_context = window.gl_create_context().unwrap();
    let gl = gl::load_with(|s| video_subsystem.gl_get_proc_address(s) as *const std::os::raw::c_void);


    let mut event_pump = sdl_context.event_pump().unwrap();
    let mut ii = 0;
    unsafe {
        gl::ClearColor(0.3, 0.3, 0.5, 1.0);
    }
    
    'main: loop {
        ii = (ii + 1) % 255;
        let i : f32 = ii as f32;
        unsafe {
            gl::ClearColor(i/255.0, 64.0/255.0, (255.0-i)/255.0, 1.0);
        }
        //canvas.set_draw_color(Color::RGB(i, 64, 255 - i));
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
            gl::Clear(gl::COLOR_BUFFER_BIT);
        }
        window.gl_swap_window();

        ::std::thread::sleep(Duration::new(0, 1_000_000_000u32 / 60));
    }
}