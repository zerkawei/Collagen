# Collagen
 Generating APIs at compile time for Beef projects

## Usage :
```c#
interface ITest { ... }
class Test : ITest { ... }

let obj = CollagenObject<ITest>.Box() // Boxes the object into a CRepr struct
let adp = Collagen.Adapt<IText>(obj)  // Adapts the foreign object or returns the Beef object
```