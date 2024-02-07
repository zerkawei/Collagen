using Collagen;
using System;
namespace CollagenTest;

[AllowForeignImplementation]
public interface IPlugin
{
	public StringView Name    { get; }
	public StringView Version { get; }

	public void Apply(Thing t);
}

public class Thing
{
	public int Value { get; set; }
}

typealias PluginEntry = function bool(HostInformation, void**);

[CRepr]
public struct HostInformation
{
	public this(function void*(char8*) gi) { GetInterface = gi; }
	public function void*(char8*) GetInterface;
} 

public class Program
{
	public static void Main()
	{
		Collagen.ExportedInterfaces.Add("Thing", CollagenInterface<Thing>.Default);
		Collagen.ExportedInterfaces.Add("IPlugin", CollagenInterface<IPlugin>.Default);

		let thing = scope Thing();
		thing.Value = 1;
		if(LoadPlugin("plugin.dll") case .Ok(let plugin))
		{
			Console.WriteLine(scope $"Successfully loaded {plugin.Name} v{plugin.Version}");
			plugin.Apply(thing);
			Console.WriteLine(thing.Value);
		}
	}

	public static Result<IPlugin> LoadPlugin(StringView path)
	{
		let plug = Internal.LoadSharedLibrary(path.Ptr);
		if(plug == null) return .Err;
		PluginEntry entry = (.)Internal.GetSharedProcAddress(plug, "plug_entry");
		if(entry == null) return .Err;
		void** outPtr = scope .();
		if(!entry(.(=> Collagen.GetInterface), outPtr)) return .Err;
 		return .Ok((.)Internal.UnsafeCastToObject(*outPtr));
	}
}