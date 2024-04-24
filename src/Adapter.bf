using System;
using System.Reflection;
using internal Collagen;
namespace Collagen;

public class CollagenAdapter<T> where T : interface
{
	public CollagenObject<T> Object { get; }

	internal this(CollagenObject<T> object) { Object = object; }

	[Comptime, OnCompile(.TypeInit)]
	public static void OnTypeInit()
	{
		let type = typeof(Self);
		Compiler.EmitAddInterface(type, typeof(T));

		for(let m in typeof(T).GetMethods())
		{
			if(m.Name.IsEmpty || m.IsStatic) continue;
			Compiler.EmitTypeBody(type, scope $"{CollagenMethods.Adapt(m, .. scope .())};\n");
		}
	}
}