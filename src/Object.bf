using System;
namespace Collagen;

[CRepr]
public struct CollagenObject<T> where T : interface
{
	public CollagenInterface<T>* VTable;
	public void*                 Ptr;
}