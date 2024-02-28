use gl;
use std;
use std::ffi::{CString,CStr};
use std::env;
use std::fs;
use std::file;
use std::io::{BufReader, BufRead};
use std::io::Write;
use std::collections::HashSet;
pub struct Program{
    id: gl::types::GLuint,
}

impl Program{
    pub fn from_shaders(shaders: &[Shader]) -> Result<Program,String>{
        let program_id = unsafe{ gl::CreateProgram() };

        for shader in shaders {
            unsafe{ gl::AttachShader(program_id, shader.id());}
        }
    
        unsafe{gl::LinkProgram(program_id);}
    
        // error handling
        let mut success: gl::types::GLint = 1;
        unsafe {
            gl::GetProgramiv(program_id, gl::LINK_STATUS, &mut success);
        }

        if success == 0 {
            let mut len: gl::types::GLint = 0;
            unsafe {
                gl::GetProgramiv(program_id, gl::INFO_LOG_LENGTH, &mut len);
            }
        
            let error = create_whitespace_cstring_with_len(len as usize);
        
            unsafe {
                gl::GetProgramInfoLog(
                    program_id,
                    len,
                    std::ptr::null_mut(),
                    error.as_ptr() as *mut gl::types::GLchar
                );
            }
        
            return Err(error.to_string_lossy().into_owned());
        }


        // end of error handling
        for shader in shaders{
            unsafe { gl::DetachShader(program_id,shader.id()); }
        }

        Ok(Program{id:program_id})
    }

    pub fn id(&self) -> gl::types::GLuint{
        self.id
    }

    pub fn set_used(&self){
        unsafe{
            gl::UseProgram(self.id);
        }
    }
}

impl Drop for Program{
    fn drop(&mut self){
        unsafe{
            gl::DeleteProgram(self.id);
        }
    }
}

pub struct Shader{
    id: gl::types::GLuint,
}

impl Shader {
    pub fn from_file(
        path: String,
        kind: gl::types::GLenum
    ) -> Result<Shader, String> {
        let id = shader_from_file(path, kind)?;
        Ok(Shader{id})
    }

    pub fn from_vert_file(path: String) -> Result<Shader,String> {
        match Shader::from_file(path,gl::VERTEX_SHADER){
            Ok(shader) => Ok(shader),
            Err(_) => {
                panic!("Error compiling the vertex shader.");
            } 
        }
    }
    pub fn from_frag_file(path: String) -> Result<Shader,String> {
        match Shader::from_file(path,gl::FRAGMENT_SHADER){
            Ok(shader) => Ok(shader),
            Err(_) => {
                panic!("Error compiling the fragment shader.");
            } 
        }
    }

    pub fn id(&self) -> gl::types::GLuint{
        self.id
    }
}

impl Drop for Shader{
    fn drop(&mut self){
        unsafe{
            gl::DeleteShader(self.id);
        }
    }
}

fn preprocess(
    path : String
) -> String{ // location of the preprocessed file
    let mut out = String::new();
    out.push_str(path.as_str());
    out.push_str(".tmp");

    
    let _ = fs::remove_file(out.clone());
    let _ = fs::copy(path,out.clone());
    
    let mut bad = 0;

    let mut set: HashSet<String> = HashSet::new();

    while bad == 0{
        bad = 1;


        let lines : Vec<Result<String,std::io::Error>>= BufReader::new(fs::File::open(out.clone()).expect("buffered reader fck up")).lines().collect();
        let _ = fs::remove_file(out.clone());
        let _ = fs::File::create(out.clone());

        let mut of = fs::OpenOptions::new()
            .write(true)
            .append(true)
            .open(out.clone())
            .unwrap();
        
        for line in lines {
            let s = line.unwrap();
            let words = s.split_whitespace().collect::<Vec<&str>>();
            if words.len() > 1 && words[0] == "#include" {
                let check = String::from(words[1].clone());
                if set.contains(&check.clone()){
                    continue;
                }
                bad = 0;
                set.insert(check);
                let tmp = fs::read_to_string(words[1]).unwrap();
                writeln!(of,"{}",tmp.as_str());
            }
            else {
                for i in words{
                    write!(of, "{} ", i);
                }
                writeln!(of,"");
            }     
        }
    }

    out
}


fn shader_from_file(
    path : String,
    kind : gl::types::GLuint // shader type
) -> Result<gl::types::GLuint,String> {
    println!("Given path for shader compilation: {}", path);
    let new_path = preprocess(path);
    println!("Preprocessed path is {}",new_path);
    let contents : String = fs::read_to_string(new_path).expect("Couldnt read shader file");
    let source = CString::new(contents).unwrap();

    let id = unsafe { gl::CreateShader(kind)};
    unsafe{
        gl::ShaderSource(id, 1, &source.as_ptr(), std::ptr::null());
        gl::CompileShader(id);
    }

    let mut success: gl::types::GLint = 1;
    unsafe {
        gl::GetShaderiv(id, gl::COMPILE_STATUS, &mut success);
    }
    
    if success == 0 {
        let mut len: gl::types::GLint = 0;
        unsafe{
            gl::GetShaderiv(id,gl::INFO_LOG_LENGTH,&mut len);
        }
        
        let mut error = Vec::with_capacity(len as usize);
        let buf_ptr = error.as_mut_ptr() as *mut gl::types::GLchar;
        unsafe{
            gl::GetShaderInfoLog(id, len, std::ptr::null_mut(), buf_ptr);
            let s = CStr::from_ptr(buf_ptr).to_str().unwrap();
            println!("{}",s);
        }
        
        println!("Error compiling shader >_<");
        println!("Shader type error: {}", kind);
        //return Err(error.to_string_lossy().into_owned());    
        return Err("Lol\n".to_owned());
    }

    Ok(id)
}

fn create_whitespace_cstring_with_len(len: usize) -> CString {
    // allocate buffer of correct size
    let mut buffer: Vec<u8> = Vec::with_capacity(len + 1);
    // fill it with len spaces
    buffer.extend([b' '].iter().cycle().take(len));
    // convert buffer to CString
    unsafe { CString::from_vec_unchecked(buffer) }
}

pub struct Uniform{
    pub id : gl::types::GLint,
}

impl Uniform{
    pub fn new(program : u32, name: &str) -> Result<Self,String>{
        let cname : CString = CString::new(name).expect("CString::new failed");
        let location : gl::types::GLint = unsafe{ gl::GetUniformLocation(program, cname.as_ptr())};
        if location == -1{
            return Err(format!("Couldnt get location info for {}",name));       
        }
        Ok(Uniform { id:location })
    }
}

