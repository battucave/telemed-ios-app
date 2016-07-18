Extend any classes with Categories here. If an existing class needs an existing method changed, be sure to "swizzle" the class to ensure that original selector is also still executed. The NSObject+Swizzle class in this folder provides a simple way to swizzle methods from any class.

See the following tutorials for more information about Categories and Swizzling:
http://blog.carbonfive.com/2012/01/23/monkey-patching-ios-with-objective-c-categories-part-1-simple-extensions-and-overrides/

http://blog.carbonfive.com/2012/11/27/monkey-patching-ios-with-objective-c-categories-part-ii-adding-instance-properties/

http://blog.carbonfive.com/2013/02/20/monkey-patching-ios-with-objective-c-categories-part-iii-swizzling/