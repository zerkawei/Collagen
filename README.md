# Collagen
 Generating APIs at compile time for Beef projects

## Usage :
```c#
interface ITest { ... }
class Test : ITest { ... }

let obj = new Test(); 
let c   = CollagenObject<ITest>.Box(obj); // Boxes the object into a CRepr struct
let adp = Collagen.Adapt<IText>(c);  // Adapts the foreign object or returns the Beef object
```
