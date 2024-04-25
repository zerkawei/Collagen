using System;
using System.Collections;
using System.Reflection;
namespace Collagen;

[AttributeUsage(.Interface)]
public struct AllowForeignImplementationAttribute : Attribute {}

[AttributeUsage(.Method | .Types)]
public struct CollagenNameAttribute : Attribute
{
	public StringView Name;
	public this(StringView name) {Name = name;}
}

[AttributeUsage(.Struct)]
public struct APICastAttribute : Attribute
{
	public Type Target;
	public this(Type target) {Target = target;}
}

[CRepr]
public struct CRepr<T> where T : struct
{
	[Comptime, OnCompile(.TypeInit)]
	public static void Generate()
	{
		let self   = typeof(Self);
		let target = typeof(T);
		for(let f in target.GetFields())
		{
			Compiler.EmitTypeBody(self, scope $"{f.FieldType.GetFullName(.. scope .())} {f.Name};\n");
		}

		Compiler.EmitTypeBody(self, scope $"this({target.GetFullName(.. scope .())} val)\n\{\n");
		for(let f in target.GetFields())
		{
			Compiler.EmitTypeBody(self, scope $"this.{f.Name} = val.[Friend]{f.Name};\n");
		}
		Compiler.EmitTypeBody(self, "}\n");

		Compiler.EmitTypeBody(self, scope $"public static implicit operator Self({target.GetFullName(.. scope .())} _) => .(_);\n");

		Compiler.EmitTypeBody(self, scope $"public static implicit operator {target.GetFullName(.. scope .())}(Self _) \n\{\n{target.GetFullName(.. scope .())} val = ?;\n");
		for(let f in target.GetFields())
		{
			Compiler.EmitTypeBody(self, scope $"val.[Friend]{f.Name} = _.{f.Name};\n");
		}
		Compiler.EmitTypeBody(self,"return val;\n}");
	}
}

public static class Collagen
{
	private static Dictionary<StringView, void*> ExportedInterfaces = new .() ~ delete _;
	public static void* GetInterface(char8* symbol)
	{
		if(ExportedInterfaces.TryGet(.(symbol), let _, let iface))
		{
			return iface;
		}
		return null;
	}

	[Inline]
	public static void Export<T>() => Export(TypeName<T>(), CollagenInterface<T>.Default);
	public static void Export (StringView name, void* iface) => ExportedInterfaces.Add(name, iface);

	[Comptime(ConstEval=true)]
	private static String TypeName<T>() => typeof(T).GetCustomAttribute<CollagenNameAttribute>() case .Ok(let att) ? scope .(att.Name) : typeof(T).GetFullName(.. scope .());

	[Comptime]
	internal static void TypeFor(Type type, String string)
	{
		if(type.GetCustomAttribute<APICastAttribute>() case .Ok(let att))
		{
			att.Target.GetFullName(string);
		}
		else if(type.IsStruct && type.GetCustomAttribute<CReprAttribute>() case .Err)
		{
			string.Append(scope $"CRepr<{type.GetFullName(.. scope .())}>");
		}
		else if(type.IsValueType || (type.IsEnum && type.IsUnion))
		{
			type.GetFullName(string);
		}
		else if(type.IsEnum)
		{
			type.UnderlyingType.GetFullName(string);
		}
		else
		{
			string.Append("void*");
		}
	}
}

