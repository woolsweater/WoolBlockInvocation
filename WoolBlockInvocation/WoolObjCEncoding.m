//
//  WoolObjCEncoding.m
//
// Adapted from Apple Open Source code by Joshua Caswell in June 2012. See
// notice below for license information.
// Portions Copyright (c) 2012 Joshua Caswell

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

#import "WoolObjCEncoding.h"

/* Processes a compound type encoding, returning the number of characters it 
 * occupies in the string.
 */
static int subtypeUntil(const char * type, char endChar)
{
    int level = 0;
    const char * head = type;
    
    //
    while (*type)
    {
        if (!*type || (!level && (*type == endChar)))
            return (int)(type - head);
        
        switch (*type)
        {
            case ']': case '}': case ')': level--; break;
            case '[': case '{': case '(': level += 1; break;
        }
        
        type++;
        
    }
    
    //_objc_fatal("Type encoding: subtypeUntil: end of type encountered prematurely\n");
    return 0;
}


/* Moves past the non-numeric portion of an argument's encoding, returning a
 * pointer to the following char, which is the first digit char.
 */
static char * skipType(const char * type)
{
    char * p = (char *)type;
    while (1)
    {
        switch (*p++)
        {
            case 'O':    /* bycopy */
            case 'n':    /* in */
            case 'o':    /* out */
            case 'N':    /* inout */
            case 'r':    /* const */
            case 'V':    /* oneway */
            case '^':    /* pointers */
                break;
                
            case '@':   /* objects */
                if (p[0] == '?') p++;  /* Blocks */
                return p;
                
                /* arrays */
            case '[':
                while ((*p >= '0') && (*p <= '9')){
                    p++;
                }
                return p + subtypeUntil(p, ']') + 1;
                
                /* structures */
            case '{':
                return p + subtypeUntil(p, '}') + 1;
                
                /* unions */
            case '(':
                return p + subtypeUntil(p, ')') + 1;
                
                /* basic types */
            default:
                return p;
        }
    }
}

/* Takes a pointer to the beginning of an encoded argument and gets the offset 
 * portion of the encoding, returning a pointer to the following character. 
 * Returns the offset itself, as an int, indirectly.
 */
char * arg_getOffset(const char * argdesc, int * offset)
{
    BOOL offset_is_negative = NO;
    
    // Move past the non-offset portion
    char * desc_p = skipType(argdesc);
    
    // Skip GNU runtime's register parameter hint
    if( *desc_p == '+' ) desc_p++;
    
    // Note negative sign in offset
    if( *desc_p == '-' )
    {
        offset_is_negative = YES;
        desc_p++;
    }
    
    // Pick up offset value and compensate for it being negative
    *offset = 0;
    while( (*desc_p >= '0') && (*desc_p <= '9') ){
        *offset = *offset * 10 + (*desc_p++ - '0');
    }
    if( offset_is_negative ){
        *offset = -(*offset);
    }
    return desc_p;
}

/* Takes a pointer to the first char of an argument encoding and returns
 * a pointer to the first char of the following argument's encoding.
 */
char * arg_skipArg(const char * argdesc)
{   
    int ignored;
    return arg_getOffset(argdesc, &ignored);
}

/* Skips the return type and stack length to return a pointer to the first
 * char of the first argument's (self) encoding.
 */
char * encoding_selfArgument(const char * typedesc)
{
    return arg_skipArg(typedesc);
}

/* Takes a pointer to an argument encoding and a buffer (dst), along with the
 * buffer's length. Copies the type portion of the argument encoding string 
 * into dst, returning a pointer to the new last character in dst.
 */
char * arg_getType(const char *argdesc, char *buf, size_t buf_size)
{
    size_t len;
    const char *end;
    
    if (!buf) return (char *)argdesc;
    if (!argdesc) {
        strlcpy(buf, "", buf_size);
        return NULL;
    }
    
    end = skipType(argdesc);
    len = end - argdesc;
    strlcpy(buf, argdesc, MIN(len, buf_size));
    return buf + len;
    // Zero out the remainder of dst
    //if( len < dst_len ) memset(dst+len, 0, dst_len - len);
}

/* Takes a pointer to an argument encoding and returns a string which is owned
 * by the caller containing just the type portion of the encoding. */
char * arg_copyTypeString(const char *argdesc)
{
    size_t len;
    const char * end;
    if( !argdesc ) return NULL;
    
    end = skipType(argdesc);
    len = end - argdesc;
    
    char * ret = malloc(len+1);
    strlcpy(ret, argdesc, len);
    *(ret+len) = '\0';
    
    return ret;
}

BOOL arg_isObjectType(const char *argdesc)
{
    return argdesc[0] == '@';
}

BOOL arg_isPointerType(const char *argdesc)
{
    return argdesc[0] == '@' ||
           argdesc[0] == '^' ||
           argdesc[0] == '[';
}

/* Takes an encoding string and a buffer and copies the encoded return
 * type into the buffer, returning a pointer to the new final char in buf.
 */
char * encoding_getReturnType(const char *typedesc, char *buf, size_t buf_size)
{
    return arg_getType(typedesc, buf, buf_size);
}

/* Takes an encoding string and returns the stack size as an int. */
int encoding_stackSize(const char * typedesc)
{
    int stack_size;
    arg_getOffset(typedesc, &stack_size);
    return stack_size;
}

/* Takes an encoding string and an argument index.
 * Returns a pointer to the first char of the specified argument in the string
 * and indirectly returns that argument's encoded offset as an int.
 */
char * encoding_findArgument(const char *typedesc, int arg_idx, int *offset)
{
    
    // Move past return type and stack size
    char * desc_p = encoding_selfArgument(typedesc);
    
    // Move to the correct argument
    unsigned nargs = 0;
    int self_offset = 0;
    while( *desc_p && nargs != arg_idx )
    {
        
        if( nargs == 0 )
        {
            desc_p = arg_getOffset(desc_p, &self_offset);
            
        }
        else
        {
            desc_p = arg_skipArg(desc_p);
        }
        
        nargs += 1;
    }
    
    if( *desc_p )
    {
        int arg_offset;
        if( arg_idx == 0 )
        {
            *offset = self_offset;
        }
        else
        {
            char * ignored __attribute__((unused));
            ignored = arg_getOffset(desc_p, &arg_offset);
            
            *offset = arg_offset - self_offset;
        }
        
    }
    else
    {
        *offset	= 0;
    }
    
    return desc_p;
}

/* Takes an encoding string. Returns the number of arguments encoded. */
unsigned int encoding_numberOfArguments(const char *typedesc)
{
    unsigned int nargs = 0;
    // Move past return type and stack size
    char * desc_p = encoding_selfArgument(typedesc);
    while( *desc_p )
    {
        desc_p = arg_skipArg(desc_p);
        // Made it past an argument
        nargs += 1;
    }
    
    return nargs;
}