/*
 NSObject+REResponder.h
 
 Copyright ©2014 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "REUtil.h" // Delete later >>>


#define REIMP(ReturnType) (__typeof(ReturnType (*)(id, SEL, ...)))

//#define RESetBlock(receiver, selector, isClassMethod, key, block) \


//#define RESupermethod(defaultValue, receiver, ...) \
//	^{\
//		IMP re_supermethod;\
//		SEL re_selector;\
//		re_supermethod = [receiver supermethodOfCurrentBlock:&re_selector];\
//		if (re_supermethod && re_selector) {\
//			return (__typeof(defaultValue))(REIMP(__typeof(defaultValue))re_supermethod)(receiver, re_selector, ##__VA_ARGS__);\
//		}\
//		else {\
//			return (__typeof(defaultValue))defaultValue;\
//		}\
//	}()

//NSString* RESetBlock(id receiver, SEL selector, id key, BOOL isClassMethod); // Returns key >>>

@interface NSObject (REResponder)

// Block Management for Class
+ (void)setBlockForClassMethod:(SEL)selector key:(id)key block:(id)block;
+ (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
+ (BOOL)hasBlockForClassMethod:(SEL)selector key:(id)key;
+ (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
+ (IMP)supermethodOfClassMethod:(SEL)selector key:(id)key;
+ (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForClassMethod:(SEL)selector key:(id)key;
+ (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Block Management for Specific Instance
- (void)setBlockForInstanceMethod:(SEL)selector key:(id)key block:(id)block;
- (BOOL)hasBlockForInstanceMethod:(SEL)selector key:(id)key;
- (IMP)supermethodOfInstanceMethod:(SEL)selector key:(id)key;
- (void)removeBlockForInstanceMethod:(SEL)selector key:(id)key;

// Conformance
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol key:(id)key;

@end

#pragma mark -


// Deprecated Methods
@interface NSObject (REResponder_Depricated)
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block __attribute__((deprecated));
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key __attribute__((deprecated));
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key __attribute__((deprecated));
@end
