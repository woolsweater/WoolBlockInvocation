//
//  main.m
//  WoolBlockInvocaiton
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WSSBlockInvocation.h"
#import "WSSBlockSignature.h"
#import "WoolBlockHelper.h"

typedef void (^StringBlock)(NSString *);

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSString * arg = @"It's the first time an artist of such stature has taken the A272.";
        
        StringBlock b1 = ^(NSString * s){
            NSLog(@"%@", [s lowercaseString]);
        };
        
        StringBlock b2 = ^(NSString * s){
            NSLog(@"%@", [s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
        };
        
        StringBlock b3 = ^(NSString * s){
            NSLog(@"%@", [s uppercaseString]);
        };

        WSSBlockInvocation * invoc = [WSSBlockInvocation invocationWithSignature:[WSSBlockSignature signatureForBlock:b1]];
        [invoc addBlock:b1];
        [invoc addBlock:b2];
        [invoc addBlock:b3];
        
        StringBlock capsule = (StringBlock)[invoc invocationBlock];
        
        NSLog(@"Invocation block: ");
        capsule(arg);
        
        NSLog(@"\n\n----------------------\nUsing -invoke:");
        [invoc setArgument:&arg atIndex:1];
        [invoc invoke];
        
    }
    return 0;
}

