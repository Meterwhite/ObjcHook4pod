# ObjcHook4pod
## Hook by file.Modify source code for CocoaPods. 
##### Star ObjcHook4pod to user more feature.
##### 使用Swift 或者 Objc都无所谓，但目标类型必须是runtime中的对象(NSObject)
##### 点赞 ObjcHook4pod 以使用更多功能.
##### It doesn't matter if you use Swift or Objc, but the target type has to be an object in Runtime (NSObject)


####
解决问题：想修改CocoaPods代码又想每次更新版本使用最新功能。此开源库以文件的方式侵入源码，实现重写目标类的指定方法，添加目标类的新属性，甚至更换目标类的基类。
1. 拷贝目标类文件
2. 在类名增加后缀'_h4p'(是ObjcHook4pod的缩写)；
3. 在方法名增加后缀'_h4m'则作为钩子替换原方法；
4. 添加一个后缀为'_a2p'的属性可以为目标类添加一个示例属性，并且支持weak,strong,copy；
5. 如果需要替换目标类的基类可以指定你的类型的基类为相异类型；
>> (Translated by Google)
Fix the problem: You want to change your CocoaPods code and you want to use the latest functionality with each update. The open source library invades the source code as a file to override the specified methods of the target class, add new properties of the target class, and even replace the base class of the target class.
>> 1. Copy the target class file
>> 2. Add the suffix '_h4p' to the class name (which is short for ObjcHook4pod);
>> 3. Add the suffix '_h4m' to the method name to replace the original method as a hook;
Add an attribute suffix '_a2p' to add an example attribute for the target class, and support weak,strong, and copy;
>> 5. If you need to replace the base class of the target class, you can specify that the base class of your type is a different type;

```  
Destination File
Class : Super {
  method { ... }
  ... ...
}
My File
Class_hook4pod : NewSuper(If need) {
  @property (weak | strong | copy) property_a2p;
  ... ...
  method_hook4pod { self.property_a2p = ... }
}
```
## CocoaPods
```
pod 'ObjcHook4pod'
```
