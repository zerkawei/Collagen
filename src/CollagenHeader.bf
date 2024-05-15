using System;
using System.Collections;
using internal Collagen;
namespace Collagen;

public class CollagenHeader
{
	[Comptime(ConstEval=true)]
	public static String Create(params Type[] types)
	{
		let str     = scope String();
		let structs = scope HashSet<Type>();

		str.Append("#pragma once\n#include <stdint.h>\n#include <stddef.h>\n\n");

		for(let t in types)
		{
			CInterfaceDecl(t, str, structs);
			str.Append("\n\n");
		}

		for(let t in structs)
		{
			CStructDecl(t, str, structs);
			str.Append("\n\n");
		}

		return str;
	}

	[Comptime]
	private static void Mangle(String str)
	{
		let tmp = scope String();
		str..Replace('.', '_')..Replace('<','g')..Replace('>', 'c')..Replace('(', 't')..Replace(')', 'c')..Replace(',', '_')..Replace('[', 'a')..Replace(']', 'c');
		for(let x in str.Split(" "))
		{
			tmp.Append(x);
		}
		str.Clear();
		str.Append(tmp);
	}

	[Comptime]
	private static void CaptureDependency(Type type, HashSet<Type> structs)
	{
		int _ = ?;
		let eType = Collagen.GetExportedTypeOf(type, ref _);
		if(eType.IsStruct)
		{
			structs.Add(eType);
		}
	}

	[Comptime]
	private static void CTypeFor(Type type, String string)
	{
		int starCount = 0;
		let t = Collagen.GetExportedTypeOf(type, ref starCount);
		switch(t)
		{
		case typeof(bool):
			string.Append("bool");
		case typeof(int16):
			string.Append("short");
		case typeof(uint16):
			string.Append("unsigned short");
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
				string.Append(Mangle(.. t.GetFullName(.. scope .())));
			}
		}

		string.Append('*', starCount);
	}

	[Comptime]
	private static void CStructDecl(Type type, String str, HashSet<Type> structs)
	{
		str.Append("struct ");
		str.Append(Mangle(.. type.GetFullName(.. scope .())));
		str.Append(" {\n");

		if(type.GetCustomAttribute<CReprAttribute>() case .Ok)
		{
			for(let field in type.GetFields(.Instance | .Public | .NonPublic))
			{
				str.Append("  ");
				CTypeFor(CaptureDependency(.. field.FieldType, structs), str);
				str.Append(" ");
				str.Append(field.Name);
				str.Append(";\n");
			}
		}
		else
		{
			str.Append("char[");
			str.Append(type.Stride);
			str.Append("] data;\n");
		}

		str.Append("};");
	}

	[Comptime]
	private static void CInterfaceDecl(Type type, String str, HashSet<Type> structs)
	{
		str.Append("struct ");
		str.Append(Mangle(.. type.GetFullName(.. scope .())));
		str.Append("_i {\n");

		for(let m in type.GetMethods())
		{
			if(m.Name.IsEmpty || (m.IsConstructor && !m.DeclaringType.IsValueType) || m.IsDestructor || !m.IsPublic || m.DeclaringType != type || m.GenericArgCount > 0 || m.IsMixin) continue;

			str.Append("  ");
			CTypeFor(CaptureDependency(.. m.ReturnType, structs), str);
			str.Append(" (*");
			CollagenMethods.GetCollagenName(m, str);
			str.Append(")(");

			if(!m.IsStatic)
			{
				if(type.IsValueType)
				{
					CTypeFor(CaptureDependency(.. type, structs), str);
				}
				else
				{
					str.Append("void");
				}
				str.Append("* __self");
			}
			for(int i < m.ParamCount)
			{
				if(i > 0 || !m.IsStatic)
				{
					str.Append(", ");
				}
				CTypeFor(CaptureDependency(.. m.GetParamType(i), structs), str);
				str.Append(" ");
				str.Append(m.GetParamName(i));
			}
			str.Append(");\n");
		}
		
		str.Append("};");
	}
}