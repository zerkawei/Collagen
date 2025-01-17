# Collagen
Collagen is a library that generates C APIs for Beef projects with the aim of being unintrusive.

## Basic usage
A basic usage example is provided at `CollagenTest/` and `CollagenTestC/`.

## Interfaces
`CollagenInterface<T>` provides a CRepr interface to the public methods of the type `T`. `CollagenInterface<T>.Default` is a pointer to the instance of the interface allowing calls to Beef implementations of the type.

### Exporting
The interfaces can be exported using the `CollagenExport` attribute or `Collagen.Export` method. They are then added to a dictionary that foreign code can access with the `Collegen.GetInterface` method.

```csharp
[CollagenExport]
public class ClassName { ... }

Collagen.Export("ClassName", &iface); // Adds an entry with the specified key value pair.
```

### Foreign Implementation
The `AllowForeignImplementation` attribute permits implementation of an interface by foreign languages. The exported interface will have an added `__adapt` method that creates a `CollagenAdapter<T>` object which implements the `T` interface.

(Note: The foreign code owns the memory allocated for the CollagenAdapter).

## Renaming
Methods can have the `CollagenName` attribute to override the default name used in generated code. For types, the `CollagenExport` can take an additional argument to rename the exported interface.

```csharp
[CollagenExport("thing")]
public class Thing 
{
    [CollagenName("function_x")] 
    public int Function(int x) { ... }
    [CollagenName("function_x_y")]
    public int Function(int x, int y) { ... }
}
```

## Custom struct adapter
A CRepr struct can be defined to be used in place of another type within the API the latter being automatically cast into the former. The struct need to provide conversion operators to and from the target type.

```csharp
[CRepr]
public struct ThingStruct { ... }

[APICast(typeof(ThingStruct))]
public class Thing { ... }
```

### Generated CRepr struct
Collagen also provides the `CRepr<T>` type to automatically generate a CRepr version of the `T` struct.

```csharp
namespace System
{
    [APICast(typeof(CRepr<StringView>))]
    public extension StringView {}
}
```

## Header generation
The `CollagenHeader.Create` method creates a C header string containing the specified types' interfaces and dependant structs.

```csharp
CollagenHeader.Create(typeof(Thing), typeof(Thing2)); // Evaluated at compile-time
```

The compile time header generation can be enabled with the `COLLAGEN_HEADER_GEN` preprocessor define.