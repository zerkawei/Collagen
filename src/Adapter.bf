using System.Collections;
using System;
using System.Reflection;
namespace Collagen;

public interface IAdapter { public CollagenObject Object { get; } }
public struct CollagenAdapter : IAdapter
{
	public CollagenObject Object { get; }

	public this() { Object = .(null, null); }
	public this(CollagenObject object) { Object = object; }

	public static Dictionary<uint64, AdapterInfo> Convertors = new .() ~ DeleteDictionaryAndValues!(_);
  	public static CollagenObject Box<T>(T object)   where T : interface => .(Convertors[GetID(typeof(T))].BoxInterface, Internal.UnsafeCastToPtr(object));
	public static T Adapt<T>(CollagenObject object) where T : interface => (Convertors[GetID(typeof(T))].BoxInterface == object.Type) ?
		(T)Internal.UnsafeCastToObject(object.Ptr) :
		(T)Convertors[object.Type.typeID].Create(object);
		
	[Inline] public static uint64 GetID(Type T) => (uint64)(T.GetFullName(..scope .()).GetHashCode()); //(uint64)T.GetTypeId();
}

public class AdapterInfo
{
	public function IAdapter(CollagenObject) Create;
	public CollagenInterface* BoxInterface ~ delete _;

	public this(function IAdapter(CollagenObject) create, CollagenInterface* boxInterface)
	{
		Create = create;
		BoxInterface = boxInterface;
	}
}

[AttributeUsage(.Struct)]
public struct CollagenAdapterAttribute<T, N> : Attribute, IOnTypeInit where T : interface where N : CollagenInterface
{
	[Comptime]
	public void OnTypeInit(Type type, Self* prev)
	{
		Compiler.EmitAddInterface(type, typeof(T));
		Compiler.EmitAddInterface(type, typeof(IAdapter));

		Compiler.EmitTypeBody(type, scope $"public static this() \{ CollagenAdapter.Convertors.Add({CollagenAdapter.GetID(typeof(T))}, new .(=> Create, new {typeof(N).GetFullName(.. scope .())}({CollagenAdapter.GetID(typeof(T))})));\}\n");
		Compiler.EmitTypeBody(type, "public this(CollagenObject obj) : base(obj){}; public static IAdapter Create(CollagenObject obj) => Self(obj);\n");

		for(let m in typeof(T).GetMethods())
		{
			if(m.Name.IsEmpty) continue;
			Compiler.EmitTypeBody(type, scope $"{MethodAdapt(m, ..scope .())};\n");
		}
	}

	[Comptime]
	public void MethodAdapt(MethodInfo m, String string)
	{
		string.Append(scope $"public {m.ReturnType.GetFullName(..scope .())} {m.Name}({m.GetParamsDecl(..scope .())}) => ");
		{
			ComptimeUtils.Adapt!(m.ReturnType, string);
			string.Append(scope $"(({typeof(N).GetFullName(..scope .())}*)Object.Type).{m.Name}(Object.Ptr");
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