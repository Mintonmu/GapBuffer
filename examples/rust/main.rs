use std::os::raw::c_void;
use std::slice;
use std::str;

// 对应 C 的不透明指针
#[repr(C)]
pub struct GapBuffer {
    _private: [u8; 0],
}

// 绑定 Zig 导出的 C ABI
extern "C" {
    fn gapbuffer_create(capacity: usize) -> *mut GapBuffer;
    fn gapbuffer_destroy(gb: *mut GapBuffer);
    fn gapbuffer_insert(gb: *mut GapBuffer, value: u8);
    fn gapbuffer_move_cursor_left(gb: *mut GapBuffer);
    fn gapbuffer_move_cursor_right(gb: *mut GapBuffer);
    fn gapbuffer_backspace(gb: *mut GapBuffer);
    fn gapbuffer_get_text(gb: *mut GapBuffer, out_len: *mut usize) -> *mut u8;
    fn gapbuffer_free_text(text: *mut u8, len: usize);
}

// Rust 安全封装
pub struct SafeGapBuffer {
    ptr: *mut GapBuffer,
}

impl SafeGapBuffer {
    pub fn new(capacity: usize) -> Self {
        let ptr = unsafe { gapbuffer_create(capacity) };
        assert!(!ptr.is_null(), "Failed to allocate GapBuffer");
        Self { ptr }
    }

    pub fn insert(&mut self, value: u8) {
        unsafe { gapbuffer_insert(self.ptr, value) }
    }

    pub fn move_left(&mut self) {
        unsafe { gapbuffer_move_cursor_left(self.ptr) }
    }

    pub fn backspace(&mut self) {
        unsafe { gapbuffer_backspace(self.ptr) }
    }

    pub fn get_text(&self) -> String {
        unsafe {
            let mut len = 0;
            let text_ptr = gapbuffer_get_text(self.ptr, &mut len);
            if text_ptr.is_null() {
                return String::new();
            }
            
            let text_slice = slice::from_raw_parts(text_ptr, len);
            let result = str::from_utf8(text_slice).unwrap_or("").to_string();
            
            gapbuffer_free_text(text_ptr, len);
            result
        }
    }
}

impl Drop for SafeGapBuffer {
    fn drop(&mut self) {
        unsafe { gapbuffer_destroy(self.ptr) }
    }
}

fn main() {
    println!("--- Rust Example ---");
    
    let mut gb = SafeGapBuffer::new(10);
    gb.insert(b'R');
    gb.insert(b'u');
    gb.insert(b's');
    gb.insert(b't');
    
    gb.move_left();
    gb.insert(b'-');
    
    println!("Text: {}", gb.get_text()); // 应该输出 "Rus-t"
}