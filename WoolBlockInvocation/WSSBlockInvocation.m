//
//  WSSBlockInvocation.m
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import "WSSBlockInvocation.h"
#import "WSSBlockSignature.h"

#import "WoolBlockHelper.h"

#include <ffi/ffi.h>

ffi_type * libffi_type_for_objc_encoding(const char * str);

@interface WSSBlockInvocation ()

- (id)initWithBlockSignature:(WSSBlockSignature *)sig;
- (void *)allocate:(size_t)size;

/**
 * Construct a list of ffi_type * describing the method signature of this
 * invocation. 
 */
- (ffi_type **)buildFFIArgTypeList;

@end

@implementation WSSBlockInvocation
{
    WSSBlockSignature * blockSignature;
    NSMutableArray * blocks;
    void ** return_values;
    void ** arguments;
    NSMutableArray * allocations;
    NSMutableArray * retainedArgs;
    NSMutableArray * retainedReturnValues;
}

+ (instancetype)invocationWithBlocks:(NSArray *)blocks
{
    WSSBlockSignature * sig = [WSSBlockSignature signatureForBlock:blocks[0]];
    id newinstance = [[self alloc] initWithBlockSignature:sig];
    
    [newinstance setBlocks:blocks];
    
    return newinstance;
    
}

+ (instancetype)invocationWithSignature:(WSSBlockSignature *)sig
{
    return [[self alloc] initWithBlockSignature:sig];
}

- (id)init
{
    [NSException raise:NSInvalidArgumentException
                format:@"Use invocationWithSignature: or invocationWithBlocks:"
                        " to create a new instance"];
    return nil;
}

- (id)initWithBlockSignature:(WSSBlockSignature *)sig
{
    self = [super init];
    if( !self ) return nil;
    
    blockSignature = sig;
    blocks = [NSMutableArray new];
    allocations = [NSMutableArray new];
    arguments = [self allocate:(sizeof(void *) *
                                [blockSignature numberOfArguments])];
    arguments[0] = [self allocate:sizeof(id)];
    
    return self;
}

@synthesize retainsArguments;

- (void *)allocate:(size_t)size
{
    NSMutableData * dat = [NSMutableData dataWithLength:size];
    [allocations addObject:dat];
    
    return [dat mutableBytes];
}

- (WSSBlockSignature *)blockSignature
{
    return blockSignature;
}

- (NSUInteger)blockReturnLength
{
    return [blockSignature returnLength];
}

- (void)setRetainsArguments:(BOOL)shouldRetainArguments
{
    if( shouldRetainArguments && !retainedArgs ){
        retainedArgs = [NSMutableArray new];
    }
    
    retainsArguments = shouldRetainArguments;
}

- (NSUInteger)numberOfBlocks
{
    return [blocks count];
}

- (void)addBlock:(id)block
{
    WSSBlockSignature * newSig = [WSSBlockSignature signatureForBlock:block];
    NSAssert([newSig isEqual:blockSignature],
             @"Signature for added Block (%@) does not match existing "
             "signature (%@) for %@", newSig, blockSignature, self);
    [blocks addObject:block];
}

- (void)setBlocks:(NSArray *)newBlocks
{
    // Go through addBlock: rather than directly adding to array
    // so that the signatures are checked.
    [blocks removeAllObjects];
    for( id block in newBlocks ){
        [self addBlock:block];
    }
}

- (id)blockAtIndex:(NSUInteger)idx
{
    return [blocks objectAtIndex:idx];
}

- (NSArray *)allBlocks
{
    return [blocks copy];
}

- (void)setArgument:(void *)arg atIndex:(NSInteger)idx
{
    NSAssert(idx != 0,
             @"Argument 0 is reserved for a pointer to the invoked Block");
    NSAssert(idx < [blockSignature numberOfArguments],
             @"Setting argument at index %ld out of range for number of "
             "arguments %ld", idx, [blockSignature numberOfArguments]);
    
    size_t size = [blockSignature sizeOfArgumentAtIndex:idx];
    arguments[idx] = [self allocate:size];
    if( retainsArguments && [blockSignature argumentAtIndexIsObject:idx] ){
        id obj = (__bridge id)*(void **)arg;
        [retainedArgs addObject:obj];
    }
    memcpy(arguments[idx], arg, size);
}

- (void)getArgument:(void *)buffer atIndex:(NSInteger)idx
{
    memcpy(buffer, arguments[idx], [blockSignature sizeOfArgumentAtIndex:idx]);
}

