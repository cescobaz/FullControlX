#include "../src/fcx_mouse.h"
#include <CUnit/Basic.h>
#include <json-c/json.h>

#ifdef _WIN32
#include <Winsock2.h>
#else
#include <unistd.h>
#endif

int init_suite() { return 0; }

int clean_suite() { return 0; }

typedef enum { axis_x = 0, axis_y = 1 } axis;

int location_axis(struct json_object *location, axis axis) {
  return json_object_get_int64(json_object_array_get_idx(location, axis));
}

void wait_for_event_post() {
  struct timeval tv;
  tv.tv_sec = 0;
  tv.tv_usec = 50 * 1000; // 30 doesn't work always, 40 could be ok, 50 is
                          // "secure". At least on my machine
  select(0, NULL, NULL, NULL, &tv);
}

void test_mouse_move() {
  int mx = 21;
  int my = 7;
  struct json_object *location = fcx_mouse_location();
  CU_ASSERT_TRUE(0 == fcx_mouse_move(mx, my));
  wait_for_event_post();
  struct json_object *new_location = fcx_mouse_location();
  int dx =
      location_axis(new_location, axis_x) - location_axis(location, axis_x);
  CU_ASSERT_TRUE(dx <= mx + 2);
  CU_ASSERT_TRUE(dx >= mx - 2);
  int dy =
      location_axis(new_location, axis_y) - location_axis(location, axis_y);
  CU_ASSERT_TRUE(dy <= my + 2);
  CU_ASSERT_TRUE(dy >= my - 2);
}

int main() {
  CU_pSuite pSuite = NULL;

  /* initialize the CUnit test registry */
  if (CUE_SUCCESS != CU_initialize_registry())
    return CU_get_error();

  /* add a suite to the registry */
  pSuite = CU_add_suite("Suite_1", init_suite, clean_suite);
  if (NULL == pSuite) {
    CU_cleanup_registry();
    return CU_get_error();
  }

  /* add the tests to the suite */
  if ((NULL == CU_add_test(pSuite, "test mouse move", test_mouse_move))) {
    CU_cleanup_registry();
    return CU_get_error();
  }

  /* Run all tests using the CUnit Basic interface */
  CU_basic_set_mode(CU_BRM_VERBOSE);
  CU_basic_run_tests();
  CU_cleanup_registry();
  return CU_get_error();
}
