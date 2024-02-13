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

			String name = scope .();
			if(m.GetCustomAttribute<CollagenNameAttribute>() case .Ok(let val))
			{
				name.Append(val.Name);
			}
			else
			{
				Collagen.MangleName(m, name);
			}

			Compiler.EmitTypeBody(type, scope $"{MethodAdapt(m, ..scope .(), name)};\n");
		}
	}

	[Comptime]
	public static void MethodAdapt(MethodInfo m, String string, String name)
	{
		let strs = scope MethodAdapter<T>(name);

		for(int i < m.ParamCount) strs.Box(m.GetParamType(i), m.GetParamName(i));
		strs.Adapt(m.ReturnType, m.Name, true);

		string.Append(strs);
	}
}