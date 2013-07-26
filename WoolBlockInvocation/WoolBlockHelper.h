//  WoolBlockHelper.h

#ifndef WoolBlockHelper_h
#define WoolBlockHelper_h

/* 
 * The information in this header largely duplicates the private Blocks header
 * defining the ABI for Blocks. While the ABI is an implementation detail, it
 * is a _compile-time_ detail. An executable will not break in the field.
 */

#if !__has_feature(objc_arc)
#define __bridge
#endif // Exclude if compiled with ARC

/* 
 * Below code thanks very much to Mike Ash's MABlockForwarding and
 * MABlockClosure projects
 * https://github.com/mikeash/MABlockForwarding
 * http://www.mikeash.com/pyblog/friday-qa-2011-10-28-generic-block-proxying.html
 * https://github.com/mikeash/MABlockClosure
 *
 * Copyright (c) 2010, Michael Ash
 * All rights reserved.
 * Distributed under a BSD license.
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this 
 * list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution.
 *
 * Neither the name of Michael Ash nor the names of its contributors may be 
 * used to endorse or promote products derived from this software without 
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */

struct BlockDescriptor
{
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block
{
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BlockDescriptor *descriptor;
};

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30), 
};

// Return the block's invoke function pointer.
static void * BlockIMP(id block)
{
    return ((__bridge struct Block *)block)->invoke;
}


// Return a C string representing the block's signature; NSMethodSignature
// can use this.
static const char * BlockSig(id blockObj){
    struct Block *block = (__bridge void *)blockObj;
    struct BlockDescriptor *descriptor = block->descriptor;
    
    assert(block->flags & BLOCK_HAS_SIGNATURE);
    
    int index = 0;
    if(block->flags & BLOCK_HAS_COPY_DISPOSE)
        index += 2;
    
    return descriptor->rest[index];
}

/* End code from Mike Ash */

#if !__has_feature(objc_arc)
#undef __bridge
#endif // Exclude if compiled with ARC

#endif /* WoolBlockHelper_h */
