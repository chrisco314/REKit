/*
 REResponderInstanceLogicTests.m
 
 Copyright ©2013 Kazki Miura. All rights reserved.
*/

#import "REKit.h"
#import "REResponderInstanceLogicTests.h"
#import "RETestObject.h"
#import <objc/message.h>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


@implementation REResponderInstanceLogicTests

- (void)_resetClasses
{
	// Reset all classes
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		// Remove blocks
		NSDictionary *blocks;
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_blocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForSelector:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		blocks = [NSDictionary dictionaryWithDictionary:[aClass associatedValueForKey:@"REResponder_instaceBlocks"]];
		[blocks enumerateKeysAndObjectsUsingBlock:^(NSString *selectorName, NSArray *blockInfos, BOOL *stop) {
			[[NSArray arrayWithArray:blockInfos] enumerateObjectsUsingBlock:^(NSDictionary *blockInfo, NSUInteger idx, BOOL *stop) {
				objc_msgSend(aClass, @selector(removeBlockForInstanceMethodForSelector:key:), NSSelectorFromString(selectorName), blockInfo[@"key"]);
			}];
		}];
		
		// Remove protocols
		NSDictionary *protocols;
		protocols = [aClass associatedValueForKey:@"REResponder_protocols"];
		[protocols enumerateKeysAndObjectsUsingBlock:^(NSString *protocolName, NSDictionary *protocolInfo, BOOL *stop) {
			[protocolInfo[@"keys"] enumerateObjectsUsingBlock:^(NSString *aKey, NSUInteger idx, BOOL *stop) {
				[aClass setConformable:NO toProtocol:NSProtocolFromString(protocolName) key:aKey];
			}];
		}];
	}
}

- (void)setUp
{
	// super
	[super setUp];
	
	[self _resetClasses];
}

- (void)tearDown
{
	[self _resetClasses];
	
	// super
	[super tearDown];
}

- (void)test_dynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	id obj = [NSObject object];
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Call the sel
	log = objc_msgSend(obj, sel);
	STAssertEqualObjects(log, @"block", @"");
}

