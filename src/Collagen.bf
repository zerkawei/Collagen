using System;
using System.Collections;
using System.Reflection;
using System.IO;
using internal Collagen;
namespace Collagen;

[AttributeUsage(.Interface)]
public struct AllowForeignImplementationAttribute : Attribute {}

[AttributeUsage(.Method)]
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

[AttributeUsage(.Types)]
public struct CollagenExportAttribute : Attribute
{
	public StringView Name;
	public this(StringView name = "") { Name = name; }
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
			Compiler.EmitTypeBody(self, scope $"{Collagen.TypeFor(f.FieldType, .. scope .())} {Collagen.FieldName(f, .. scope .())};\n");
		}

		Compiler.EmitTypeBody(self, scope $"this({target.GetFullName(.. scope .())} val)\n\{\n");
		for(let f in target.GetFields())
		{
			Compiler.EmitTypeBody(self, scope $"this.{Collagen.FieldName(f, .. scope .())} = ");
			String access = scope .();
			{
				CollagenMethods.[Friend]Box!(f.FieldType, access);
				access.Append(scope $"val.{Collagen.FieldAccess(f, .. scope .())}");
			}
			access.Append(";\n");
			Compiler.EmitTypeBody(self, access);
		}
		Compiler.EmitTypeBody(self, "}\n");

		Compiler.EmitTypeBody(self, scope $"public static implicit operator Self({target.GetFullName(.. scope .())} _) => .(_);\n");

		Compiler.EmitTypeBody(self, scope $"public static implicit operator {target.GetFullName(.. scope .())}(Self _) \n\{\n{target.GetFullName(.. scope .())} val = ?;\n");
		for(let f in target.GetFields())
		{
			Compiler.EmitTypeBody(self, scope $"val.{Collagen.FieldAccess(f, .. scope .())} = ");
			String access = scope .();
			{
				CollagenMethods.[Friend]Adapt!(f.FieldType, access);
				access.Append(scope $"_.{Collagen.FieldName(f, .. scope .())}");
			}
			access.Append(";\n");
			Compiler.EmitTypeBody(self, access);
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

	public static void Export(StringView name, void* iface) => ExportedInterfaces.Add(name, iface);

	[Comptime]
	internal static void FieldName(FieldInfo f, String string)
	{
		if(f.Name[0].IsDigit) string.Append("_");
		string.Append(f.Name);
	}

	[Comptime]
	internal static void FieldAccess(FieldInfo f, String string)
	{
		if(!f.IsPublic) string.Append("[Friend]");
 		string.Append(f.Name);
	}

	[Comptime]
	internal static void TypeFor(Type type, String string)
	{
		int starCount = 0;
		GetExportedTypeOf(type, ref starCount).GetFullName(string);
		string.Append('*', starCount);
	}

	[Comptime]
	internal static Type GetExportedTypeOf(Type type, ref int starCount)
	{
		if(type.GetCustomAttribute<APICastAttribute>() case .Ok(let att))
		{
			return att.Target;
		}
		if(type.IsValueType || (type.IsEnum && type.IsUnion))
		{
			return type;
		}
		if(type.IsEnum)
		{
			return type.UnderlyingType;
		}

		starCount = 1;
		if(type is RefType || type.IsPointer && type.UnderlyingType.IsPrimitive)
		{
			return type.UnderlyingType;
		}
		return typeof(void);
	}

	[Comptime, OnCompile(.TypeInit)]
	static void GenerateExports()
	{
		Compiler.EmitTypeBody(typeof(Self), "static this\n{\n");
		for(let t in TypeDeclaration.TypeDeclarations)
		{
			if(t.GetCustomAttribute<CollagenExportAttribute>() case .Ok(let export))
			{
				Compiler.EmitTypeBody(typeof(Self), scope $"Collagen.Export(\"{export.Name.Length > 0 ? export.Name : t.GetFullName(.. scope .())}\", CollagenInterface<comptype({(int)t.TypeId})>.Default);\n");
			}
		}
		Compiler.EmitTypeBody(typeof(Self), "}");
	}

#if COLLAGEN_HEADER_GEN
	[Comptime, OnCompile(.TypeDone)]
	static void GenerateHeader()
	{
		List<Type> types = scope .();
		for(let t in TypeDeclaration.TypeDeclarations)
		{
			if(t.HasCustomAttribute<CollagenExportAttribute>())
			{
				types.Add(t.ResolvedType);
			}
		}

		if(types.Count > 0)
		{
			File.WriteAllText("collagen.h", CollagenHeader.Create(types.CopyTo(.. scope:: Type[types.Count])));
		}
	}
#endif
}

