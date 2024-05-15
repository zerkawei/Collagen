#include <stdbool.h>
#include "collagentest.h"

#define EXPORT __declspec(dllexport)

typedef struct CollagenTest_IPlugin_i IPlugin;
typedef struct Collagen_CReprgSystem_StringViewc StringView;
typedef struct CollagenTest_Thing_i Thing;

typedef struct _HostInfo
{
    void*(*getInterface)(char*);
} HostInfo;

EXPORT bool plug_entry (HostInfo, void**);