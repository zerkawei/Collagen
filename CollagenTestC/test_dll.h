#include <stdbool.h>

#define EXPORT __declspec(dllexport)

typedef struct _Plugin Plugin;

typedef struct _HostInfo
{
    void*(*getInterface)(char*);
} HostInfo;

typedef struct _StringView
{
    char* ptr;
    int   len;
} StringView;

EXPORT bool plug_entry (HostInfo, void**);

typedef struct PluginInterface
{
    void*(*adapt)(Plugin);
    StringView(*getName)(void*);
    StringView(*getVersion)(void*);
    void(*apply)(void*, void*);
} IPlugin;

struct _Plugin
{
    IPlugin* interface;
    void*    ptr;
};

typedef struct ThingInterface
{
    int(*getValue)(void*);
    void(*setValue)(void*, int);
} Thing;
