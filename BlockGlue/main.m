//
//  main.m
//  BlockGlue
//
//  Created by Joshua Caswell on 7/14/13.
//  Copyright (c) 2013 Josh Caswell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BlockGlue.h"
#import "BlockSignature.h"
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

        BlockGlue * glue = [BlockGlue blockGlueWithSignature:[BlockSignature signatureForBlock:b1]];
        [glue addBlock:b1];
        [glue addBlock:b2];
        [glue addBlock:b3];
        
        StringBlock glued = (StringBlock)[glue invocationBlock];
        
        glued(arg);
        
        [glue setArgument:&arg atIndex:1];
        [glue invoke];
        
    }
    return 0;
}