- (void)getReturnValue:(void *)buffer
{
    [self getReturnValue:buffer fromIndex:0];
}

- (void)getReturnValue:(void *)buffer fromIndex:(NSUInteger)idx
{
    NSAssert(return_values != NULL, @"No return value set for %@", self);
    NSAssert([blocks count] > idx,
             @"Getting return value at index %ld out of range for number of "
             "Blocks %ld", idx, [blocks count]);
    
    memcpy(buffer, return_values[idx], [blockSignature returnLength]);
}

- (void **)copyReturnValues
{
    NSAssert(return_values != NULL, @"No return value set for %@", self);
    
    void ** buffer = malloc(sizeof(void *) * [blocks count]);
    if( [blockSignature returnTypeIsObject] ){
        
        // Casting through void * here doesn't seem correct, but it's the only
        // way to get the compiler not to complain -- __bridge casts error out
        // http://brokaw.github.io/2012/10/18/casting-indirect-pointers-with-arc.html
        // has some related information.
        [retainedReturnValues getObjects:(__unsafe_unretained id *)(void *)buffer
                                   range:(NSRange){0, [blocks count]}];
    }
    else {
        NSUInteger return_size = [blockSignature returnLength];
        for( NSUInteger i = 0; i < [blocks count]; i++ ){
            buffer[i] = malloc(return_size);
            memcpy(buffer[i], return_values[i], return_size);
        }
    }
    
    return buffer;
}

- (void)invoke
{
    NSAssert([blocks count] > 0,
             @"Cannot invoke %@ without at least one Block", self);
    if( [blockSignature numberOfArguments] > 1 ){
        NSAssert(arguments[1] != NULL,
                 @"Cannot invoke %@ without arguments having been set", self);
    }
    
    NSUInteger num_args = [blockSignature numberOfArguments];
    
    ffi_type ** arg_types = [self buildFFIArgTypeList];
    ffi_type * return_type;
    return_type = libffi_type_for_objc_encoding([blockSignature returnType]);
    
    NSUInteger return_size = [blockSignature returnLength];
    BOOL doRetainReturnVals = NO;
    if( return_size > 0 ){
        
        return_values = [self allocate:sizeof(void *) * [blocks count]];
        
        doRetainReturnVals = [blockSignature returnTypeIsObject];
        if( doRetainReturnVals ){
            retainedReturnValues = [NSMutableArray new];
        }
    }

    ffi_cif inv_cif;
    ffi_status prep_status = ffi_prep_cif(&inv_cif, FFI_DEFAULT_ABI,
                                          (unsigned int)num_args,
                                          return_type, arg_types);
    NSAssert(prep_status == FFI_OK, @"ffi_prep_cif() failed for", self);
    
    for( NSUInteger idx = 0; idx < [blocks count]; idx++ ){
        
        void * return_val = NULL;
        if( return_size > 0 ){
            return_values[idx] = [self allocate:return_size];
            return_val = return_values[idx];
            NSAssert(return_values[idx] != NULL,
                     @"%@ failed to allocate space for return value", self);
        }
        
        void * currBlock = (__bridge void *)[blocks objectAtIndex:idx];
        memcpy(arguments[0], &currBlock, sizeof(id));
        ffi_call(&inv_cif, BlockIMP((__bridge id)currBlock),
                 return_val, arguments);
        
        if( doRetainReturnVals ){
            [retainedReturnValues addObject:(__bridge id)*(void **)return_val];
        }
    }
}

- (id)invocationBlock
{
    return [^void (void * arg1, ...){
        [self setRetainsArguments:YES];
        va_list args;
        va_start(args, arg1);
        void * arg = arg1;
        NSUInteger numArguments = [blockSignature numberOfArguments];
        for( NSUInteger idx = 1; idx < numArguments; idx++ ){
            
            [self setArgument:&arg atIndex:idx];
            
            arg = va_arg(args, void *);
        }
        va_end(args);
        
        [self invoke];
    
    } copy];
}

/**
 * Construct a list of ffi_type * describing the method signature of this
 * invocation. Steps through each argument in turn and interprets the ObjC
 * type encoding.
 */
- (ffi_type **)buildFFIArgTypeList
{
    NSUInteger num_args = [blockSignature numberOfArguments];
    ffi_type ** arg_types = [self allocate:sizeof(ffi_type *) * num_args];
    for( NSUInteger idx = 0; idx < num_args; idx++ ){
        arg_types[idx] = libffi_type_for_objc_encoding([blockSignature argumentTypeAtIndex:idx]);
    }
    
    return arg_types;
}