- (void)test_methodOfDynamicBlock
{
	SEL sel = @selector(log);
	id obj = [RESubTestObject object];
	
	// Responds to log method dynamically
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	STAssertTrue([RESubTestObject instancesRespondToSelector:sel], @"");
	
	// Get method
	IMP method;
	method = [RESubTestObject instanceMethodForSelector:sel];
	
	// Don't affet class method
	STAssertTrue([RESubTestObject methodForSelector:sel] != method, @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
	
	// Affect to instance
	STAssertEquals([obj methodForSelector:sel], method, @"");
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Don't affect superclass
	STAssertTrue([NSObject methodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue([NSObject instanceMethodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue([[NSObject object] methodForSelector:sel] != method, @"");
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_overrideBlock
{
	SEL sel = @selector(log);
	
	// Override
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check log
	STAssertEqualObjects([[RETestObject object] log], @"overridden", @"");
}

- (void)test_methodOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Override log method
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	STAssertTrue([RETestObject instancesRespondToSelector:sel], @"");
	
	// Get method
	IMP method;
	method = [RETestObject instanceMethodForSelector:sel];
	
	// Don't affect class method
	STAssertTrue([RETestObject methodForSelector:sel] != method, @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	
	// Affect instance
	STAssertEquals([obj methodForSelector:sel], method, @"");
	STAssertTrue([obj respondsToSelector:sel], @"");
	
	// Don't affect superclass
	STAssertTrue([NSObject methodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue([NSObject instanceMethodForSelector:sel] != method, @"");
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue([[NSObject object] methodForSelector:sel] != method, @"");
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_receiverOfDynamicBlock
{
	SEL sel = @selector(log);
	id obj = [NSObject object];
	
	// Set block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	}];
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_receiverOfOverrideBlock
{
	SEL sel = @selector(log);
	id obj = [RETestObject object];
	
	// Set block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		STAssertEqualObjects(receiver, obj, @"");
		return @"block";
	}];
	
	// Call
	objc_msgSend(obj, sel);
}

- (void)test_dynamicBlockAffectSubclasses
{
	SEL sel = @selector(log);
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Responds?
	STAssertTrue([NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue([@(1) respondsToSelector:sel], @"");
	
	// Check log
	STAssertEqualObjects(objc_msgSend(@(1), sel), @"block", @"");
}

- (void)test_dynamicBlockAffectSubclassesConnectedToForwardingMethod
{
	SEL sel = _cmd;
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertEquals([RETestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	STAssertEquals([RESubTestObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
}

- (void)test_overrideBlockAffectSubclasses
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Override
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check log of RESubTestObject
	log = [[RESubTestObject object] log];
	STAssertEqualObjects(log, @"log", @"");
}

- (void)test_dynamicBlockDoesNotAffectOtherClass
{
	SEL sel = _cmd;
	
	// Set block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_overrideBlockDoesNotAffectOtherClasses
{
	SEL sel = @selector(log);
	
	// Override
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		return @"block";
	}];
	
	// Check NSNumber
	STAssertTrue(![NSNumber instancesRespondToSelector:sel], @"");
	STAssertTrue(![@(1) respondsToSelector:sel], @"");
}

- (void)test_dynamicBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(subLog);
	NSString *string;
	
	// Add subRect method
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check return string
	string = [[RESubTestObject object] subLog];
	STAssertEqualObjects(string, @"subLog", @"");
}

- (void)test_overrideBlockDoesNotOverrideImplementationOfSubclass
{
	SEL sel = @selector(overrideLog);
	NSString *string;
	
	// Override overrideLog
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	string = [[RESubTestObject object] overrideLog];
	STAssertEqualObjects(string, @"RESubTestObject", @"");
}

- (void)test_addDynamicBlockToSubclassesOneByOne
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"NSObject";
	}];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RETestObject";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"RESubTestObject";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"RETestObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"RESubTestObject", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"NSObject", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"NSObject", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject respondsToSelector:sel], @"");
	STAssertTrue(![RETestObject respondsToSelector:sel], @"");
	STAssertTrue(![RESubTestObject respondsToSelector:sel], @"");
}

- (void)test_overridingLastBlockUpdatesSubclasses
{
	SEL sel = _cmd;
	
	// Add _cmd
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Override block of NSObject
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"overridden";
	}];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"overridden", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"overridden", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_overrideLastBlockWithSameBlock
{
	SEL sel = _cmd;
	
	// Make block
	NSString *(^block)(id receiver);
	block = ^(id receiver) {
		return @"block";
	};
	
	// Set block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:block];
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:block];
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:block];
	
	// Remove block
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Override block with same block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:block];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_addDynamicBlockToSubclasses
{
	SEL sel = _cmd;
	
	// Add block
	for (Class aClass in RESubclassesOfClass([NSObject class], YES)) {
		[aClass setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of RESubTestObject
	[RESubTestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Check returned string
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RESubTestObject object], sel), @"block", @"");
	
	// Remove block of NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RETestObject instancesRespondToSelector:sel], @"");
	STAssertTrue(![RESubTestObject instancesRespondToSelector:sel], @"");
}

- (void)test_canPsssReceiverAsKey
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add log method
	[NSObject setBlockForInstanceMethod:sel key:[NSObject class] block:^(id receiver) {
		return @"block";
	}];
	log = objc_msgSend([NSObject object], sel);
	
	// Check log
	STAssertEqualObjects(log, @"block", @"");
	
	// Remove the block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:[NSObject class]];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_contextOfRemovedBlockIsDeallocated
{
	SEL selector = @selector(log);
	__block BOOL isContextDeallocated = NO;
	
	@autoreleasepool {
		// Make context
		id context;
		context = [NSObject object];
		[context setBlockForInstanceMethod:@selector(dealloc) key:nil block:^(id receiver) {
			// Raise deallocated flag
			isContextDeallocated = YES;
			
			// super
			IMP supermethod;
			if ((supermethod = [receiver supermethodOfCurrentBlock])) {
				supermethod(receiver, @selector(dealloc));
			}
		}];
		
		// Add log method
		[NSObject setBlockForInstanceMethod:selector key:@"key1" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Override log method
		[NSObject setBlockForInstanceMethod:selector key:@"key2" block:^(id receiver) {
			id ctx;
			ctx = context;
		}];
		
		// Remove blocks
		[NSObject removeBlockForInstanceMethodForSelector:selector key:@"key2"];
		STAssertTrue(!isContextDeallocated, @"");
		[NSObject removeBlockForInstanceMethodForSelector:selector key:@"key1"];
	}
	
	// Check
	STAssertTrue(isContextDeallocated, @"");
}

- (void)test_allowArguments
{
	SEL selector = @selector(logWithSuffix:);
	NSString *log;
	
	// Add block
	[NSObject setBlockForInstanceMethod:selector key:nil block:^(id receiver, NSString *suffix) {
		return [NSString stringWithFormat:@"block1-%@", suffix];
	}];
	
	// Call
	log = objc_msgSend([NSObject object], selector, @"suffix");
	STAssertEqualObjects(log, @"block1-suffix", @"");
}

- (void)test_allowStructures
{
	SEL sel = @selector(makeRectWithOrigin:size:);
	CGRect rect;
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		return (CGRect){.origin = origin, .size = size};
	}];
	
	// Check rect
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(10.0, 20.0), CGSizeMake(30.0, 40.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_methodForSelector__executeReturnedIMP
{
	SEL sel = @selector(doSomething);
	__block BOOL called = NO;
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		called = YES;
	}];
	
	// Call imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	(REIMP(void)imp)([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_hasBlockForInstanceMethod_key
{
	SEL sel = @selector(log);
	
	// Has block?
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Has block?
	STAssertTrue(![NSObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	STAssertTrue([RETestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:@""], @"");
	STAssertTrue(![RETestObject hasBlockForInstanceMethod:sel key:nil], @"");
	STAssertTrue(![RESubTestObject hasBlockForInstanceMethod:sel key:@"key"], @"");
}

- (void)test_stackBlockPerSelector
{
	NSString *string;
	
	// Add block for log method with key
	[NSObject setBlockForInstanceMethod:@selector(log) key:@"key" block:^(id receiver) {
		return @"log";
	}];
	
	// Add block for say method with key
	[NSObject setBlockForInstanceMethod:@selector(say) key:@"key" block:^(id receiver) {
		return @"say";
	}];
	
	// Perform log
	string = objc_msgSend([NSObject object], @selector(log));
	STAssertEqualObjects(string, @"log", @"");
	
	// Perform say
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove log block
	[NSObject removeBlockForInstanceMethodForSelector:@selector(log) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(log)], @"");
	string = objc_msgSend([NSObject object], @selector(say));
	STAssertEqualObjects(string, @"say", @"");
	
	// Remove say block
	[NSObject removeBlockForInstanceMethodForSelector:@selector(say) key:@"key"];
	STAssertTrue(![NSObject instancesRespondToSelector:@selector(say)], @"");
}

- (void)test_stackOfDynamicBlocks
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		return @"block1";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:@"block2" block:^NSString*(id receiver) {
		return @"block2";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethod:sel key:@"block3" block:^NSString*(id receiver) {
		return @"block3";
	}];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	STAssertTrue([[NSObject object] respondsToSelector:sel], @"");
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
	STAssertEquals([NSObject methodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_recoonectedToForwardingMethod
{
	SEL sel = @selector(readThis:);
	NSString *string = nil;
	
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return string;
	}];
	string = objc_msgSend([NSObject object], sel, @"Read");
	STAssertEqualObjects(string, @"Read", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	STAssertEquals([NSObject instanceMethodForSelector:sel], [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_stackOfOverrideBlocks
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Call block1
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block1", @"");
	
	// Add block2
	[NSString setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Add block3
	[NSString setBlockForInstanceMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		return @"block3";
	}];
	
	// Call block3
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block3", @"");
	
	// Remove block3
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block1
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	
	// Call block2
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block2
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	
	// Call original
	STAssertTrue([[NSString string] respondsToSelector:sel], @"");
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_allowsOverrideOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block1";
	}];
	
	// Override the block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block2";
	}];
	
	// Get log
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"block2", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_allowsOverrideOfOverrideBlock
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Override
	[NSString setBlockForInstanceMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block1";
	}];
	
	// Override block
	[NSString setBlockForInstanceMethod:sel key:@"key" block:^(id receiver, NSString *string) {
		return @"block2";
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"block2", @"");
	
	// Remove block
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Call original
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_implementBySameBlock
{
	SEL sel = @selector(log);
	
	for (Class cls in @[[NSObject class], [NSObject class]]) {
		[cls setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_canShareBlock
{
	SEL sel = _cmd;
	
	// Share block
	for (Class cls in @[[NSObject class], [NSObject class], [RETestObject class]]) {
		[cls setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
			return @"block";
		}];
	}
	
	// Call log method
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"block", @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from NSObject
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([NSObject instancesRespondToSelector:sel], @"");
	STAssertEqualObjects(objc_msgSend([RETestObject object], sel), @"block", @"");
	
	// Remove block from RETestObject
	[RETestObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	STAssertFalse([[RETestObject object] respondsToSelector:sel], @"");
}

- (void)test_supermethodPointsToNil
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add block
	[NSArray setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Check supermethod
		STAssertNil((id)[receiver supermethodOfCurrentBlock], @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([NSArray array], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToOriginalMethod
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	IMP originalMethod;
	originalMethod = [RETestObject instanceMethodForSelector:sel];
	STAssertNotNil((id)originalMethod, @"");
	
	// Override log method
	[RETestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// supermethod
		NSString *res = nil;
		typedef id (*id_IMP)(id, SEL, ...);
		id_IMP supermethod;
		if ((supermethod = (id_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, originalMethod, @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToMethodOfSuperclass
{
	SEL sel = @selector(log);
	__block BOOL called = NO;
	
	// Add log block to RESubTestObject
	[RESubTestObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// supermethod
		id res = nil;
		typedef id (*id_IMP)(id, SEL, ...);
		id_IMP supermethod;
		if ((supermethod = (id_IMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, [RETestObject instanceMethodForSelector:sel], @"");
		
		called = YES;
	}];
	
	// Call
	objc_msgSend([RESubTestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodPointsToInstancesBlockOfSuperclass
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	// Get imp
	IMP imp;
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		called = YES;
	}];
	imp = [NSObject instanceMethodForSelector:sel];
	
	// Add block
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			(REIMP(void)supermethod)(receiver, sel);
		}
		
		// Check supermethod
		STAssertEquals(supermethod, imp, @"");
	}];
	
	// Call
	objc_msgSend([RETestObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_supermethodDoesNotPointToClassMethod
{
	SEL sel = _cmd;
	__block BOOL dirty = NO;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Add class method
	[NSObject setBlockForClassMethod:sel key:nil block:^(Class receiver) {
		dirty = YES;
	}];
	
	// Add instance method
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// Check supermethod
		STAssertNil((id)[receiver supermethodOfCurrentBlock], @"");
	}];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertTrue(!dirty, @"");
}

- (void)test_orderOfSupermethod
{
	SEL sel = _cmd;
	__block NSMutableArray *imps;
	imps = [NSMutableArray array];
	
	id testObj;
	id obj;
	testObj = [RETestObject object];
	obj = [NSObject object];
	
	// Add block to testObj
	[testObj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp1;
	imp1 = [testObj methodForSelector:sel];
	
	// Add block to NSObject
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp2;
	imp2 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp3;
	imp3 = [obj methodForSelector:sel];
	
	// Add block to RETestObject
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp4;
	imp4 = [RETestObject instanceMethodForSelector:sel];
	
	// Add block to NSObject
	[[obj class] setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp5;
	imp5 = [NSObject instanceMethodForSelector:sel];
	
	// Add object block
	[obj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp6;
	imp6 = [obj methodForSelector:sel];
	
	// Add block to testObj
	[testObj setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp7;
	imp7 = [testObj methodForSelector:sel];
	
	// Add block to RETestObject
	[[testObj class] setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			[imps addObject:[NSValue valueWithPointer:supermethod]];
			(REIMP(void)supermethod)(receiver, sel);
		}
	}];
	IMP imp8;
	imp8 = [RETestObject instanceMethodForSelector:sel];
	
	// Call
	[imps addObject:[NSValue valueWithPointer:[testObj methodForSelector:sel]]];
	objc_msgSend(testObj, sel);
	
	// Check
	NSArray *expected;
	expected = @[
		[NSValue valueWithPointer:imp7],
		[NSValue valueWithPointer:imp1],
		[NSValue valueWithPointer:imp8],
		[NSValue valueWithPointer:imp4],
		[NSValue valueWithPointer:imp5],
		[NSValue valueWithPointer:imp2],
	];
	STAssertEqualObjects(imps, expected, @"");
}

- (void)test_supermethodOfDynamicBlock
{
	SEL sel = @selector(log);
	NSString *log;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver) {
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append supermethod's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block1"];
		
		return log;
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1", @"");
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append supermethod's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block2"];
		
		return log;
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Add block3
	[NSObject setBlockForInstanceMethod:sel key:@"block3" block:^NSString*(id receiver) {
		// Make log…
		NSMutableString *log;
		log = [NSMutableString string];
		
		// Append super's log
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[log appendString:supermethod(receiver, sel)];
		}
		
		// Append my log
		[log appendString:@"-block3"];
		
		return log;
	}];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2-block3", @"");
	
	// Remove block3
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block1-block2", @"");
	
	// Remove block1
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	
	// Call log method
	log = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(log, @"-block2", @"");
	
	// Remove block2
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	STAssertTrue(![[NSObject object] respondsToSelector:sel], @"");
}

- (void)test_supermethodOfOverrideBlock
{
	SEL sel = @selector(stringByAppendingString:);
	NSString *string;
	
	// Add block1
	[NSString setBlockForInstanceMethod:sel key:@"block1" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block1"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1", @"");
	
	// Add block2
	[NSString setBlockForInstanceMethod:sel key:@"block2" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block2"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Add block3
	[NSString setBlockForInstanceMethod:sel key:@"block3" block:^(id receiver, NSString *string) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// Append supermethod's string
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel, string)];
		}
		
		// Append my string
		[str appendString:@"-block3"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2-block3", @"");
	
	// Remove block3
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block3"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block1-block2", @"");
	
	// Remove block1
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block1"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string-block2", @"");
	
	// Remove block2
	[NSString removeBlockForInstanceMethodForSelector:sel key:@"block2"];
	
	// Call
	string = objc_msgSend([NSString string], sel, @"string");
	STAssertEqualObjects(string, @"string", @"");
}

- (void)test_supermethodReturningScalar
{
	SEL sel = @selector(age);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override age method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		NSUInteger age = 0;
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			age = supermethod(receiver, sel);
		}
		
		// Increase age
		age++;
		
		return age;
	}];
	
	// Check age
	STAssertEquals(obj.age, (NSUInteger)11, @"");
}

- (void)test_supermethodWithArgumentReturningScalar
{
	SEL sel = @selector(ageAfterYears:);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.age = 10;
	
	// Override ageAfterYears: method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSUInteger years) {
		// supermethod
		NSUInteger age = 0;
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			age = supermethod(receiver, sel, years);
		}
		
		// Increase age
		age++;
		
		return age;
	}];
	
	// Check age
	NSUInteger age;
	age = [obj ageAfterYears:3];
	STAssertEquals(age, (NSUInteger)14, @"");
}

- (void)test_supermethodReturningStructure
{
	SEL sel = @selector(rect);
	
	// Make obj
	RETestObject *obj;
	obj = [RETestObject object];
	obj.rect = CGRectMake(10.0f, 20.0f, 30.0f, 40.0f);
	
	// Override rect method
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		CGRect res = CGRectZero;
		typedef CGRect (*CGRectIMP)(id, SEL, ...);
		CGRectIMP supermethod;
		if ((supermethod = (CGRectIMP)[receiver supermethodOfCurrentBlock])) {
			res = supermethod(receiver, sel);
		}
		
		// Inset
		return CGRectInset(res, 3.0, 6.0);
	}];
	
	// Get rect
	CGRect rect;
	rect = obj.rect;
	STAssertEquals(rect, CGRectMake(13.0f, 26.0f, 24.0f, 28.0f), @"");
}

- (void)test_supermethodReturningVoid
{
	SEL sel = @selector(sayHello);
	__block BOOL called = NO;
	
	// Override sayHello
	[RETestObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, sel);
			called = YES;
		}
	}];
	[[RETestObject object] sayHello];
	
	// Called?
	STAssertTrue(called, @"");
}

- (void)test_getSupermethodFromOutsideOfBlock
{
	IMP supermethod;
	supermethod = [NSObject supermethodOfCurrentBlock];
	STAssertNil((id)supermethod, @"");
}

- (void)test_removeBlockForInstanceMethodForSelector_key
{
	SEL sel = @selector(log);
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Responds to log method dynamically
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		return @"block";
	}];
	
	// Remove block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Responds?
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
	
	// Check imp
	IMP imp;
	imp = [NSObject instanceMethodForSelector:sel];
	STAssertEquals(imp, [NSObject methodForSelector:NSSelectorFromString(@"_objc_msgForward")], @"");
}

