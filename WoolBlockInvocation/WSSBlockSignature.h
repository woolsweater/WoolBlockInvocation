//
//  WSSBlockSignature.h
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import <Foundation/Foundation.h>

@interface WSSBlockSignature : NSObject

/* Create a Block signature object representing the given encoding string. */
+ (instancetype)signatureWithObjCTypes:(const char *)types;

/* Create a Block signature object representing the signature of the
 * given Block.
 */
+ (instancetype)signatureForBlock:(id)block;

/* The @encode string for the argument at the specified index. */
- (const char *)argumentTypeAtIndex:(NSUInteger)idx;
- (BOOL)argumentAtIndexIsObject:(NSUInteger)idx;
- (BOOL)argumentAtIndexIsPointer:(NSUInteger)idx;
/* The size in bytes of the argument type at the specified index. */
- (NSUInteger)sizeOfArgumentAtIndex:(NSUInteger)idx;
- (NSUInteger)numberOfArguments;

/* The @encode string for the return type. */
- (const char *)returnType;
- (BOOL)returnTypeIsObject;
/* The size in bytes of the return type. */
- (NSUInteger)returnLength;

@end