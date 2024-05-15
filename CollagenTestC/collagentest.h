#pragma once
#include <stdint.h>
#include <stddef.h>

struct CollagenObject {
  void* vtable;
  void* data;
};

struct CollagenTest_Thing_i {
  intptr_t (*get__Value¨17D3665D070)(void* __self);
  void (*set__Value¨17D3665CE70)(void* __self, intptr_t value);
};

struct CollagenTest_IPlugin_i {
  void*(*__adapt)(struct CollagenObject);
  struct Collagen_CReprgSystem_StringViewc (*getName)(void* __self);
  struct Collagen_CReprgSystem_StringViewc (*getVersion)(void* __self);
  void (*Apply¨17D366637F0)(void* __self, void* t);
  intptr_t (*Apply¨17D36662770)(void* __self, intptr_t i);
};

struct Collagen_CReprgSystem_StringViewc {
  char* mPtr;
  intptr_t mLength;
};

