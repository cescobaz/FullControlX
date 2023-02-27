#include "../fcx_mouse.h"
#include <Windows.h>

int fcx_mouse_move(int x, int y) {
    INPUT input;
    memset(&input, 0, sizeof(input));
    input.type = INPUT_MOUSE;
    input.mi.dx = x;
    input.mi.dy = y;
    input.mi.dwFlags = MOUSEEVENTF_MOVE;
    input.mi.dwExtraInfo = GetMessageExtraInfo();
    return SendInput(1, &input, sizeof(INPUT));
}
int fcx_mouse_left_down() {
    INPUT input;
    memset(&input, 0, sizeof(input));
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    return SendInput(1, &input, sizeof(INPUT));
}
int fcx_mouse_left_up() {
    INPUT input;
    memset(&input, 0, sizeof(input));
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_LEFTUP;
    return SendInput(1, &input, sizeof(INPUT));
}
int fcx_mouse_left_click() {
    INPUT input[2];
    memset(input, 0, sizeof(INPUT) * 2);
    input[0].type = INPUT_MOUSE;
    input[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    input[1].type = INPUT_MOUSE;
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    return SendInput(2, input, sizeof(INPUT));
}
int fcx_mouse_right_down() {
    INPUT input;
    memset(&input, 0, sizeof(input));
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    return SendInput(1, &input, sizeof(INPUT));
}
int fcx_mouse_right_up() {
    INPUT input;
    memset(&input, 0, sizeof(input));
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    return SendInput(1, &input, sizeof(INPUT));
}
int fcx_mouse_right_click() {
    INPUT input[2];
    memset(input, 0, sizeof(INPUT) * 2);
    input[0].type = INPUT_MOUSE;
    input[0].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    input[1].type = INPUT_MOUSE;
    input[1].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    return SendInput(2, input, sizeof(INPUT));
}

int fcx_mouse_double_click() {
  fcx_mouse_left_click();
  fcx_mouse_left_click();
  return 0;
}

int fcx_mouse_scroll_wheel(int x, int y) {
  if (x == 0 && y == 0) {
    return 0;
  }
  mouse_event(MOUSE_HWHEELED, x, 0, x * 5, GetMessageExtraInfo());
  mouse_event(MOUSE_WHEELED, 0, 0, y * (-1), GetMessageExtraInfo());
}

int fcx_mouse_drag(int x, int y) { return fcx_mouse_move(x, y); }