- (void)test_removeBlockForInstanceMethodForSelector_key__doesNotAffectObjectBlock
{
	SEL sel = _cmd;
	__block NSUInteger count = 0;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Set object block
	[obj setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		count++;
	}];
	
	// Set instances block
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		STFail(@"");
	}];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertEquals(count, (NSUInteger)1, @"");
	
	// Remove instances block
	[NSObject removeBlockForInstanceMethodForSelector:sel key:@"key"];
	
	// Call
	objc_msgSend(obj, sel);
	STAssertEquals(count, (NSUInteger)2, @"");
}

- (void)test_removeCurrentBlock
{
	SEL sel = @selector(oneShot);
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		// Remove currentBlock
		[receiver removeCurrentBlock];
	}];
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
	objc_msgSend([NSObject object], sel);
	STAssertTrue(![NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_removeCurrentBlock__callInSupermethod
{
	SEL sel = _cmd;
	NSString *string;
	
	// Add block1
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		[receiver removeCurrentBlock];
		return @"block1-";
	}];
	
	// Add block2
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
		NSMutableString *str;
		str = [NSMutableString string];
		
		// supermethod
		IMP supermethod;
		if ((supermethod = [receiver supermethodOfCurrentBlock])) {
			[str appendString:supermethod(receiver, sel)];
		}
		
		[str appendString:@"block2"];
		
		return str;
	}];
	
	// Call
	string = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(string, @"block1-block2", @"");
	
	// Call again
	string = objc_msgSend([NSObject object], sel);
	STAssertEqualObjects(string, @"block2", @"");
}

