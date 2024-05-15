using Collagen;
using System;
using System.IO;

namespace System
{
	[APICast(typeof(CRepr<StringView>))]
	public extension StringView {}
}

namespace CollagenTest;

[AllowForeignImplementation, CollagenName("IPlugin")]
public interface IPlugin
{
	public StringView Name    { [CollagenName("getName")]get; }
	public StringView Version { [CollagenName("getVersion")]get; }

	public void Apply(Thing t);
	public int  Apply(int i);
}

[CollagenName("Thing")]
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

public class GenerateHeader
{
	public static void Main()
	{
		File.WriteAllText("collagentest.h", CollagenHeader.Create(typeof(Thing), typeof(IPlugin)));
	}
}

public class Program
{
	public static void Main()
	{
		Collagen.Export<Thing>();
		Collagen.Export<IPlugin>();

		let thing = scope Thing();
		thing.Value = 1;
		if(LoadPlugin("plugin.dll") case .Ok(let plugin))
		{
			Console.WriteLine(scope $"Successfully loaded {plugin.Name} v{plugin.Version}");
			plugin.Apply(thing);
			Console.WriteLine(thing.Value);
		}
		Console.Read();
	}

	public static Result<IPlugin> LoadPlugin(StringView path)
	{
		let plug = Windows.LoadLibraryA(Path.GetAbsolutePath(path, Directory.GetCurrentDirectory(.. scope .()) ,.. scope .()).Ptr);
		if(plug == null) return .Err;
		PluginEntry entry = (.)Windows.GetProcAddress(plug, "plug_entry");
		if(entry == null) return .Err;
		void** outPtr = scope .();
		if(!entry(.(=> Collagen.GetInterface), outPtr)) return .Err;
 		return .Ok((.)Internal.UnsafeCastToObject(*outPtr));
	}
}