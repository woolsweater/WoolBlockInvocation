//
//  WoolBlockInvocationTests.m
//  WoolBlockInvocationTests
//
//  Created by Joshua Caswell on 7/22/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

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

- (void)testCreatingWithMismatchedSigsFails
{
    void (^typed_b)(NSString *) = ^(NSString * s){};
    
    STAssertThrows((blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[void_b1, void_b2, typed_b]]),
                   @"Creating an invocation with Blocks of varied signatures should raise.");
}

- (void)testAddingBlockWithMismatchedSigFails
{
    void (^typed_b)(NSString *) = ^(NSString * s){};
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[void_b1]];
    
    STAssertThrows([blockInvocation addBlock:typed_b],
                   @"Adding a Block with different signature should raise.");
}

- (void)testSettingBlocksArrayWithMismatchedSigsFails
{
    void (^typed_b)(NSString *) = ^(NSString * s){};
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[typed_b]];
    
    STAssertThrows(([blockInvocation setBlocks:@[void_b1, void_b2]]),
                   @"Setting new array of Blocks with signature not matching "
                   "original should raise.");
}

- (void)testSettingArgumentInSlotForBlockFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[void_b1]];

    STAssertThrows([blockInvocation setArgument:NULL atIndex:0],
                   @"Trying to set an argument for index 0 should raise.");
}

- (void)testAskingForReturnValueBeforeInvokingFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1]];

    int retVal;
    STAssertThrows([blockInvocation getReturnValue:&retVal fromIndex:0], nil);
}

- (void)testAskingForSingleReturnValueWithMultipleBlocksFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1, [int_b1 copy], [int_b1 copy]]];
    
    int retVal;
    STAssertThrows([blockInvocation getReturnValue:&retVal fromIndex:0], nil);
}

- (void)testInvokingWithoutSettingArgumentsFails
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^(NSString * s){}]];
    
    STAssertThrows([blockInvocation invoke],
                   @"Invoking without having set arguments should raise.");
}

- (void)testSingleIntegerReturnValue
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1]];
    
    [blockInvocation invoke];
    int retVal;
    [blockInvocation getReturnValue:&retVal fromIndex:0];
    STAssertEquals(retVal, INT_CONST,
                   @"Expected %d but got %d", INT_CONST, retVal);

}

- (void)testSingleObjectReturnValue
{
    NSObject * o = [NSObject new];
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^{ return o;}]];
    [blockInvocation invoke];
    
    void * return_p;
    [blockInvocation getReturnValue:&return_p fromIndex:0];
    // ARC will emit an extra release if this is not __unsafe_unretained
    id retVal = (__bridge __unsafe_unretained id)return_p;
    
    STAssertEquals(o, retVal, nil);
}

- (void)testSingleFloatReturnValue
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[float_b1]];
    
    [blockInvocation invoke];
    float retVal;
    [blockInvocation getReturnValue:&retVal fromIndex:0];
    
    STAssertEquals(retVal, FLOAT_CONST,
                   @"Expected %f but got %f", FLOAT_CONST, retVal);
}

- (void)testMultipleIntegerReturnValues
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[int_b1, [int_b1 copy], [int_b1 copy]]];
    
    [blockInvocation invoke];
    NSUInteger numVals = [blockInvocation numberOfBlocks];
    void ** retValues = [blockInvocation copyReturnValues];
    
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
    
    void ** returnValues = [blockInvocation copyReturnValues];
    
    NSUInteger numBlocks = [blockInvocation numberOfBlocks];
    
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
    
    NSUInteger numVals = [blockInvocation numberOfBlocks];
    void ** retValues = [blockInvocation copyReturnValues];
    
    for( NSUInteger i = 0; i < numVals; i++ ){
        // ARC will emit an extra release if this is not __unsafe_unretained
        id retVal = (__bridge __unsafe_unretained id)retValues[i];
        
        STAssertEquals(retVal, o,
                       @"Expected %@ for Block %ld of %ld but got %@",
                       o, i+1, numVals, retVal);
    }
    free(retValues);
}

- (void)testSingleIntegerArgument
{
    void (^b_int)(int) = ^(int i){
        STAssertEquals(i, INT_CONST, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_int]];
    
    int arg = INT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    [blockInvocation invoke];
}

- (void)testSingleFloatArgument
{
    void (^b_float)(float) = ^(float f){
        STAssertEquals(f, FLOAT_CONST, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_float]];
    
    float arg = FLOAT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    [blockInvocation invoke];
}

- (void)testSingleObjectArgument
{
    NSObject * o = [NSObject new];
    void (^b_obj)(id) = ^(id obj_arg){
        STAssertEquals(obj_arg, o, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_obj]];
    
    [blockInvocation setArgument:&o atIndex:1];
    
    [blockInvocation invoke];
}

- (void)testSingleIntegerArgumentWithRetainsArguments
{
    void (^b_int)(int) = ^(int i){
        STAssertEquals(i, INT_CONST, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_int]];
    [blockInvocation setRetainsArguments:YES];
    
    int arg = INT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    [blockInvocation invoke];
}

