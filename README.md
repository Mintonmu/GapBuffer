# GapBuffer

A classic text editor data structure (Gap Buffer) implemented in [Zig](https://ziglang.org/).

A Gap Buffer allows for highly efficient $O(1)$ text insertions and deletions near the cursor, making it the perfect underlying data structure for text editors.

## Features

- Written in pure Zig with explicit memory management.
- Dynamic resizing when the gap is filled.
- Exposes a C ABI, making it easy to use from C, C++, Rust, and other languages.
- Builds both static (`.a` / `.lib`) and shared (`.so` / `.dll` / `.dylib`) libraries.

## Build Instructions

Make sure you have Zig 0.16.0 (or a compatible version) installed.

To build the libraries:
```bash
zig build
```
The compiled static and shared libraries will be available in the `zig-out/lib/` directory.

To build all examples (C, C++, Rust):
```bash
zig build examples
```
The compiled example executables will be placed in `zig-out/bin/`.

To run the Zig unit tests:
```bash
zig build test
```

## Usage Examples (FFI)

The library exposes a standard C ABI. You can find the C header file at `examples/c/gapbuffer.h`.

### 1. Using in C

```c
#include <stdio.h>
#include "gapbuffer.h"

int main() {
    GapBuffer* gb = gapbuffer_create(10);
    
    gapbuffer_insert(gb, 'H');
    gapbuffer_insert(gb, 'i');
    
    size_t len;
    uint8_t* text = gapbuffer_get_text(gb, &len);
    printf("Text: %.*s\n", (int)len, text);
    
    gapbuffer_free_text(text, len);
    gapbuffer_destroy(gb);
    return 0;
}
```

*Run with:* `LD_LIBRARY_PATH=zig-out/lib ./zig-out/bin/c_example`

### 2. Using in C++

C++ can easily wrap the C API using RAII for automatic memory management.

```cpp
#include <iostream>
#include "gapbuffer.h"

class GapBufferWrapper {
    GapBuffer* gb;
public:
    GapBufferWrapper(size_t cap) { gb = gapbuffer_create(cap); }
    ~GapBufferWrapper() { gapbuffer_destroy(gb); }
    void insert(char c) { gapbuffer_insert(gb, c); }
    // ...
};

int main() {
    GapBufferWrapper gb(10);
    gb.insert('C');
    gb.insert('+');
    gb.insert('+');
    return 0;
}
```

*Run with:* `LD_LIBRARY_PATH=zig-out/lib ./zig-out/bin/cpp_example`

### 3. Using in Rust

Rust can bind to the C ABI using `extern "C"`.

```rust
#[repr(C)]
pub struct GapBuffer { _private: [u8; 0] }

extern "C" {
    fn gapbuffer_create(capacity: usize) -> *mut GapBuffer;
    fn gapbuffer_destroy(gb: *mut GapBuffer);
    fn gapbuffer_insert(gb: *mut GapBuffer, value: u8);
}

fn main() {
    unsafe {
        let gb = gapbuffer_create(10);
        gapbuffer_insert(gb, b'R');
        gapbuffer_destroy(gb);
    }
}
```

*Run with:* `LD_LIBRARY_PATH=zig-out/lib ./zig-out/bin/rust_example`