- (void)test_canCallRemoveCurrentBlockFromOutsideOfBlock
{
	SEL sel = @selector(doSomething);
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Add doSomething method
	[NSObject setBlockForInstanceMethod:sel key:@"key" block:^(id receiver) {
		// Do something
	}];
	
	// Call removeCurrentBlock
	STAssertNoThrow([obj removeCurrentBlock], @"");
	
	// Check doSomething method
	STAssertTrue([NSObject instancesRespondToSelector:sel], @"");
}

- (void)test_doNotChangeClass
{
	SEL sel = _cmd;
	
	// Make obj
	id obj;
	obj = [NSObject object];
	
	// Get original class
	Class class;
	class = [obj class];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver) {
	}];
	
	// Check class
	STAssertEquals([obj class], class, @"");
	STAssertEquals(object_getClass(obj), class, @"");
}

- (void)test_REIMP__void
{
	SEL sel = _cmd;
	__block BOOL called = NO;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		called = YES;
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		(REIMP(void)[receiver supermethodOfCurrentBlock])(receiver, sel);
	}];
	
	// Call
	objc_msgSend([NSObject object], sel);
	STAssertTrue(called, @"");
}

- (void)test_REIMP__id
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		return @"hello";
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		NSString *res;
		res = (REIMP(id)[receiver supermethodOfCurrentBlock])(receiver, sel);
		return res;
	}];
	
	STAssertEqualObjects(objc_msgSend([NSObject object], sel), @"hello", @"");
}

