//
//  WSSBlockInvocation.h
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import <Foundation/Foundation.h>

@class WSSBlockSignature;

@interface WSSBlockInvocation : NSObject

/**
 * Create an object that can invoke each Block in \c blocks in turn, with the 
 * same set of arguments, storing any return values for later access.
 * Raises an exception if the signatures of the Blocks -- return type plus 
 * argument number and types -- do not match.
 */
+ (instancetype)invocationWithBlocks:(NSArray *)blocks;


/** Create an object which will accept only Blocks with the given signature. */
+ (instancetype)invocationWithSignature:(WSSBlockSignature *)sig;

/** The Block signaure for this invocation. */
- (WSSBlockSignature *)blockSignature;

/** The return type's length in bytes as indicated by the Block encoding. */
- (NSUInteger)blockReturnLength;

/** The number of Blocks represented by this invocation.
 *
 * This is just a convenience for \code [[theInvocation allBlocks] count]\endcode
 */
- (NSUInteger)numberOfBlocks;

/** 
 * Append \c block to the list of Blocks; an exception will be raised if the
 * new Block's signature does not match the existing signature.
 */
- (void)addBlock:(id)block;

/**
 * Remove all previous Blocks and use this array instead. An exception will be
 * raised if any of the signatures among the new Blocks' does not match the 
 * existing signature.
 */
- (void)setBlocks:(NSArray *)blocks;

/** Return the Block at the given index in the invocation's list of Blocks. */
- (id)blockAtIndex:(NSUInteger)idx;

/** Return a copy of the invocation's list of Blocks. */
- (NSArray *)allBlocks;


@property (assign, nonatomic) BOOL retainsArguments;

/**
 * Copy the contents of \c arg to be used as the argument at the specified 
 * index. The number of bytes copied is determined by the argument size.
 * Argument 0 is reserved for the Block itself, and trying to set it raises
 * an exception.
 */
- (void)setArgument:(void *)arg atIndex:(NSInteger)idx;

/**
 * Copy the argument at the specified index into the space pointed to by 
 * \c arg, which should be large enough to hold the value.
 */
- (void)getArgument:(void *)arg atIndex:(NSInteger)idx;

/** 
 * Copy the return value from the specified index into \c buffer, which should
 * be large enough to hold the value. Use \c blockReturnLength to determine the
 * appropriate size. 
 * Trying to access return values before the Blocks have been invoked or
 * accessing a return value at an invalid index raises an exception.
 */
- (void)getReturnValue:(void *)buffer fromIndex:(NSUInteger)idx;

/** A convenience for the return value at index 0. */
- (void)getReturnValue:(void *)buffer;

/**
 * Return a list, owned by the caller, containing the return values from the
 * invocation of all the Blocks. 
 * Trying to access this list before the Blocks have been invoked raises
 * an exception.
 */
- (void **)copyReturnValues;

/**
 * Invoke each Block in turn, passing itself as the first argument and the
 * invocation's set arguments for the remainder, saving any return values.
 * Trying to invoke without having set required arguments raises an exception.
 */
- (void)invoke;

/*
 * Return a block which encapsulates the invocation of all the Blocks.
 * This probably only makes sense for a Block signature with void return, but
 * there is no actual restriction imposed. The return values can be retrieved
 * via the return value accessors after the capsule Block runs, if desired.
 */
- (id)invocationBlock;

@end
