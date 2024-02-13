using System;
using System.Reflection;
using System.IO;
using internal Collagen;
namespace Collagen;

[CRepr]
public struct CollagenInterface<T>
{
	public static Self* Default = new .(null) ~ delete _;

	[Comptime, OnCompile(.TypeInit)]
	public static void OnTypeInit()
	{
		let type = typeof(Self);
		bool foreignImplAllowed = typeof(T).GetCustomAttribute<AllowForeignImplementationAttribute>() case .Ok;
		let methods = typeof(T).GetMethods();

		let ctor = scope String("public this(void* _){ ");
		let body = scope String();

		if(foreignImplAllowed)
		{
			ctor.Append("__adapt = => def____adapt;");
			body.Append(scope $"public function void*(CollagenObject<{typeof(T).GetFullName(.. scope .())}>) __adapt;");
			body.Append(scope $"public static void* def____adapt(CollagenObject<{typeof(T).GetFullName(.. scope .())}> obj) => System.Internal.UnsafeCastToPtr(new CollagenAdapter<{typeof(T).GetFullName(.. scope .())}>(obj));\n");
		}

		for(let m in methods)
		{
			if(m.Name.IsEmpty || m.IsConstructor || m.IsDestructor || !m.IsPublic || m.DeclaringType == typeof(Object)) continue;

			String name = scope .();
			if(m.GetCustomAttribute<CollagenNameAttribute>() case .Ok(let val))
			{
				name.Append(val.Name);
			}
			else
			{
				Collagen.MangleName(m, name);
			}

			ctor.Append(scope $"{name} = => def__{name}; ");
			body.Append(scope $"public function {Collagen.TypeFor(m.ReturnType, ..scope .())}(void*");
			for(int i < m.ParamCount)
			{
				body.Append(scope $", {Collagen.TypeFor(m.GetParamType(i), ..scope .())}");
			}
			body.Append(scope $") {name};\n{DefaultMethod(m, ..scope .(), name)};\n");
		}

		ctor.Append("};\n");

		Compiler.EmitTypeBody(type, ctor);
		Compiler.EmitTypeBody(type, body);
	}

	[Comptime]
	private static void DefaultMethod(MethodInfo m, String string, String name)
	{
		let strs = scope MethodAdapter<T>(m.Name);

		for(int i < m.ParamCount) strs.Adapt(m.GetParamType(i), m.GetParamName(i));
		strs.Box(m.ReturnType, scope $"def__{name}", true);

		string.Append(strs);
	}
}