- (void)test_REIMP__scalar
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		return 1;
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		NSInteger i;
		i = (REIMP(NSInteger)[receiver supermethodOfCurrentBlock])(receiver, sel);
		return i + 1;
	}];
	
	STAssertEquals((NSInteger)objc_msgSend([NSObject object], sel), (NSInteger)2, @"");
}

- (void)test_REIMP__CGRect
{
	SEL sel = _cmd;
	
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		CGRect res;
		IMP supermethod;
		supermethod = [receiver supermethodOfCurrentBlock];
		if (supermethod) {
			res = (REIMP(CGRect)[receiver supermethodOfCurrentBlock])(receiver, sel);
		}
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(Class receiver) {
		// supermethod
		CGRect rect;
		rect = (REIMP(CGRect)[receiver supermethodOfCurrentBlock])(receiver, sel);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		
		return rect;
	}];
	
	// Check rect
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel);
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

- (void)test_RESupermethod__void
{
	SEL sel = @selector(checkString:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(void, receiver, sel, string);
		STAssertEqualObjects(string, @"block", @"");
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		RESupermethod(void, receiver, sel, @"block");
		STAssertEqualObjects(string, @"string", @"");
	}];
	
	// Call
	objc_msgSend([NSObject object], sel, @"string");
}

- (void)test_RESupermethod__id
{
	SEL sel = @selector(appendString:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(id, receiver, sel, @"Wow"), string];
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSString *string) {
		return [NSString stringWithFormat:@"%@%@", RESupermethod(id, receiver, sel, @"block1"), string];
	}];
	
	// Call
	NSString *string;
	string = objc_msgSend([NSObject object], sel, @"block2");
	STAssertEqualObjects(string, @"(null)block1block2", @"");
}

