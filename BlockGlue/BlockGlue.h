//
//  BlockGlue.h
//  BlockGlue
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BlockSignature;

@interface BlockGlue : NSObject

+ (instancetype)blockGlueWithSignature:(BlockSignature *)sig;

- (BlockSignature *)blockSignature;

- (void)setBlock:(id)block;
- (void)addBlock:(id)block;
- (id)blockAtIndex:(NSUInteger)idx;
- (NSArray *)allBlocks;

- (void)setArgument:(void *)arg atIndex:(NSInteger)idx;
- (void)getArgument:(void *)arg atIndex:(NSInteger)idx;

@property (assign, nonatomic) BOOL retainsArguments;

- (void)getReturnValue:(void *)buffer;
- (void * const *)returnValues;

- (void)invoke;
- (id)invocationBlock;

@end
