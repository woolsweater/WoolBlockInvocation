//
//  WSSBlockSignature.m
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import "WSSBlockSignature.h"

#import "WoolBlockHelper.h"
#import "WoolObjCEncoding.h"

@interface WSSBlockSignature ()

- (void)setAttributesFromEncoding:(const char *)newEncoding;
- (void)releaseMallocdMemory;

@end

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
    
    [newinstance setAttributesFromEncoding:types];
    
    return newinstance;
}

+ (instancetype)signatureForBlock:(id)block
{
    return [self signatureWithObjCTypes:BlockSig(block)];
}

- (void)dealloc
{
    [self releaseMallocdMemory];
}

- (void)releaseMallocdMemory
{
    free(encoding);
    if( argtypes ){
        for( NSUInteger i = 0; i < numargs; i++ ){
            free(argtypes[i]);
        }
    }
    free(argtypes);
    free(rettype);
}

static int strcmpNULLSafe(const char * s1, const char * s2)
{
    s1 = s1 != NULL ? s1 : "";
    s2 = s2 != NULL ? s2 : "";
    
    return strcmp(s1, s2);
}

- (BOOL)isEqual:(id)other
{
    if( self == other ) return YES;
    
    if( ![other isKindOfClass:[self class]] ) return NO;
    
    WSSBlockSignature * otherSig = other;
    
    if( numargs != otherSig->numargs ) return NO;
    
    if( 0 != strcmpNULLSafe(rettype, otherSig->rettype) ) return NO;
    
    for( NSUInteger i = 0; i < numargs; i++ ){
        if( 0 != strcmpNULLSafe(argtypes[i], otherSig->argtypes[i]) ) return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return [[NSData dataWithBytesNoCopy:encoding
                                 length:strlen(encoding)]
                hash];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>: "
                               "Encoding: %s, number of arguments: %ld, "
                               "return type: %s",
                               [self class], self, encoding, numargs, rettype];
}

- (void)setAttributesFromEncoding:(const char *)newEncoding
{
    if( encoding != newEncoding &&
        0 != strcmpNULLSafe(encoding, newEncoding) )
    {
        [self releaseMallocdMemory];
        
        encoding = malloc(strlen(newEncoding)+1);
        strcpy(encoding, newEncoding);
        
        numargs = encoding_numberOfArguments(encoding);
        
        argtypes = malloc(sizeof(char *) * numargs);
        for( NSUInteger idx = 0; idx < numargs; idx++ ){
            int ignored;
            char * arg = encoding_findArgument(encoding, (int)idx, &ignored);
            argtypes[idx] = arg_copyTypeString(arg);
        }
        
        rettype = arg_copyTypeString(encoding);
    }
}

- (const char *)argumentTypeAtIndex:(NSUInteger)idx
{
    if( idx >= numargs ){
        [NSException raise:NSInvalidArgumentException
                    format:@"Index %ld out of range for number of arguments"
                            "%ld for %@", idx, numargs, self];
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

- (const char *)returnType
{
    return rettype;
}

- (BOOL)returnTypeIsObject
{
    return arg_isObjectType([self returnType]);
}

- (NSUInteger)returnLength
{
    NSUInteger retsize, ignored;
    NSGetSizeAndAlignment(rettype, &retsize, &ignored);
    return retsize;
}

@end