- (void)test_RESupermethod__Scalar
{
	SEL sel = @selector(addInteger:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(NSInteger, receiver, sel, integer);
		
		// Check
		STAssertEquals(integer, (NSInteger)1, @"");
		STAssertEquals(value, (NSInteger)0, @"");
		
		return (value + integer);
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, NSInteger integer) {
		NSInteger value;
		value = RESupermethod(NSInteger, receiver, sel, 1);
		
		// Check
		STAssertEquals(integer, (NSInteger)2, @"");
		STAssertEquals(value, (NSInteger)1, @"");
		
		return (value + integer);
	}];
	
	// Call
	NSInteger value;
	value = objc_msgSend([NSObject object], sel, 2);
	STAssertEquals(value, (NSInteger)3, @"");
}

- (void)test_RESupermethod__CGRect
{
	SEL sel = @selector(rectWithOrigin:Size:);
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethodStret((CGRect){}, receiver, sel, origin, size);
		STAssertEquals(rect, CGRectZero, @"");
		
		return CGRectMake(1.0, 2.0, 3.0, 4.0);
	}];
	
	// Add block
	[NSObject setBlockForInstanceMethod:sel key:nil block:^(id receiver, CGPoint origin, CGSize size) {
		CGRect rect;
		rect = RESupermethodStret(CGRectZero, receiver, sel, origin, size);
		rect.origin.x *= 10.0;
		rect.origin.y *= 10.0;
		rect.size.width *= 10.0;
		rect.size.height *= 10.0;
		return rect;
	}];
	
	// Call
	CGRect rect;
	rect = (REIMP(CGRect)objc_msgSend_stret)([NSObject object], sel, CGPointMake(1.0, 2.0), CGSizeMake(3.0, 4.0));
	STAssertEquals(rect, CGRectMake(10.0, 20.0, 30.0, 40.0), @"");
}

@end
