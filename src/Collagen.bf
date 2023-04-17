using System;
using System.Reflection;
using System.Collections;
namespace Collagen;

public static class Collagen
{
	private static Dictionary<void*, IAdapter> _ownedAdapters = new .() ~ DeleteDictionaryAndValues!(_);

	[Inline] public static uint64 GetID<T>() => (uint64)(typeof(T).GetFullName(..scope .()).GetHashCode()); 
	public static T Adapt<T>(CollagenObject<T> obj) where T : interface
	{
		let objPtr = obj.Ptr;
		IAdapter existingAdapter = ?;

		return _ownedAdapters.ContainsKey(objPtr) && (existingAdapter = _ownedAdapters[objPtr]).TypeID == obj.Type.TypeID ?
			(T)existingAdapter
			: (obj.Type == CollagenObject<T>.BoxingInterface) ?
				(T)Internal.UnsafeCastToObject(objPtr)
				: (T)(Object)(_ownedAdapters.Add(objPtr, .. new CollagenAdapter<T>(*(CollagenObject<T>*)(void*)&obj)));
	}
}

internal static class ComptimeUtils
{
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
		else if(type.IsInterface)
		{
			string.Append(scope $"CollagenObject<{type.GetFullName(.. scope .())}>");
		}
		else
		{
			string.Append("void*");
		}
	}

	[Comptime]
	public static mixin Box(Type type, String string)
	{
		if(type.IsEnum)
		{
			string.Append(scope $"({type.UnderlyingType.GetFullName(..scope .())})");
		}
		else if(type.IsInterface)
		{
			string.Append(scope $"CollagenObject<{type.GetFullName(..scope .())}>.Box(");
			defer:: string.Append(")");
		}
		else if(!type.IsPrimitive)
		{
			string.Append("System.Internal.UnsafeCastToPtr(");
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
		else if(type.IsInterface)
		{
			string.Append(scope $"Collagen.Adapt<{type.GetFullName(..scope .())}>(");
			defer:: string.Append(")");
		}
		else if(!type.IsPrimitive)
		{
			string.Append(scope $"({type.GetFullName(..scope .())})System.Internal.UnsafeCastToObject(");
			defer:: string.Append(")");
		}
	}
}

public interface IAdapter
{
	public uint64 TypeID { get; }
}

public class CollagenAdapter<T> : IAdapter where T : interface
{
	public CollagenObject<T> Object { get; }
	public uint64            TypeID { get => Object.Type.TypeID; }

	public this(CollagenObject<T> object) { Object = object; }
	public ~this() { Collagen.[Friend]_ownedAdapters.Remove(Object.Ptr); }

	[Comptime, OnCompile(.TypeInit)]
	public static void OnTypeInit()
	{
		let type = typeof(Self);
		Compiler.EmitAddInterface(type, typeof(T));

		int i = 0;
		for(let m in typeof(T).GetMethods())
		{
			if(m.Name.IsEmpty) continue;
			Compiler.EmitTypeBody(type, scope $"{MethodAdapt(m, i++, ..scope .())};\n");
		}
	}

	[Comptime]
	public static void MethodAdapt(MethodInfo m, int idx, String string)
	{
		string.Append(scope $"public {m.ReturnType.GetFullName(..scope .())} {m.Name}({m.GetParamsDecl(..scope .())}) => ");
		{
			ComptimeUtils.Adapt!(m.ReturnType, string);
			string.Append(scope $"((CollagenObject<{typeof(T).GetFullName(.. scope .())}>.Interface*)Object.Type).{m.Name}(Object.Ptr");
			for(int i < m.ParamCount)
			{
				string.Append(", ");
				{
					ComptimeUtils.Box!(m.GetParamType(i), string);
					string.Append(m.GetParamName(i));
				}
			}
			string.Append(")");
		}
	}
}

[CRepr]
public struct CollagenObject<T> where T : interface
{
	public Interface* Type;
	public void* Ptr;

	public this(Interface* type, void* ptr) { Type = type; Ptr = ptr; }

	public static Interface* BoxingInterface = new .(Collagen.GetID<T>()) ~ delete _;
	public static Self Box(T obj) => .(BoxingInterface, Internal.UnsafeCastToPtr(obj)); 

	[CRepr]
	public struct Interface
	{
		public uint64 TypeID;

		[Comptime, OnCompile(.TypeInit)]
		public static void OnTypeInit()
		{
			let type = typeof(Self);
			Compiler.EmitTypeBody(type, scope $"public this(uint64 id)\{ TypeID = id; ");

			let methods = typeof(T).GetMethods();
			for(let m in methods)
			{
				if(m.Name.IsEmpty) continue;
				Compiler.EmitTypeBody(type, scope $"{m.Name} = => def__{m.Name}; ");
			}
			Compiler.EmitTypeBody(type, "};\n");

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
}