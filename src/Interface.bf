using System;
using System.Reflection;
namespace Collagen;

[CRepr]
public struct CollagenObject
{
	public CollagenInterface* Type;
	public void*              Ptr;
	public this(CollagenInterface* type, void* ptr) { Type = type; Ptr = ptr; }
}

[CRepr]
public struct CollagenInterface { public uint64 typeID; }

[AttributeUsage(.Struct)]
public struct CollagenInterfaceAttribute<T> : Attribute, IOnTypeInit where T : interface
{
	[Comptime]
	public void OnTypeInit(Type type, Self* prev)
	{
		Compiler.EmitTypeBody(type, "public this(uint64 id) { typeID = id; ");

		let methods = typeof(T).GetMethods();
		for(let m in methods)
		{
			if(m.Name.IsEmpty) continue;
			Compiler.EmitTypeBody(type, scope $"{m.Name} = => def__{m.Name}; ");
		}
		Compiler.EmitTypeBody(type, "}\n");

		for(let m in methods)
		{
			if(m.Name.IsEmpty) continue;
			Compiler.EmitTypeBody(type, scope $"public function {ComptimeUtils.TypeFor(m.ReturnType, ..scope .())}(void*");
			for(int i < m.ParamCount)
			{
				Compiler.EmitTypeBody(type, scope $", {ComptimeUtils.TypeFor(m.GetParamType(i), ..scope .())}");
			}
			Compiler.EmitTypeBody(type, scope $") {m.Name};\n");
		}

		for(let m in methods)
		{
			Compiler.EmitTypeBody(type, scope $"{DefaultMethod(m, ..scope .())};\n");
		}
	}

	[Comptime]
	private static void DefaultMethod(MethodInfo m, String string)
	{
		string.Append(scope $"private static {ComptimeUtils.TypeFor(m.ReturnType, ..scope .())} def__{m.Name} (void* __self");
		for(int i < m.ParamCount)
		{
			string.Append(scope $", {ComptimeUtils.TypeFor(m.GetParamType(i), ..scope .())} {m.GetParamName(i)}");
		}
		string.Append(") => ");

		{
			ComptimeUtils.Box!(m.ReturnType, string);
			string.Append(scope $"(({typeof(T).GetFullName(..scope .())})System.Internal.UnsafeCastToObject(__self)).{m.Name.StartsWith("get__") || m.Name.StartsWith("set__") ? m.Name.Substring(5) : m.Name}");
			if(m.Name.StartsWith("set__"))
			{
				string.Append("=");
			}
			else if(!m.Name.StartsWith("get__"))
			{
				string.Append("(");
				defer:: string.Append(")");
			}

			for(int i < m.ParamCount)
			{
				{
					ComptimeUtils.Adapt!(m.GetParamType(i), string);
					string.Append(m.GetParamName(i));
				}
				if(i < m.ParamCount - 1) string.Append(",");
			}
		}
	}
}