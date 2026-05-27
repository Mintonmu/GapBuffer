#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 这是一个不透明指针，C 语言不需要知道它内部的结构
typedef struct GapBuffer GapBuffer;

// 创建 GapBuffer
GapBuffer* gapbuffer_create(size_t capacity);

// 销毁 GapBuffer
void gapbuffer_destroy(GapBuffer* gb);

// 插入字符
void gapbuffer_insert(GapBuffer* gb, uint8_t value);

// 移动光标
void gapbuffer_move_cursor_left(GapBuffer* gb);
void gapbuffer_move_cursor_right(GapBuffer* gb);

// 删除光标左侧字符
void gapbuffer_backspace(GapBuffer* gb);

// 获取有效文本，返回的指针需要使用 gapbuffer_free_text 释放
uint8_t* gapbuffer_get_text(GapBuffer* gb, size_t* out_len);

// 释放获取到的文本内存
void gapbuffer_free_text(uint8_t* text, size_t len);

#ifdef __cplusplus
}
#endif
