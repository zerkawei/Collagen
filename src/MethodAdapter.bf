using System;
namespace Collagen;

internal class MethodAdapter<T> 
{
	public String PreSign    { get; } = new .() ~ delete _;
	public String Signature  { get; } = new .() ~ delete _;
	public String BeforeCall { get; } = new .() ~ delete _;
	public String InCall     { get; } = new .() ~ delete _;
	public String AfterCall  { get; } = new .() ~ delete _;
	public String Call       { get; } = new .() ~ delete _;
	public StringView Name   { get; }

	public this(StringView name)
	{
		Name = name;
	}

	[Comptime]
	public void Box(Type type, StringView accessor, bool isReturn = false)
	{
		if(!isReturn)
		{
			Signature.Append(scope $"{type.GetFullName(.. scope .())} {accessor},");
			InCall.Append(",");
			{
				Collagen.Box!(type, InCall);
				InCall.Append(accessor);
			}
		}
		else
		{
			PreSign.Append(scope $"static {Collagen.TypeFor(type, .. scope:: . ())} {accessor}(void* __self");

			if(type != typeof(void))
			{
				Call.Append("let __callret = ");
				AfterCall.Append("return ");
				{
					Collagen.Box!(type, AfterCall);
					AfterCall.Append("__callret");
				}
				AfterCall.Append(";");
			}

			Call.Append(scope $"(({typeof(T).GetFullName(..scope .())})System.Internal.UnsafeCastToObject(__self)).{Name.StartsWith("get__") || Name.StartsWith("set__") ? Name.Substring(5) : Name}");
			if(Name.StartsWith("set__"))
			{
				Call.Append("=");
			}
			else if(!Name.StartsWith("get__"))
			{
				Call.Append("(");
				InCall.TrimEnd(',');
				InCall.Append(")");
			}
		}
	}

	[Comptime]
	public void Adapt(Type type, StringView accessor, bool isReturn = false)
	{
		if(!isReturn)
		{
			Signature.Append(scope $",{Collagen.TypeFor(type, .. scope .())} {accessor}");
			{
				Collagen.Adapt!(type, InCall);
				InCall.Append(accessor);
			}
			InCall.Append(",");
		}
		else
		{
			PreSign.Append(scope $"{type.GetFullName(.. scope .())} {accessor} (");

			if(type != typeof(void))
			{
				Call.Append("let __callret = ");
				AfterCall.Append("return ");
				{
					Collagen.Adapt!(type, AfterCall);
					AfterCall.Append("__callret");
				}
				AfterCall.Append(";");
			}

			Call.Append(scope $"((CollagenInterface<{typeof(T).GetFullName(.. scope .())}>*)Object.VTable).{Name}(Object.Ptr");
			InCall.Append(")");
		}
	}

	public override void ToString(String strBuffer)
	{
		strBuffer.Append("public ");
		strBuffer.Append(PreSign);
		Signature.TrimEnd(',');
		strBuffer.Append(Signature);
		strBuffer.Append(")");
		
		strBuffer.Append("\n{\n");
		strBuffer.Append(BeforeCall);
		strBuffer.Append("\n");

		strBuffer.Append(Call);
		InCall.TrimEnd(',');
		strBuffer.Append(InCall);
		strBuffer.Append(";\n");

		strBuffer.Append(AfterCall);
		strBuffer.Append("\n}");
	}
}
