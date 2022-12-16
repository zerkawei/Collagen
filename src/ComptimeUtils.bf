using System;
namespace Collagen;

internal static class ComptimeUtils
{
	[Comptime]
	public static void TypeFor(Type type, String string)
	{
		if(type.IsPrimitive)
		{
			type.GetFullName(string);
		}
		else if(type.IsEnum)
		{
			type.UnderlyingType.GetFullName(string);
		}
		else
		{
			string.Append("CollagenObject");
		}
	}

	[Comptime]
	public static mixin Box(Type type, String string)
	{
		if(type.IsEnum)
		{
			string.Append(scope $"({type.UnderlyingType.GetFullName(..scope .())})");
		}
		else if(!type.IsPrimitive)
		{
			string.Append(scope $"CollagenAdapter.Box<{type.GetFullName(..scope .())}>(");
			defer:: string.Append(")");
		}	
	}

	[Comptime]
	public static mixin Adapt(Type type, String string)
	{
		if(type.IsEnum)
		{
			string.Append(scope $"({type.GetFullName(..scope .())})");
		}
		else if(!type.IsPrimitive)
		{
			string.Append(scope $"CollagenAdapter.Adapt<{type.GetFullName(..scope .())}>(");
			defer:: string.Append(")");
		}	
	}
}