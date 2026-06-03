#include "../fcx_ui_inspector.h"
#include "../logger.h"
#include <AppKit/AppKit.h>
#include <ApplicationServices/ApplicationServices.h>
#include <CoreFoundation/CoreFoundation.h>

bool fcx_ui_inspector_enabled() { return AXIsProcessTrusted(); }

CFArrayRef fcx_ui_inspector_copy_attribute_values(AXUIElementRef element,
                                                  CFStringRef attribute) {
  CFIndex count = 0;
  if (AXUIElementGetAttributeValueCount(element, attribute, &count) !=
      kAXErrorSuccess) {
    return NULL;
  }
  CFArrayRef values;
  if (AXUIElementCopyAttributeValues(element, (CFStringRef)attribute, 0, count,
                                     &values) != kAXErrorSuccess) {
    return NULL;
  }
  return values;
}

CFTypeRef fcx_ui_inspector_copy_attribute_value(AXUIElementRef element,
                                                CFStringRef attribute) {
  CFTypeRef value = NULL;
  if (AXUIElementCopyAttributeValue(element, attribute, &value) !=
      kAXErrorSuccess) {
    return NULL;
  }
  return value;
}

CFArrayRef fcx_ui_inspector_filter_by_role(CFArrayRef elements,
                                           CFStringRef role) {
  if (elements == NULL) {
    return NULL;
  }
  CFMutableArrayRef filtered = CFArrayCreateMutable(
      NULL, CFArrayGetCount(elements), &kCFTypeArrayCallBacks);
  for (CFIndex i = 0; i < CFArrayGetCount(elements); i++) {
    AXUIElementRef element = CFArrayGetValueAtIndex(elements, i);
    CFStringRef element_role = fcx_ui_inspector_copy_attribute_value(
        element, (CFStringRef)NSAccessibilityRoleAttribute);
    if (CFStringCompare(element_role, role, 0) == kCFCompareEqualTo) {
      CFArrayAppendValue(filtered, element);
    }
    CFRelease(element_role);
  }
  return filtered;
}

CFArrayRef fcx_ui_inspector_children_with_role(AXUIElementRef element,
                                               CFStringRef role) {
  CFArrayRef children = fcx_ui_inspector_copy_attribute_values(
      element, (CFStringRef)NSAccessibilityChildrenAttribute);
  if (!children) {
    return NULL;
  }
  if (CFArrayGetCount(children) == 0) {
    CFRelease(children);
    return NULL;
  }
  CFArrayRef filtered = fcx_ui_inspector_filter_by_role(children, role);
  CFRelease(children);
  return filtered;
}

struct json_object *
fcx_ui_inspector_menu_item_command(AXUIElementRef menu_item);

struct json_object *
fcx_ui_inspector_menu_items_commands(CFArrayRef menu_items) {
  struct json_object *list = json_object_new_array();

  for (CFIndex i = 0; i < CFArrayGetCount(menu_items); i++) {
    AXUIElementRef menu_item = CFArrayGetValueAtIndex(menu_items, i);
    struct json_object *command = fcx_ui_inspector_menu_item_command(menu_item);

    json_object_array_add(list, command);
  }

  return list;
}

struct json_object *
fcx_ui_inspector_menu_item_command(AXUIElementRef menu_item) {
  struct json_object *command = json_object_new_object();

  CFStringRef title = fcx_ui_inspector_copy_attribute_value(
      menu_item, (CFStringRef)kAXTitleAttribute);
  const char *title_str = [(NSString *)title UTF8String];
  if (title_str) {
    json_object_object_add(command, "name", json_object_new_string(title_str));
  }

  CFStringRef cmd_char = fcx_ui_inspector_copy_attribute_value(
      menu_item, (CFStringRef)kAXMenuItemCmdCharAttribute);
  CFStringRef cmd_virtual_key = fcx_ui_inspector_copy_attribute_value(
      menu_item, (CFStringRef)kAXMenuItemCmdVirtualKeyAttribute);
  CFNumberRef cmd_modifiers = fcx_ui_inspector_copy_attribute_value(
      menu_item, (CFStringRef)kAXMenuItemCmdModifiersAttribute);

  if (!cmd_char && !cmd_virtual_key) {
    NSLog(@"--> %@", title);
  } else {
    NSLog(@"%@\t%@ %@ %@", title, cmd_char, cmd_virtual_key, cmd_modifiers);
  }

  CFArrayRef sub_menus = fcx_ui_inspector_children_with_role(
      menu_item, (CFStringRef)NSAccessibilityMenuRole);

  if (sub_menus && CFArrayGetCount(sub_menus) > 0) {
    AXUIElementRef sub_menu = CFArrayGetValueAtIndex(sub_menus, 0);
    CFArrayRef sub_menu_items = fcx_ui_inspector_children_with_role(
        sub_menu, (CFStringRef)NSAccessibilityMenuItemRole);
    if (sub_menu_items && CFArrayGetCount(sub_menu_items) > 0) {
      struct json_object *commands =
          fcx_ui_inspector_menu_items_commands(sub_menu_items);
      json_object_object_add(command, "commands", commands);
    }
    if (sub_menu_items) {
      CFRelease(sub_menu_items);
    }
  }
  if (sub_menus) {
    CFRelease(sub_menus);
  }

  return command;
}

struct json_object *fcx_ui_inspector_app_commands(pid_t pid) {
  FCX_LOG_DEBUG("fcx_ui_inspector_menu_commands for pid %d (enabled: %d)", pid,
                fcx_ui_inspector_enabled());

  AXUIElementRef application = AXUIElementCreateApplication(pid);
  if (!application) {
    FCX_LOG_ERR("fcx_ui_inspector_menu_commands no application for pid %d",
                pid);
    return NULL;
  }

  CFArrayRef menu_bars = fcx_ui_inspector_children_with_role(
      application, (CFStringRef)NSAccessibilityMenuBarRole);
  if (!menu_bars || CFArrayGetCount(menu_bars) < 1) {
    FCX_LOG_ERR("fcx_ui_inspector_menu_commands no menu_bars for pid %d", pid);
    if (menu_bars) {
      CFRelease(menu_bars);
    }
    CFRelease(application);
    return NULL;
  }
  AXUIElementRef menu_bar = CFArrayGetValueAtIndex(menu_bars, 0);
  CFArrayRef menu_bar_items =
      fcx_ui_inspector_children_with_role(menu_bar, CFSTR("AXMenuBarItem"));
  if (!menu_bar_items || CFArrayGetCount(menu_bar_items) < 1) {
    FCX_LOG_ERR("fcx_ui_inspector_menu_commands no menu_bars for pid %d", pid);
    if (menu_bar_items) {
      CFRelease(menu_bar_items);
    }
    CFRelease(menu_bars);
    CFRelease(application);
    return NULL;
  }

  struct json_object *commands =
      fcx_ui_inspector_menu_items_commands(menu_bar_items);

  CFRelease(menu_bars);
  CFRelease(application);

  return commands;
}
