/*
 NSObject+REResponder.h
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import <Foundation/Foundation.h>


// REVoidIMP
typedef void (*REVoidIMP)(id, SEL, ...);


@interface NSObject (REResponder)

// Block
- (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block;
- (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key;
- (void)removeBlockForSelector:(SEL)selector withKey:(id)key;

// Current Block
- (IMP)supermethodOfCurrentBlock;
- (void)removeCurrentBlock;

// Conformance
- (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key;

// Class Method Version
+ (void)respondsToSelector:(SEL)selector withKey:(id)key usingBlock:(id)block;
+ (BOOL)hasBlockForSelector:(SEL)selector withKey:(id)key;
+ (void)removeBlockForSelector:(SEL)selector withKey:(id)key;
+ (IMP)supermethodOfCurrentBlock;
+ (void)removeCurrentBlock;
+ (void)setConformable:(BOOL)conformable toProtocol:(Protocol*)protocol withKey:(id)key;

@end
