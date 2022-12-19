# Collagen
 Generating APIs at compile time for Beef projects

## Usage :
```c#
interface ITest
{
	...
}

[CollagenInterface<ITest>, CRepr]
struct TestForeign : CollagenInterface {}
[CollagenAdapter<ITest, TestForeign>, AlwaysInclude(AssumeInstantiated=true)]
struct TestAdapter : CollagenAdapter {} 
```