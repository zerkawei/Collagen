using System;
using System.Collections;
using System.Reflection;
namespace Collagen;

[AttributeUsage(.Interface)]
public struct AllowForeignImplementationAttribute : Attribute {}

[AttributeUsage(.Method)]
public struct CollagenNameAttribute : Attribute
{
	public StringView Name;
	public this(StringView name) {Name = name;}
}

[CRepr] public struct CReprStringView : StringView { public this(StringView _) : base(_) {} public static implicit operator CReprStringView(StringView _) => .(_); }

public static class Collagen
{
	public static Dictionary<StringView, void*> ExportedInterfaces = new .() ~ delete _;
	public static void* GetInterface(char8* symbol)
	{
		if(ExportedInterfaces.TryGet(.(symbol), let _, let iface))
		{
			return iface;
		}
		return null;
	}

	[Comptime]
	public static void TypeFor(Type type, String string)
	{
		if(type.IsPrimitive || type.IsStruct)
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

	[Comptime]
	public static mixin Box(Type type, String string)
	{
		let typeStr = Collagen.TypeFor(type, .. scope:: .());
		if(type.IsEnum)
		{
			string.Append(scope $"({typeStr})");
		}
		else if(type == typeof(StringView))
		{
			string.Append("(CReprStringView)");
		}
		else if(!type.IsPrimitive)
		{
			string.Append("System.Internal.UnsafeCastToPtr(");
			defer:mixin string.Append(")");
		}
	}

	[Comptime]
	public static mixin Adapt(Type type, String string)
	{
		let typeStr = type.GetFullName(.. scope:: .());
		if(type.IsEnum)
		{
			string.Append(scope $"({typeStr})");
		}
		else if(type == typeof(StringView))
		{
			string.Append("(StringView)");
		}
		else if(!type.IsPrimitive)
		{
			string.Append(scope $"({typeStr})System.Internal.UnsafeCastToObject(");
			defer:mixin string.Append(")");
		}
	}

	[Comptime]
	public static void MangleName(MethodInfo m, String string)
	{
		String args = scope .();
		for(int i < m.ParamCount) args.Append(m.GetParamType(i).GetFullName(.. scope .()));
		string.Append(scope String(m.Name), "¨",  args.GetHashCode().ToString(.. scope .(), "X", null));
	}
}

