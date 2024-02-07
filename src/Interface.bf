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
		StringView[] forbbiden = scope .[]("IsDeleted", "GetType", "DynamicCastToTypeId", "DynamicCastToInterface", "ToString");

		let type = typeof(Self);
		bool foreignImplAllowed = typeof(T).GetCustomAttribute<AllowForeignImplementationAttribute>() case .Ok;

		Compiler.EmitTypeBody(type, scope $"public this(void* _)\{ ");

		let methods = typeof(T).GetMethods();
		for(let m in methods)
		{
			if(m.Name.IsEmpty || m.IsConstructor || m.IsDestructor || !m.IsPublic || forbbiden.Contains(m.Name)) continue;
			Compiler.EmitTypeBody(type, scope $"{m.Name} = => def__{m.Name}; ");
		}
		if(foreignImplAllowed)
		{
			Compiler.EmitTypeBody(type, "__adapt = => def____adapt;");
		}
		Compiler.EmitTypeBody(type, "};\n");

		if(foreignImplAllowed)
		{
			Compiler.EmitTypeBody(type, scope $"public function void*(CollagenObject<{typeof(T).GetFullName(.. scope .())}>) __adapt;");
			Compiler.EmitTypeBody(type, scope $"public static void* def____adapt(CollagenObject<{typeof(T).GetFullName(.. scope .())}> obj) => System.Internal.UnsafeCastToPtr(new CollagenAdapter<{typeof(T).GetFullName(.. scope .())}>(obj));\n");
		}

		for(let m in methods)
		{
			if(m.Name.IsEmpty || m.IsConstructor || m.IsDestructor || !m.IsPublic || forbbiden.Contains(m.Name)) continue;

			Compiler.EmitTypeBody(type, scope $"public function {Collagen.TypeFor(m.ReturnType, ..scope .())}(void*");
			for(int i < m.ParamCount)
			{
				Compiler.EmitTypeBody(type, scope $", {Collagen.TypeFor(m.GetParamType(i), ..scope .())}");
			}
			Compiler.EmitTypeBody(type, scope $") {m.Name};\n");
			Compiler.EmitTypeBody(type, scope $"{DefaultMethod(m, ..scope .())};\n");
		}
	}

	[Comptime]
	private static void DefaultMethod(MethodInfo m, String string)
	{
		let strs = scope MethodAdapter<T>(m.Name);

		for(int i < m.ParamCount) strs.Adapt(m.GetParamType(i), m.GetParamName(i));
		strs.Box(m.ReturnType, scope $"def__{m.Name}", true);

		string.Append(strs);
	}
}