//
//  WSSBlockSignature.h
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import <Foundation/Foundation.h>

@interface WSSBlockSignature : NSObject

+ (instancetype)signatureWithObjCTypes:(const char *)types;
+ (instancetype)signatureForBlock:(id)block;

- (const char *)argumentTypeAtIndex:(NSUInteger)idx;
- (BOOL)argumentAtIndexIsObject:(NSUInteger)idx;
- (BOOL)argumentAtIndexIsPointer:(NSUInteger)idx;

- (NSUInteger)sizeOfArgumentAtIndex:(NSUInteger)idx;
- (NSUInteger)numberOfArguments;
- (NSUInteger)frameLength;
- (const char *)returnType;
- (BOOL)returnTypeIsObject;
- (NSUInteger)returnSize;

@end