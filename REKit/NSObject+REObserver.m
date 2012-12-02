/*
 NSObject+REObserver.m
 
 Copyright ©2012 Kazki Miura. All rights reserved.
*/

#import "NSObject+REObserver.h"
#import "NSObject+REResponder.h"
#import "REUtil.h"

// Override addObserver:toObjectsAtIndexes:forKeyPath:options:context: method >>>
// Override - (void)removeObserver:(NSObject *)anObserver fromObjectsAtIndexes:(NSIndexSet *)indexes forKeyPath:(NSString *)keyPath >>>

#if __has_feature(objc_arc)
	#error This code needs compiler option -fno-objc-arc
#endif


// Constants
static NSString* const kObservingInfosKey = @"REObserverObservingInfos";
static NSString* const kObservedInfosKey = @"REObserverObservedInfos";

// Keys
NSString* const REObserverObservedObjectKey = @"observedObject";
NSString* const REObserverObservingObjectKey = @"observingObject";
NSString* const REObserverKeyPathKey = @"keyPath";
NSString* const REObserverOptionsKey = @"options";
NSString* const REObserverContextPointerValueKey = @"contextPointerValue";
NSString* const REObserverBlockKey = @"block";


@implementation NSObject (REObserver)

//--------------------------------------------------------------//
#pragma mark -- Setup --
//--------------------------------------------------------------//

- (void)REObserver_X_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
	// Filter
	if (!observer || ![keyPath length]) {
		return;
	}
	
	// Make observingInfo
	NSMutableDictionary *observingInfo;
	observingInfo = [NSMutableDictionary dictionaryWithDictionary:@{
		REObserverObservedObjectKey : self,
		REObserverKeyPathKey : keyPath,
		REObserverOptionsKey : @(options),
	}];
	if (context) {
		observingInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
	}
	
	// Add observingInfo
	NSMutableArray *observingInfos;
	observingInfos = [observer associatedValueForKey:kObservingInfosKey];
	if (!observingInfos) {
		observingInfos = [NSMutableArray array];
		[observer associateValue:observingInfos forKey:kObservingInfosKey policy:OBJC_ASSOCIATION_RETAIN];
	}
	[observingInfos addObject:observingInfo];
	
	// Make observedInfo
	NSMutableDictionary *observedInfo;
	observedInfo = [NSMutableDictionary dictionaryWithDictionary:@{
		REObserverObservingObjectKey : observer,
		REObserverKeyPathKey : keyPath,
		REObserverOptionsKey : @(options),
	}];
	if (context) {
		observedInfo[REObserverContextPointerValueKey] = [NSValue valueWithPointer:context];
	}
	
	// Add observedInfo
	NSMutableArray *observedInfos;
	observedInfos = [self associatedValueForKey:kObservedInfosKey];
	if (!observedInfos) {
		observedInfos = [NSMutableArray array];
		[self associateValue:observedInfos forKey:kObservedInfosKey policy:OBJC_ASSOCIATION_RETAIN];
	}
	[observedInfos addObject:observedInfo];
	
	// original
	[self REObserver_X_addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)REObserver_X_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	@synchronized (self) {
		// Get observingInfo
		__block NSDictionary *observingInfo = nil;
		[[self observingInfos] enumerateObjectsUsingBlock:^(NSDictionary *anObservingInfo, NSUInteger idx, BOOL *stop) {
			if (anObservingInfo[REObserverObservedObjectKey] == object
				&& [anObservingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
			){
				observingInfo = anObservingInfo;
				*stop = YES;
			}
		}];
		if (!observingInfo) {
			return;
		}
		
		// Execute block
		REObserverHandler block;
		block = observingInfo[REObserverBlockKey];
		if (!block) {
			return;
		}
		block(change);
	}
}

- (void)REObserver_X_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath
{
	@synchronized (self) {
		// Get observingInfos
		NSMutableArray *observingInfos;
		observingInfos = [observer associatedValueForKey:kObservingInfosKey];
		
		// Get observedInfos
		NSMutableArray *observedInfos;
		observedInfos = [self associatedValueForKey:kObservedInfosKey];
		
		// Remove observingInfo
		[observingInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observingInfo, NSUInteger idx, BOOL *stop) {
			if (observingInfo[REObserverObservedObjectKey] == self
				&& [observingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				&& observingInfo[REObserverContextPointerValueKey] == nil
			){
				// Release block
				id block;
				block = observingInfo[REObserverBlockKey];
				if (block) {
					Block_release(block);
				}
				
				// Remove observingInfo
				[observingInfos removeObject:observingInfo];
			}
		}];
		
		// Remove observedInfo
		[observedInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
			if (observedInfo[REObserverObservingObjectKey] == observer
				&& [observedInfo[REObserverKeyPathKey] isEqualToString:keyPath]
				&& observedInfo[REObserverContextPointerValueKey] == nil
			){
				// Remove observedInfo
				[observedInfos removeObject:observedInfo];
			}
		}];
	}
	
	// original
	[self REObserver_X_removeObserver:observer forKeyPath:keyPath];
}

