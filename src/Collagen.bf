using System;
using System.Collections;
using System.Reflection;
using internal Collagen;
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

	[Inline]
	public static void Export<T>() => Export(TypeName<T>(), CollagenInterface<T>.Default);
	public static void Export (StringView name, void* iface) => ExportedInterfaces.Add(name, iface);

	[Comptime(ConstEval=true)]
	private static String TypeName<T>() => typeof(T).GetCustomAttribute<CollagenNameAttribute>() case .Ok(let att) ? scope .(att.Name) : typeof(T).GetFullName(.. scope .());

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
	internal static void CTypeFor(Type type, String string)
	{
		int starCount = 0;
		let t = GetExportedTypeOf(type, ref starCount);
		switch(t)
		{
		case typeof(bool):
			string.Append("bool");
		case typeof(int16):
			string.Append("short");
		case typeof(uint16):
			string.Append("unsinged short");
		case typeof(int32):
			string.Append("int");
		case typeof(uint32):
			string.Append("unsigned int");
		case typeof(int64):
			string.Append("long long");
		case typeof(uint64):
			string.Append("unsigned long long");
		case typeof(int):
			string.Append("intptr_t");
		case typeof(uint):
			string.Append("uintptr_t");
		case typeof(uint):
			string.Append("size_t");
		case typeof(int8) : fallthrough;
		case typeof(char8):
			string.Append("char");
		case typeof(uint8):
			string.Append("unsigned char");

#if BF_PLATFORM_WINDOWS
		case typeof(char16):
			string.Append("wchar_t");
#else
		case typeof(char32):
			string.Append("wchar_t");
#endif

		case typeof(float):
			string.Append("float");
		case typeof(double):
			string.Append("double");
		case typeof(void):
			string.Append("void");

		default:
			if(type.IsStruct)
			{
				string.Append("struct ");
				string.Append(t.GetFullName(.. scope .()).Replace('.', '_'));
			}
		}

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
}

