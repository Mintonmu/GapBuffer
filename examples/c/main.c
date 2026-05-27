#include <stdio.h>
#include "gapbuffer.h"

int main() {
    printf("--- C Example ---\n");
    
    // 初始化容量为 10 的 GapBuffer
    GapBuffer* gb = gapbuffer_create(10);
    if (!gb) {
        printf("Failed to create GapBuffer\n");
        return 1;
    }

    // 插入字符
    gapbuffer_insert(gb, 'H');
    gapbuffer_insert(gb, 'e');
    gapbuffer_insert(gb, 'l');
    gapbuffer_insert(gb, 'l');
    gapbuffer_insert(gb, 'o');
    
    // 移动光标并插入
    gapbuffer_move_cursor_left(gb); // 光标移动到 'l' 和 'o' 之间
    gapbuffer_insert(gb, '-');

    // 获取并打印文本
    size_t len;
    uint8_t* text = gapbuffer_get_text(gb, &len);
    if (text) {
        printf("Text: %.*s\n", (int)len, text); // 应该输出 "Hell-o"
        gapbuffer_free_text(text, len);
    }

    // 清理内存
    gapbuffer_destroy(gb);
    return 0;
}