- (void)REObserver_X_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context
{
	if (context) {
		@synchronized (self) {
			// Get observingInfos
			NSMutableArray *observingInfos;
			observingInfos = [observer associatedValueForKey:kObservingInfosKey];
			
			// Get observedInfos
			NSMutableArray *observedInfos;
			observedInfos = [self associatedValueForKey:kObservedInfosKey];
			
			// Remove observingInfo
			[observingInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observingInfo, NSUInteger idx, BOOL *stop) {
				if (observingInfo[REObserverObservedObjectKey] == self
					&& [observingInfo[REObserverKeyPathKey] isEqualToString:keyPath]
					&& [observingInfo[REObserverContextPointerValueKey] pointerValue] == context
				){
					// Release block
					id block;
					block = observingInfo[REObserverBlockKey];
					if (block) {
						Block_release(block);
					}
					
					// Remove observingInfo
					[observedInfos removeObject:observingInfo];
					[observingInfos removeObject:observingInfo];
				}
			}];
			
			// Remove observedInfo
			[observedInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
				if (observedInfo[REObserverObservingObjectKey] == observer
					&& [observedInfo[REObserverKeyPathKey] isEqualToString:keyPath]
					&& [observedInfo[REObserverContextPointerValueKey] pointerValue] == context
				){
					[observedInfos removeObject:observedInfo];
				}
			}];
		}
	}
	
	// original
	[self REObserver_X_removeObserver:observer forKeyPath:keyPath context:context];
}

- (void)REObserver_X_willBecomeInstanceOfClass:(Class)aClass
{
	// Remove observers
	NSArray *observedInfos;
	observedInfos = [self observedInfos];
	[observedInfos enumerateObjectsUsingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
		if (observedInfo[REObserverContextPointerValueKey]) {
			[self REObserver_X_removeObserver:observedInfo[REObserverObservingObjectKey] forKeyPath:observedInfo[REObserverKeyPathKey] context:[observedInfo[REObserverContextPointerValueKey] pointerValue]];
		}
		else {
			[self REObserver_X_removeObserver:observedInfo[REObserverObservingObjectKey] forKeyPath:observedInfo[REObserverKeyPathKey]];
		}
	}];
	
	// original
	[self REObserver_X_willBecomeInstanceOfClass:aClass];
}

- (void)REObserver_X_didBecomeInstanceOfClass:(Class)aClass
{
	// original
	[self REObserver_X_didBecomeInstanceOfClass:aClass];
	
	// Add observers removed in willBecomeInstanceOfClass: method
	[[self observedInfos] enumerateObjectsUsingBlock:^(NSDictionary *observedInfo, NSUInteger idx, BOOL *stop) {
		[self REObserver_X_addObserver:observedInfo[REObserverObservingObjectKey] forKeyPath:observedInfo[REObserverKeyPathKey] options:[observedInfo[REObserverOptionsKey] integerValue] context:[observedInfo[REObserverContextPointerValueKey] pointerValue]];
	}];
}

- (void)REObserver_X_dealloc
{
	// Stop observing
	[self stopObserving];
	
	// original
	[self REObserver_X_dealloc];
}

+ (void)load
{
	@autoreleasepool {
		// Exchange methods…
		[self exchangeInstanceMethodsWithAdditiveSelectorPrefix:@"REObserver_X_" selectors:
			@selector(addObserver:forKeyPath:options:context:),
			@selector(observeValueForKeyPath:ofObject:change:context:),
			@selector(removeObserver:forKeyPath:),
			@selector(removeObserver:forKeyPath:context:),
			@selector(willBecomeInstanceOfClass:),
			@selector(didBecomeInstanceOfClass:),
			@selector(dealloc),
			nil
		];
	}
}

//--------------------------------------------------------------//
#pragma mark -- Observer --
//--------------------------------------------------------------//

- (id)addObserverForKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options usingBlock:(REObserverHandler)block
{
	// Filter
	if (![keyPath length] || !block) {
		return nil;
	}
	
	// Make observer
	id observer;
	observer = [[NSObject alloc] init];
	
	// Add observer to self
	[self addObserver:observer forKeyPath:keyPath options:options context:NULL];
	
	// Get copied block
	id copiedBock;
	copiedBock = Block_copy(block);
	
	// Add block to observingInfo
	NSMutableDictionary *observingInfo;
	observingInfo = (id)[[observer observingInfos] lastObject];
	[observingInfo setObject:copiedBock forKey:REObserverBlockKey];
	
	// Add block to observedInfo
	NSMutableDictionary *observedInfo;
	observedInfo = (id)[[self observedInfos] lastObject];
	[observedInfo setObject:copiedBock forKey:REObserverBlockKey];
	
	return [observer autorelease];
}

- (NSArray*)observingInfos
{
	// Get observingInfo
	NSArray *observingInfos;
	@synchronized (self) {
		observingInfos = [NSArray arrayWithArray:[self associatedValueForKey:kObservingInfosKey]];
	}
	
	return observingInfos;
}

- (NSArray*)observedInfos
{
	// Get observedInfos
	NSArray *observedInfos;
	@synchronized (self) {
		observedInfos = [NSArray arrayWithArray:[self associatedValueForKey:kObservedInfosKey]];
	}
	
	return observedInfos;
}

- (void)stopObserving
{
	@synchronized (self) {
		// Enumerate observingInfos
		NSMutableArray *observingInfos;
		observingInfos = [self associatedValueForKey:kObservingInfosKey];
		while ([observingInfos count]) {
			NSDictionary *observingInfo;
			observingInfo = [observingInfos lastObject];
			
			// Stop observing
			id object;
			NSString *keyPath;
			NSValue *contextPointerValue;
			object = observingInfo[REObserverObservedObjectKey];
			keyPath = observingInfo[REObserverKeyPathKey];
			contextPointerValue = observingInfo[REObserverContextPointerValueKey];
			[object removeObserver:self forKeyPath:keyPath context:[contextPointerValue pointerValue]];
		}
	}
}

@end
