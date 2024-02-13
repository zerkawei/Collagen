#include "test_dll.h"

Thing*   thingIface;
IPlugin* plugIface;

StringView pluginGetName(void* self)
{
    return (StringView){ .ptr = "CPlug", .len = 5 };
}

StringView pluginGetVersion(void* self)
{
    return (StringView){ .ptr = "0.1", .len = 3 };
}

void pluginApply(void* self, void* thing)
{
    thingIface->setValue(thing, thingIface->getValue(thing) + 1);
}

int pluginApplyInt(void* self, int i)
{
    return i + 1;
}

IPlugin cplug = (IPlugin){.getName = &pluginGetName, .getVersion = &pluginGetVersion, .apply = &pluginApply, .applyInt = &pluginApplyInt };

EXPORT bool plug_entry (HostInfo info, void** pluginPtr)
{
    thingIface = info.getInterface("Thing");
    plugIface  = info.getInterface("IPlugin");
    *pluginPtr = plugIface->adapt((Plugin){.interface=&cplug});

    return true;
}