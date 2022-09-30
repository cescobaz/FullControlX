#include "../src/fcx_mouse.h"
#include <unity.h>

void setUp() {}

void tearDown() {}

void test_mouse_move() { TEST_ASSERT_TRUE(fcx_mouse_move(1, 1)); }

int main() {
  UNITY_BEGIN();
  RUN_TEST(test_mouse_move);
  return UNITY_END();
}
