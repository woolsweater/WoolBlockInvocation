//
// WoolObjCEncoding.h
//
// Adapted from Apple Open Source code by Joshua Caswell in June 2011. See
// notice below for license information.
// Portions Copyright (c) 2012 Joshua Caswell.

#ifndef WoolObjCEncoding_h
#define WoolObjCEncoding_h

/* 
 * Portions Copyright (c) 1999-2007 Apple Computer, Inc. All Rights
 * Reserved.
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 */

/**
 * Takes a pointer to the beginning of an encoded argument and gets the offset
 * portion of the encoding, returning a pointer to the following character. 
 * Returns the offset itself, as an int, indirectly.
 */
char * arg_getOffset(const char * argdesc, int * offset);

/**
 * Takes a pointer to the first char of an argument encoding and returns
 * a pointer to the first char of the following argument's encoding.
 */
char * arg_skipArg(const char * argdesc);

/**
 * Takes pointers to an argument encoding and a buffer, along with the
 * buffer's length. Copies the type portion of the argument encoding string 
 * into the buffer, returning a pointer to the new final character in buf.
 */
char * arg_getType(const char *argdesc, char *buf, size_t buf_size);


/**
 * Takes a pointer to an argument encoding. Allocates and returns a string
 * containing just the type portion of the argument, properly NUL-terminated.
 */
char * arg_copyTypeString(const char *argdesc);

BOOL arg_isObjectType(const char *argdesc);
BOOL arg_isPointerType(const char *argdesc);

/**
 * Skips the return type and stack length to return a pointer to the first
 * char of the first argument's (self) encoding.
 */
char * encoding_selfArgument(const char * typedesc);

/**
 * Takes an encoding string and a buffer, along with the buffer's length, and
 * copies the encoded return type into the buffer, returning a pointer to the 
 * new final char in buf.
 */
char * encoding_getReturnType(const char *typedesc, char *buf, size_t buf_size);

/**  Takes an encoding string and returns the stack size as an int. */
int encoding_stackSize(const char * typedesc);

/**
 * Takes an encoding string and an argument index.
 * Returns a pointer to the first char of the specified argument in the string
 * and indirectly returns that argument's encoded offset as an int.
 */
char * encoding_findArgument(const char *typedesc, int arg_idx, int *offset);

/** Takes an encoding string. Returns the number of arguments encoded. */
unsigned int encoding_numberOfArguments(const char *typedesc);


/**
 * Takes an encoding string and inserts the encoding for a SEL after the first
 * parameter (self), adjusting the stack length and offsets. 
 */
char * encoding_createWithInsertedSEL(const char * original_encoding);

#endif /* WoolObjCEncoding_h */
