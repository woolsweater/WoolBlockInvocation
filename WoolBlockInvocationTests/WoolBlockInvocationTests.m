//
//  WoolBlockInvocationTests.m
//  WoolBlockInvocationTests
//
//  Created by Joshua Caswell on 7/22/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import "WoolBlockInvocationTests.h"

#import "WSSBlockInvocation.h"

#define INT_CONST 10
#define FLOAT_CONST 10.0f

@implementation WoolBlockInvocationTests
{
    dispatch_block_t void_b1;
    dispatch_block_t void_b2;
    dispatch_block_t void_b3;
    
    int (^int_b1)(void);
    float (^float_b1)(void);
    
    WSSBlockInvocation * blockInvocation;
}

- (void)setUp
{
    void_b1 = ^{};
    void_b2 = ^{};
    void_b3 = ^{};
    
    int_b1 = ^{ return INT_CONST; };
    float_b1 = ^{ return FLOAT_CONST; };
    
    [super setUp];
}

- (void)tearDown
{
    blockInvocation = nil;
    [super tearDown];
}

- (void)testSettingBlockLeavesOnlyOneBlock
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[void_b1, void_b2, void_b3]];
    
    [blockInvocation setBlock:^{}];
    
    NSUInteger count = [[blockInvocation allBlocks] count];
    STAssertEquals((NSUInteger)1, count, @"Using setBlock: should leave only one Block in "
                   "the invocation's list. Have %ld", count);
}

- (void)testCreatingWithMismatchedSigsFails
{
    void (^typed_b)(NSString *) = ^(NSString * s){};
    
    STAssertThrows((blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[void_b1, void_b2, typed_b]]),
                   @"Creating an invocation with Blocks of varied signatures should raise.");
}

- (void)testAskingForReturnValueBeforeInvokingFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1]];

    int ret_val;
    STAssertThrows([blockInvocation getReturnValue:&ret_val], nil);
}

- (void)testAskingForSingleReturnValueWithMultipleBlocksFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1, [int_b1 copy], [int_b1 copy]]];
    
    int ret_val;
    STAssertThrows([blockInvocation getReturnValue:&ret_val], nil);
}

- (void)testSingleIntegerReturnValue
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1]];
    
    [blockInvocation invoke];
    int retVal;
    [blockInvocation getReturnValue:&retVal];
    STAssertEquals(retVal, INT_CONST,
                   @"Expected %d but got %d", INT_CONST, retVal);

}

- (void)testSingleObjectReturnValue
{
    NSObject * o = [NSObject new];
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^{ return o;}]];
    [blockInvocation invoke];
    
    void * return_p;
    [blockInvocation getReturnValue:&return_p];
    // ARC will emit an extra release if this is not __unsafe_unretained
    id retVal = (__bridge __unsafe_unretained id)return_p;
    
    STAssertEquals(o, retVal, nil);
}

- (void)testSingleFloatReturnValue
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[float_b1]];
    
    [blockInvocation invoke];
    float retVal;
    [blockInvocation getReturnValue:&retVal];
    
    STAssertEquals(retVal, FLOAT_CONST,
                   @"Expected %f but got %f", FLOAT_CONST, retVal);
}

- (void)testMultipleIntegerReturnValues
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1, [int_b1 copy], [int_b1 copy]]];
    
    [blockInvocation invoke];
    NSUInteger numVals = [[blockInvocation allBlocks] count];
    void ** retValues = [blockInvocation getReturnValues];
    
    for( NSUInteger i = 0; i < numVals; i++ ){
        int retVal = *(int *)(retValues[i]);
        
        STAssertEquals(retVal, INT_CONST,
                       @"Expected %d for Block %ld of %ld but got %d",
                       INT_CONST, i+1, numVals, retVal);
    }
}

- (void)testMultipleFloatReturnValues
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[float_b1, [float_b1 copy], [float_b1 copy]]];
    
    [blockInvocation invoke];
    
    void ** returnValues = [blockInvocation getReturnValues];
    
    NSUInteger numBlocks = [[blockInvocation allBlocks] count];
    
    for( NSUInteger i = 0; i < numBlocks; i++ ){
        float retVal = *(float *)(returnValues[i]);
        
        STAssertEquals(retVal, FLOAT_CONST,
                       @"Expected %f for Block %ld of %ld but got %f",
                       FLOAT_CONST, i+1, numBlocks, retVal);
    }
}

- (void)testMultipleObjectReturnValues
{
    NSObject * o = [NSObject new];
    id (^object_b)(void) = ^{ return o; };
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[object_b, [object_b copy], [object_b copy]]];
    
    [blockInvocation invoke];
    
    NSUInteger numVals = [[blockInvocation allBlocks] count];
    void ** retValues = [blockInvocation getReturnValues];
    
    for( NSUInteger i = 0; i < numVals; i++ ){
        // ARC will emit an extra release if this is not __unsafe_unretained
        id retVal = (__bridge __unsafe_unretained id)retValues[i];
        
        STAssertEquals(retVal, o,
                       @"Expected %@ for Block %ld of %ld but got %@",
                       o, i+1, numVals, retVal);
    }
    free(retValues);
}


@end
