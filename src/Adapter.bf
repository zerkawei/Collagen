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
			if(m.Name.IsEmpty) continue;
			Compiler.EmitTypeBody(type, scope $"{MethodAdapt(m, ..scope .())};\n");
		}
	}

	[Comptime]
	public static void MethodAdapt(MethodInfo m, String string)
	{
		let strs = scope MethodAdapter<T>(m.Name);

		for(int i < m.ParamCount) strs.Box(m.GetParamType(i), m.GetParamName(i));
		strs.Adapt(m.ReturnType, m.Name, true);

		string.Append(strs);
	}
}