//
//  main.m
//  WoolBlockInvocation
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//  Distributed under an MIT license. See LICENSE.txt for details.

#import <Foundation/Foundation.h>

#import "WSSBlockInvocation.h"
#import "WSSBlockSignature.h"
#import "WoolBlockHelper.h"

typedef void (^StringBlock)(NSString *, NSString *, int);

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSString * arg = @"It's the first time an artist of such stature has taken the A272.";
        NSString * arg2 = @"the";
        int intarg = 3;
        
        StringBlock b1 = ^(NSString * s, NSString * r, int i){
            s = [s stringByReplacingOccurrencesOfString:r
                                             withString:[NSString stringWithFormat:@"%d", i]];
            NSLog(@"%@", [s lowercaseString]);
        };
        
        StringBlock b2 = ^(NSString * s, NSString * r, int i){
            NSLog(@"%@", [[s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] objectAtIndex:i]);
        };
        
        StringBlock b3 = ^(NSString * s, NSString * r, int i){
            for( int j = 0; j < i; j++ ){
                s = [s stringByAppendingString:r];
            }
            NSLog(@"%@", [s uppercaseString]);
        };

        WSSBlockInvocation * invoc = [WSSBlockInvocation invocationWithSignature:[WSSBlockSignature signatureForBlock:b1]];
        [invoc addBlock:b1];
        [invoc addBlock:b2];
        [invoc addBlock:b3];
        
        StringBlock capsule = (StringBlock)[invoc invocationBlock];
        
        NSLog(@"Invocation block: ");
        capsule(arg, arg2, intarg);
        
        NSLog(@"\n\n----------------------\nUsing -invoke:");
        [invoc setArgument:&arg atIndex:1];
        [invoc setArgument:&arg2 atIndex:2];
        [invoc setArgument:&intarg atIndex:3];
        [invoc invoke];
        
    }
    return 0;
}

