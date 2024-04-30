using System;
using System.Reflection;
using internal Collagen;
namespace Collagen;

internal static class CollagenMethods
{
	private enum MethodType
	{
		Method,
		PropertySet,
		PropertyGet,
		IndexerSet,
		IndexerGet
	}

	[Comptime]
	private static mixin Box(Type type, String string)
	{
		let typeStr = Collagen.TypeFor(type, .. scope:: .());
		if(type.IsValueType || (type.IsPointer && type.UnderlyingType.IsPrimitive))
		{
			string.Append("(.)");
		}
		else if(type is RefType)
		{
			string.Append(scope $"(.)&");
		}
		else
		{
			string.Append(scope $"({typeStr})System.Internal.UnsafeCastToPtr(");
			defer:mixin string.Append(")");
		}
	}

	[Comptime]
	private static mixin Adapt(Type type, String string)
	{
		let typeStr = type.GetFullName(.. scope:: .());
		if(type.IsValueType || (type.IsPointer && type.UnderlyingType.IsPrimitive))
		{
			string.Append("(.)");
		}
		else if(type is RefType)
		{
			let refType = type as RefType;
			switch(refType.RefKind)
			{
			case .In:
				string.Append("in ");
			case .Out:
				string.Append("out ");
			case .Ref:
				string.Append("ref ");
			case .Mut:
				string.Append("mut ");
			}
			string.Append(scope $"*({refType.UnderlyingType.GetFullName(.. scope .())}*)");
		}
		else
		{
			string.Append(scope $"({typeStr})System.Internal.UnsafeCastToObject(");
			defer:mixin string.Append(")");
		}
	}

	[Comptime]
	public static void DefaultInterface(MethodInfo method, String str)
	{
		StringView accessor;
		MethodType type;
		
		if(method.Name.StartsWith("set__"))
		{
			type     = (method.Name.Length == 5) ? .IndexerSet : .PropertySet;
			accessor = method.Name.Substring(5);
		}
		else if(method.Name.StartsWith("get__"))
		{
			type     = (method.Name.Length == 5) ? .IndexerGet : .PropertyGet;
			accessor = method.Name.Substring(5);
		}
		else
		{
			type     = .Method;
			accessor = method.Name; 
		}

		str.Append(scope $"public static {Collagen.TypeFor(method.ReturnType, .. scope .())} def__{GetCollagenName(method, .. scope .())}(");
		if(!method.IsStatic)
		{
			str.Append("void* __self");
		}
		for(int i < method.ParamCount)
		{
			if(i > 0 || !method.IsStatic)
			{
				str.Append(", ");
			}
			str.Append(scope $"{Collagen.TypeFor(method.GetParamType(i), .. scope .())} {method.GetParamName(i)}");
		}
		str.Append(")\n{\n");

		if(method.ReturnType != typeof(void))
		{
			str.Append("let __callret = ");
		}

		if(method.IsStatic)
		{
			str.Append("T");
		}
		else if(method.DeclaringType.IsValueType)
		{
			str.Append(scope $"(*(({method.DeclaringType.GetFullName(.. scope .())}*)__self))");
		}
		else
		{
			str.Append(scope $"(({method.DeclaringType.GetFullName(.. scope .())})System.Internal.UnsafeCastToObject(__self))");
		}

		str.Append((type <= .PropertyGet) ? "." : "[");
		str.Append(accessor);

		if(type == .Method)
		{
			str.Append("(");
		}

		for(int i = ((int)type%2); i < method.ParamCount; i++)
		{
			{
				Adapt!(method.GetParamType(i), str);
				str.Append(method.GetParamName(i));
			}
			if(i < method.ParamCount - 1)
			{
				str.Append(", ");
			}
		}

		if(type == .Method)
		{
			str.Append(")");
		}
		else if(type >= .IndexerSet)
		{
			str.Append("]");
		}

		if(((int)type%2) == 1) // Setters
		{
			str.Append(" = ");
			Adapt!(method.GetParamType(0), str);
			str.Append(method.GetParamName(0));
		}

		str.Append(";");

		if(method.ReturnType != typeof(void))
		{
			str.Append("\nreturn ");
			{
				Box!(method.ReturnType, str);
				str.Append("__callret");
			}
			str.Append(";");
		}

		str.Append("\n}");
	}

	[Comptime]
	public static void Adapt(MethodInfo method, String str)
	{
		str.Append(scope $"public {method.ReturnType.GetFullName(.. scope .())} {method.Name}({method.GetParamsDecl(.. scope .())})\n\{\n");

		for(int i = 0; i < method.ParamCount; i++)
		{
			if(method.GetParamType(i) is RefType && (method.GetParamType(i) as RefType).RefKind == .Out)
			{
				str.Append(scope $"{method.GetParamName(i)} = ?;\n"); 
			}
		}

		if(method.ReturnType != typeof(void))
		{
			str.Append("let __callret = ");
		}

		str.Append(scope $"((CollagenInterface<{method.DeclaringType.GetFullName(.. scope .())}>*)Object.VTable).{GetCollagenName(method, .. scope .())}(Object.Ptr");

		for(int i = 0; i < method.ParamCount; i++)
		{
			str.Append(", ");
			Box!(method.GetParamType(i), str);
			str.Append(method.GetParamName(i));
		}

		str.Append(");");

		if(method.ReturnType != typeof(void))
		{
			str.Append("\nreturn ");
			{
				Adapt!(method.ReturnType, str);
				str.Append("__callret");
			}
			str.Append(";");
		}

		str.Append("\n}");
	}

	[Comptime]
	public static void GetCollagenName(MethodInfo m, String string)
	{
		if(m.GetCustomAttribute<CollagenNameAttribute>() case .Ok(let name))
		{
			string.Append(name.Name);
		}
		else
		{
			// Create unique name per method instance
			string.Append(scope $"{m.Name}¨{m.[Friend]mData.mComptimeMethodInstance.ToString(.. scope .(), "X", null)}");
		}
	}
}
