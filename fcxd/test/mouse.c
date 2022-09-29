#include "unity_internals.h"
#include <unity.h>

void setUp() {}

void tearDown() {}

void test_mouse_move() { TEST_ASSERT_TRUE(0); }

int main() {
  UNITY_BEGIN();
  RUN_TEST(test_mouse_move);
  return UNITY_END();
}
