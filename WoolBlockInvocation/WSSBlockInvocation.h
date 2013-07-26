//
//  WSSBlockInvocation.h
//  WoolBlockInvocaiton
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WSSBlockSignature;

@interface WSSBlockInvocation : NSObject

+ (instancetype)invocationWithBlocks:(NSArray *)blocks;

+ (instancetype)invocationWithSignature:(WSSBlockSignature *)sig;

- (WSSBlockSignature *)blockSignature;

- (void)setBlock:(id)block;
- (void)addBlock:(id)block;
- (void)setBlocks:(NSArray *)blocks;
- (id)blockAtIndex:(NSUInteger)idx;
- (NSArray *)allBlocks;

- (void)setArgument:(void *)arg atIndex:(NSInteger)idx;
- (void)getArgument:(void *)arg atIndex:(NSInteger)idx;

@property (assign, nonatomic) BOOL retainsArguments;

- (void)getReturnValue:(void *)buffer;
/* Provides list of return values that is owned by the caller. */
- (void **)copyReturnValues;

- (void)invoke;

/* Return a block which encapsulates the invocation of all the Blocks.
 * This probably only makes sense for a Block signature with void return, but
 * there is no actual restriction imposed. The return values can be retrieved
 * via copyReturnValues after the capsule Block runs if desired.
 */
- (id)invocationBlock;

@end
