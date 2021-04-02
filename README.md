# ObjcHook4pod
## Modify source code for CocoaPods. 
- It wokrs in Runtime (Swift or Objc, NSObject)

####
目的：想修改CocoaPods的代码又想每次更新版本使用最新功能。此开源库以拷贝文件的方式先模拟出源码上下文环境，然后你可以通过指定某个方法来侵入，实现重写目标类的指定方法，添加目标类的新属性，甚至更换目标类的基类。
1. 首先拷贝你的目标文件
2. 在类名增加后缀'_h4p'(是Hook4pod的缩写)；
3. 在方法名增加后缀'_h4m'则作为钩子替换原方法；
4. 添加一个后缀为'_a2p'的属性可以为目标类添加一个示例属性，并且支持weak,strong,copy；
5. 如果需要替换目标类的基类可以指定你的类型的基类为相异类型；
>> (Translated by Google)
For: You want to modify CocoaPods code and you want to use the latest code with each update. The open source library invades the source code as a file to override the specified methods of the target class, add new properties of the target class, and even replace the base class of the target class.
>> 1. Copy the target class file
>> 2. Add the suffix '_h4p' to the class name (which is short for Hook4pod);
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
Class_h4p : NewSuper(If need) {
  @property (weak | strong | copy) property_a2p;
  ... ...
  method_h4m { self.property_a2p = ... }
}
```
## CocoaPods
```
pod 'ObjcHook4pod'
```

- If you have any issue, please report immediately.
