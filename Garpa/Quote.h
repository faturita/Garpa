//
//  Quote.h
//  Garpa
//
//  Created by Rodrigo Ramele on 8/28/15.
//  Copyright (c) 2015 Baufest. All rights reserved.
//

#ifndef Garpa_Quote_h
#define Garpa_Quote_h

#import <Foundation/Foundation.h>

@interface Quote: NSObject
{
    
}

@property (strong, nonatomic) NSString*  symbol;
@property (strong, nonatomic) NSString*  price;
@property (strong, nonatomic) NSString*  quantity;

-(void) print;
@end

#endif
