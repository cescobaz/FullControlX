#include "../src/fcx_mouse.h"
#include <json-c/json.h>
#include <unistd.h>
#include <unity.h>

void setUp() {}

void tearDown() {}

typedef enum { axis_x = 0, axis_y = 1 } axis;

int location_axis(struct json_object *location, axis axis) {
  return json_object_get_int64(json_object_array_get_idx(location, axis));
}

void test_mouse_move() {
  int mx = 21;
  int my = 7;
  struct json_object *location = fcx_mouse_location();
  TEST_ASSERT_TRUE(0 == fcx_mouse_move(mx, my));
  struct json_object *new_location = fcx_mouse_location();
  int dx =
      location_axis(new_location, axis_x) - location_axis(location, axis_x);
  TEST_ASSERT_TRUE(abs(dx - mx) < 2);
  int dy =
      location_axis(new_location, axis_y) - location_axis(location, axis_y);
  TEST_ASSERT_TRUE(abs(dy - my) < 2);
}

int main() {
  UNITY_BEGIN();
  RUN_TEST(test_mouse_move);
  return UNITY_END();
}