@end

/* ffi_type structures for common Cocoa structs */

/* N.B.: ffi_type constructions must be created and added as possible return
 * values from libffi_type_for_objc_encoding below for any custom structs that
 * will be encountered by the invocation. If libffi_type_for_objc_encoding
 * fails to find a match, it will abort.
 */
#if CGFLOAT_IS_DOUBLE
#define CGFloatFFI &ffi_type_double
#else
#define CGFloatFFI &ffi_type_float
#endif

static ffi_type CGPointFFI = (ffi_type){ .size = 0,
    .alignment = 0,
    .type = FFI_TYPE_STRUCT,
    .elements = (ffi_type * [3]){CGFloatFFI,
        CGFloatFFI,
        NULL}};


static ffi_type CGSizeFFI = (ffi_type){ .size = 0,
    .alignment = 0,
    .type = FFI_TYPE_STRUCT,
    .elements = (ffi_type * [3]){CGFloatFFI,
        CGFloatFFI,
        NULL}};

static ffi_type CGRectFFI = (ffi_type){ .size = 0,
    .alignment = 0,
    .type = FFI_TYPE_STRUCT,
    .elements = (ffi_type * [3]){&CGPointFFI,
        &CGSizeFFI, NULL}};

/**
 * Translate an ObjC encoding string into a pointer to the appropriate
 * libffi type; this covers the CoreGraphics structs defined above,
 * and, on OS X, the AppKit equivalents.
 */
ffi_type * libffi_type_for_objc_encoding(const char * str)
{
    /* Slightly modfied version of Mike Ash's code from
     * https://github.com/mikeash/MABlockClosure/blob/master/MABlockClosure.m
     * Copyright (c) 2010, Michael Ash
     * All rights reserved.
     * Distributed under a BSD license. See MA_LICENSE.txt for details.
     */
#define SINT(type) do { \
if(str[0] == @encode(type)[0]) \
{ \
if(sizeof(type) == 1) \
return &ffi_type_sint8; \
else if(sizeof(type) == 2) \
return &ffi_type_sint16; \
else if(sizeof(type) == 4) \
return &ffi_type_sint32; \
else if(sizeof(type) == 8) \
return &ffi_type_sint64; \
else \
{ \
NSLog(@"fatal: %s, unknown size for type %s", __func__, #type); \
abort(); \
} \
} \
} while(0)
    
#define UINT(type) do { \
if(str[0] == @encode(type)[0]) \
{ \
if(sizeof(type) == 1) \
return &ffi_type_uint8; \
else if(sizeof(type) == 2) \
return &ffi_type_uint16; \
else if(sizeof(type) == 4) \
return &ffi_type_uint32; \
else if(sizeof(type) == 8) \
return &ffi_type_uint64; \
else \
{ \
NSLog(@"fatal: %s, unknown size for type %s", __func__, #type); \
abort(); \
} \
} \
} while(0)
    
#define INT(type) do { \
SINT(type); \
UINT(unsigned type); \
} while(0)
    
#define COND(type, name) do { \
if(str[0] == @encode(type)[0]) \
return &ffi_type_ ## name; \
} while(0)
    
#define PTR(type) COND(type, pointer)
    
#define STRUCT(structType, retType) do { \
if(strncmp(str, @encode(structType), strlen(@encode(structType))) == 0) \
{ \
return retType; \
} \
} while(0)
    
    SINT(_Bool);
    SINT(signed char);
    UINT(unsigned char);
    INT(short);
    INT(int);
    INT(long);
    INT(long long);
    
    PTR(id);
    PTR(Class);
    //    PTR(Protocol);
    PTR(SEL);
    PTR(void *);
    PTR(char *);
    PTR(void (*)(void));
    
    COND(float, float);
    COND(double, double);
    
    COND(void, void);
    
    // Mike Ash's code dynamically allocates ffi_types representing the
    // structures rather than statically defining them.
    STRUCT(CGPoint, &CGPointFFI);
    STRUCT(CGSize, &CGSizeFFI);
    STRUCT(CGRect, &CGRectFFI);
    
#if !TARGET_OS_IPHONE
    STRUCT(NSPoint, &CGPointFFI);
    STRUCT(NSSize, &CGSizeFFI);
    STRUCT(NSRect, &CGRectFFI);
#endif
    
    // Add custom structs here using
    // STRUCT(StructName, &ffi_typeForStruct);
    
    NSLog(@"fatal: %s, unknown encode string %s", __func__, str);
    abort();
}

/* End code from Mike Ash */