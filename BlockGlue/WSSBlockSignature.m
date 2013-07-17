//
//  WSSBlockSignature.m
//  WoolBlockInvocaiton
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import "WSSBlockSignature.h"

#import "WoolBlockHelper.h"
#import "WoolObjCEncoding.h"

@implementation WSSBlockSignature
{
    char * encoding;
    char ** argtypes;
    char * rettype;
    NSUInteger numargs;
}

+ (instancetype)signatureWithObjCTypes:(const char *)types
{
    id newinstance = [self new];
    if( !self ) return nil;
    
    [newinstance setEncoding:types];
    
    return [newinstance autorelease];
}

+ (instancetype)signatureForBlock:(id)block
{
    return [self signatureWithObjCTypes:BlockSig(block)];
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
    free(encoding);
    if( argtypes ){
        for( NSUInteger i = 0; i < numargs; i++ ){
            free(argtypes[i]);
        }
    }
    free(argtypes);
    free(rettype);
    [super dealloc];
}
#endif // Exclude if compiled with ARC


- (const char *)encoding
{
    return encoding;
}

static void parse_encoding_into_types(const char * encoding, NSUInteger numargs, char ** typesarray)
{
    for( NSUInteger idx = 0; idx < numargs; idx++ ){
        int ignored;
        char * arg = encoding_findArgument(encoding, (int)idx, &ignored);
        typesarray[idx] = arg_createTypeString(arg);
    }
}

- (void)setEncoding:(const char *)newEncoding
{
    if( encoding != newEncoding ){
        free(encoding);
        encoding = malloc(strlen(newEncoding)+1);
        strcpy(encoding, newEncoding);
        
        numargs = encoding_numberOfArguments(encoding);
        
        if( argtypes ){
            for( NSUInteger i = 0; i < numargs; i++ ){
                free(argtypes[i]);
            }
        }
        free(argtypes);
        
        argtypes = malloc(sizeof(char *) * numargs);
        parse_encoding_into_types(encoding, numargs, argtypes);
        
        free(rettype);
        rettype = arg_createTypeString(encoding);
    }
}

- (const char *)argumentTypeAtIndex:(NSUInteger)idx
{
    if( idx >= numargs ){
        [NSException raise:NSInvalidArgumentException
                    format:@"Index %ld out of range for number of arguments %ld for %@", idx, numargs, self];
    }
    
    return argtypes[idx];
}

- (BOOL)argumentAtIndexIsObject:(NSUInteger)idx
{
    return arg_isObjectType([self argumentTypeAtIndex:idx]);
}

- (BOOL)argumentAtIndexIsPointer:(NSUInteger)idx
{
    return arg_isPointerType([self argumentTypeAtIndex:idx]);
}

- (NSUInteger)sizeOfArgumentAtIndex:(NSUInteger)idx
{
    NSUInteger size, ignored;
    NSGetSizeAndAlignment([self argumentTypeAtIndex:idx], &size, &ignored);
    
    return size;
}


- (NSUInteger)numberOfArguments
{
    return numargs;
}

- (NSUInteger)frameLength
{
    return (NSUInteger)encoding_stackSize(encoding);
}

- (const char *)returnType
{
    return rettype;
}

- (BOOL)returnTypeIsObject
{
    return arg_isObjectType([self returnType]);
}

- (NSUInteger)returnSize
{
    NSUInteger retsize, ignored;
    NSGetSizeAndAlignment(rettype, &retsize, &ignored);
    return retsize;
}

@end
