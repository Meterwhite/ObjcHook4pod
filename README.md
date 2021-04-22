# ObjcHook4pod
## Copy & Hook. Modify source code for CocoaPods or 3rd SDK. 
- It wokrs in Runtime (swift or ObjC, NSObject)

####
目的：想修改CocoaPods的代码又想每次更新版本使用最新功能。此开源库以拷贝文件的方式先模拟出源码上下文环境，然后你可以通过指定某个方法来侵入，实现重写目标类的指定方法，添加目标类的新属性，甚至更换目标类的基类。
1. 首先拷贝你的目标文件
2. 在类名增加后缀'_h4p'(是Hook4pod的缩写)；
3. 在方法名增加后缀'_h4m'则作为钩子替换原方法；
4. 添加一个后缀为'_a2p'的属性可以为目标类添加一个实例属性，并且支持weak,strong,copy；（不支持基础类型）
5. 添加一个后缀为'_a2m'的方法会将该类型方法或者实例方法添加到目标类上；
6. 如果需要替换目标类的基类可以指定你的类型的基类为相异类型；
>> (Translated by Google)
For: You want to modify CocoaPods code and you want to use the latest code with each update. The open source library invades the source code as a file to override the specified methods of the target class, add new properties of the target class, and even replace the base class of the target class.
>> 1. Copy the target class file
>> 2. Add the suffix '_h4p' to the class name (which is short for Hook4pod);
>> 3. Add the suffix '_h4m' to the method name to replace the original method as a hook;
Add an attribute suffix '_a2p' to add an example attribute for the target class, and support weak,strong, and copy;(Base types are not supported)
>> 5. Adding a method with the suffix '_a2m' adds the class method or instance method to the target class;
>> 6. If you need to replace the base class of the target class, you can specify that the base class of your type is a different type;

```  
Destination File
Class : Super {
  property_super
  method_super { ... }
  ... ...
}
My File
Class_h4p : NewSuper(If need) {
  property_super
  @property (weak | strong | copy) propertyNew_a2p;
  ... ...
  
  method_super_h4m {
     /// 不应在方法内调用任何后缀为'_h4m'的方法，h4m方法只提供函数实现的地址不向目标类型增加方法名。
     self.property_a2p = ...
     [self setValueForKey:@"_property_super"]; /// Access Ivar。访问成员变量请使用属性或者KVC，无法使用下划线形式。
     id value = self.property_super; /// Access Ivar or property。
  }
  methodNew_a2m {
     /// 使用h2m方法增加方法。在文件外调用编译器无法提示，可以通过performSelector等runtime形式调用
     self.property_a2p = ...
  }
}
如果继承了修改过父类的类型，而你需要在编译器中访问真的的父类的方法和属性可以使用宏定义在类定义中声明
If you inherit a class from a hooked class, and you need access to the real properties and methods, the methods and properties can be declared in the class definition using the macro definition.
Class_sub : Class_h4p {
  H4P_SUPER_IS(NewSuper)
  ...
  someMethod { [super_h4p method_super];  }
}
 分类 Category
 NSString_h4p : NSString {
     method_h4m { ... ... }
     ... ...
}
注意：修改父类的目的是为了快速地进行方法转发，修改父类并不会修改类的真实结构，这意味着你不能访问原始类型中不存在的ivar变量地址。解决该问题只能通过Category为原始类型的属性实现动态的成员变量ivar，如果所有属性都是动态实现的则是安全的。
PS: The purpose of changing a superclass is to forward many methods quickly.Changing a super class does not change the real structure of the class, which means you cannot access ivar variable addresses that do not exist in the
original class.The only way to solve this problem is to implement the dynamic member variable ivar by Category as a property of original class.It is safe if all properties are implemented dynamically.
```
## CocoaPods
```
pod 'ObjcHook4pod'
```

- If you have any issue, please report immediately.