- (void)testSingleFloatArgumentWithRetainsArguments
{
    void (^b_float)(float) = ^(float f){
        STAssertEquals(f, FLOAT_CONST, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_float]];
    [blockInvocation setRetainsArguments:YES];
    
    float arg = FLOAT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    [blockInvocation invoke];
}

- (void)testSingleObjectArgumentWithRetainsArguments
{
    NSObject * o = [NSObject new];
    void (^b_obj)(id) = ^(id obj_arg){
        STAssertEquals(obj_arg, o, nil);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b_obj]];
    [blockInvocation setRetainsArguments:YES];
    
    [blockInvocation setArgument:&o atIndex:1];
    
    [blockInvocation invoke];
}


typedef void (^StringBlock)(NSString *, NSString *, int);

- (void)testMultipleArguments
{
    NSString * arg = @"It's the first time an artist of such stature has taken the A272.";
    NSString * arg2 = @"the";
    int intarg = 3;
    
    NSString * checkString = [arg stringByReplacingOccurrencesOfString:arg2
                                                            withString:[NSString stringWithFormat:@"%d", intarg]];
    
    StringBlock b = ^(NSString * s, NSString * r, int i){
        NSString * transformed;
        transformed = [s stringByReplacingOccurrencesOfString:r
                                                   withString:[NSString stringWithFormat:@"%d", i]];
        STAssertTrue([transformed isEqualToString:checkString],
                     @"Expected «%@» but got «%@»", checkString, transformed);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b]];
    
    [blockInvocation setArgument:&arg atIndex:1];
    [blockInvocation setArgument:&arg2 atIndex:2];
    [blockInvocation setArgument:&intarg atIndex:3];
    
    [blockInvocation invoke];
    
}

- (void)testInvocationBlock
{
    NSString * arg = @"It's the first time an artist of such stature has taken the A272.";
    NSString * arg2 = @"the";
    int intarg = 3;
    
    NSString * checkString1 = [arg stringByReplacingOccurrencesOfString:arg2
                                                             withString:[NSString stringWithFormat:@"%d", intarg]];
    
    StringBlock b1 = ^(NSString * s, NSString * r, int i){
        NSString * transformed;
        transformed = [s stringByReplacingOccurrencesOfString:r
                                                   withString:[NSString stringWithFormat:@"%d", i]];
        STAssertTrue([transformed isEqualToString:checkString1],
                     @"Expected «%@» but got «%@»", checkString1, transformed);
    };
    
    NSString * checkString2 = [[arg componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] objectAtIndex:intarg];
    
    StringBlock b2 = ^(NSString * s, NSString * r, int i){
        NSString * transformed = [[s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] objectAtIndex:i];
        STAssertTrue([transformed isEqualToString:checkString2],
                     @"Expected «%@» but got «%@»", checkString2, transformed);
    };
    
    NSMutableString * checkString3 = [NSMutableString stringWithString:arg];
    for( int i = 0; i < intarg; i++ ){
        [checkString3 appendString:arg2];
    }
    
    StringBlock b3 = ^(NSString * s, NSString * r, int i){
        NSString * transformed = s;
        for( int j = 0; j < i; j++ ){
            transformed = [transformed stringByAppendingString:r];
        }
        STAssertTrue([transformed isEqualToString:checkString3],
                     @"Expected «%@» but got «%@»", checkString3, s);
    };
    
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[b1, b2, b3]];
    
    StringBlock capsule = (StringBlock)[blockInvocation invocationBlock];
    
    capsule(arg, arg2, intarg);
}

- (void)testGetIntegerArgument
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^(int i){}]];
    
    int arg = INT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    int arg_get;
    [blockInvocation getArgument:&arg_get atIndex:1];
    
    STAssertEquals(arg, arg_get, nil);
}

- (void)testGetFloatArgument
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^(float f){}]];
    
    float arg = FLOAT_CONST;
    [blockInvocation setArgument:&arg atIndex:1];
    
    float arg_get;
    [blockInvocation getArgument:&arg_get atIndex:1];
    
    STAssertEquals(arg, arg_get, nil);
}

- (void)testGetObjectArgument
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^(id o){}]];
    
    id arg = [NSObject new];
    [blockInvocation setArgument:&arg atIndex:1];
    
    __unsafe_unretained id arg_get;
    [blockInvocation getArgument:&arg_get atIndex:1];
    
    STAssertEquals(arg, arg_get, nil);
}

- (void)testGettingReturnValuesAfterUsingInvocationBlock
{
    blockInvocation = [WSSBlockInvocation invocationWithBlocks:@[^{return INT_CONST;}, ^{return INT_CONST;}, ^{return INT_CONST;}]];
    
    int (^capsule)(void) = [blockInvocation invocationBlock];
    
    capsule();
    
    NSUInteger numVals = [blockInvocation numberOfBlocks];
    void ** retValues = [blockInvocation copyReturnValues];
    
    for( NSUInteger i = 0; i < numVals; i++ ){
        int retVal = *(int *)(retValues[i]);
        
        STAssertEquals(retVal, INT_CONST,
                       @"Expected %d for Block %ld of %ld but got %d",
                       INT_CONST, i+1, numVals, retVal);
    }
}

@end
