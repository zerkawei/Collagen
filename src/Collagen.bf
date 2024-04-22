namespace System
{
	using Collagen;
	[APICast(typeof(CReprStringView))] public extension StringView {}
	[APICast(typeof(CReprVariant))]    public extension Variant    {}
}

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

[AttributeUsage(.Struct)]
public struct APICastAttribute : Attribute
{
	public Type Target;
	public this(Type target) {Target = target;}
}

[CRepr] public struct CReprStringView : StringView { public this(StringView _) : base(_) {} public static implicit operator CReprStringView(StringView _) => .(_); }
[CRepr] public struct CReprVariant : Variant
{
	public this(Variant v)
	{
		this.[Friend]mData       = v.[Friend]mData;
		this.[Friend]mStructType = v.[Friend]mStructType;
	}

	public static implicit operator CReprVariant(Variant _) => .(_);
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

	public static void Export   (StringView name, void* iface) => ExportedInterfaces.Add(name, iface);
	public static void Export<T>(StringView	name)              => ExportedInterfaces.Add(name, CollagenInterface<T>.Default);
	[Inline]
	public static void Export<T>()                             => Export<T>(TypeName<T>());

	[Comptime(ConstEval=true)]
	private static var TypeName<T>() => typeof(T).GetFullName(.. scope .());

	[Comptime]
	internal static void TypeFor(Type type, String string)
	{
		if(type.GetCustomAttribute<APICastAttribute>() case .Ok(let att))
		{
			att.Target.GetFullName(string);
		}
		else if(type.IsValueType && !type.IsEnum)
		{
			type.GetFullName(string);
		}
		else if(type.IsEnum)
		{
			if(type.IsUnion)
			{
				type.GetFullName(string);
			}
			else
			{
				type.UnderlyingType.GetFullName(string);
			}
		}
		else
		{
			string.Append("void*");
		}
	}
}

