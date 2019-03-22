//
//  Quote.m
//  Garpa
//
//  Created by Rodrigo Ramele on 8/28/15.
//  Copyright (c) 2015 Baufest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Quote.h"

@implementation Quote

@synthesize symbol, price;


-(void)print
{
    NSLog(@"%@", symbol);
}


-(NSString*) description
{
    return [NSString stringWithFormat:@"%@/%@", symbol, price];
}

@end