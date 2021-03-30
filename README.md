# ObjcHook4pod
 The method hook of objc implemented by file can quickly modify the method in cocoapods. 

#### 复制目标文件到项目中，在需要修改的类型和方法后面加上后缀'_hook4pod'，该方法就会替代你的目标方法。解决了修改CocoaPods中文件的困难，甚至可以更换目标的基类。
>> Copy the target file to the project, add the suffix'_hook4pod' after the ClassName and MethodName that need to be replaced, this method
will replace your target method. Solved the difficulty of modifying files in CocoaPods,you can even change the superClass of the target.

```  
Original File
Class : Super {
  Method { old... }
  ... ...
}
Your File
Class_hook4pod : NewSuper {
  Method_hook4pod { new... }
  ... ...
}
```
## CocoaPods
```
pod 'ObjcHook4pod'
```
