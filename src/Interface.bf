using System;
using System.Reflection;
using System.IO;
using internal Collagen;
namespace Collagen;

[CRepr]
public struct CollagenInterface<T>
{
	public static Self* Default = new .() ~ delete _;

	[Comptime, OnCompile(.TypeInit)]
	public static void OnTypeInit()
	{
		let type = typeof(Self);
		bool foreignImplAllowed = typeof(T).GetCustomAttribute<AllowForeignImplementationAttribute>() case .Ok;
		let methods = typeof(T).GetMethods();

		let ctor = scope String("public this{ ");
		let body = scope String();

		if(foreignImplAllowed)
		{
			ctor.Append("__adapt = => def____adapt;");
			body.Append(scope $"public function void*(CollagenObject<{typeof(T).GetFullName(.. scope .())}>) __adapt;");
			body.Append(scope $"public static void* def____adapt(CollagenObject<{typeof(T).GetFullName(.. scope .())}> obj) => System.Internal.UnsafeCastToPtr(new CollagenAdapter<{typeof(T).GetFullName(.. scope .())}>(obj));\n");
		}

		for(let m in methods)
		{
			if(m.Name.IsEmpty || (m.IsConstructor && !m.DeclaringType.IsValueType) || m.IsDestructor || !m.IsPublic || m.DeclaringType != typeof(T) || m.GenericArgCount > 0 || m.IsMixin) continue;

			String name = scope .();
			CollagenMethods.GetCollagenName(m, name);

			ctor.Append(scope $"{name} = => def__{name}; ");
			body.Append(scope $"public function {Collagen.TypeFor(m.ReturnType, ..scope .())}(");

			if(!m.IsStatic)
			{
				if(m.DeclaringType.IsValueType)
				{
					body.Append(m.DeclaringType.GetFullName(.. scope .()));
				}
				else
				{
					body.Append("void");
				}
				body.Append("*");
			}
			for(int i < m.ParamCount)
			{
				if(i > 0 || !m.IsStatic)
				{
					body.Append(", ");
				}
				body.Append(scope $"{Collagen.TypeFor(m.GetParamType(i), ..scope .())}");

			}
			body.Append(scope $") {name};\n{CollagenMethods.DefaultInterface(m, .. scope .())};\n");
		}

		ctor.Append("};\n");

		Compiler.EmitTypeBody(type, ctor);
		Compiler.EmitTypeBody(type, body);
	}
}