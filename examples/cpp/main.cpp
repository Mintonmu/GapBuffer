#include <iostream>
#include <string>
#include "../c/gapbuffer.h"

// 使用 C++ 类封装 C 接口，实现 RAII 自动内存管理
class GapBufferWrapper {
private:
    GapBuffer* gb;

public:
    GapBufferWrapper(size_t capacity) {
        gb = gapbuffer_create(capacity);
        if (!gb) {
            throw std::bad_alloc();
        }
    }

    ~GapBufferWrapper() {
        gapbuffer_destroy(gb);
    }

    void insert(char c) {
        gapbuffer_insert(gb, c);
    }

    void moveLeft() {
        gapbuffer_move_cursor_left(gb);
    }

    void moveRight() {
        gapbuffer_move_cursor_right(gb);
    }

    void backspace() {
        gapbuffer_backspace(gb);
    }

    std::string getText() {
        size_t len;
        uint8_t* text = gapbuffer_get_text(gb, &len);
        if (!text) return "";
        
        std::string result((char*)text, len);
        gapbuffer_free_text(text, len);
        return result;
    }
};

int main() {
    std::cout << "--- C++ Example ---" << std::endl;
    
    GapBufferWrapper gb(10);
    
    gb.insert('C');
    gb.insert('+');
    gb.insert('+');
    gb.insert('!');
    
    gb.moveLeft();
    gb.backspace(); // 删除第二个 '+'
    
    std::cout << "Text: " << gb.getText() << std::endl; // 应该输出 "C+!"
    
    return 0;
}
