#include "test_dll.h"

Thing*   thingIface;
IPlugin* plugIface;

StringView pluginGetName(void* self)
{
    return (StringView){ .mPtr = "CPlug", .mLength = 5 };
}

StringView pluginGetVersion(void* self)
{
    return (StringView){ .mPtr = "0.1", .mLength = 3 };
}

void pluginApply(void* self, void* thing)
{
    thingIface->set__Value¨17D3665CE70(thing, thingIface->get__Value¨17D3665D070(thing) + 1);
}

int pluginApplyInt(void* self, int i)
{
    return i + 1;
}

IPlugin cplug = (IPlugin){.getName = &pluginGetName, .getVersion = &pluginGetVersion, .Apply¨17D366637F0 = &pluginApply, .Apply¨17D36662770 = &pluginApplyInt };

EXPORT bool plug_entry (HostInfo info, void** pluginPtr)
{
    thingIface = info.getInterface("Thing");
    plugIface  = info.getInterface("IPlugin");
    *pluginPtr = plugIface->__adapt((struct CollagenObject){.vtable=&cplug});

    return true;
}