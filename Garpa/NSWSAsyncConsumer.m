//
//  NSWSAsyncConsumer.m
//  SancorCotizadorAutomotor
//
//  Created by Rodrigo Ramele on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSWSAsyncConsumer.h"

@implementation NSWSAsyncConsumer


@synthesize connection;
@synthesize connectionData;

- (id)initWithBlock:(ServiceResponseBlock) serviceResponseBlock andErrorBlock:(ServiceErrorBlock)serviceErrorBlock
{
    self = [super init];
    if (self) {
        // Custom initialization
        
        serviceResponse = serviceResponseBlock;
        
        serviceError = serviceErrorBlock;
        
        callback=nil;
        
    }
    return self;
}
- (id)initWithCallback:(id <ServiceCompletionCallback>) callbackService{
    self = [super init];
    if (self) {
        callback=callbackService;
        serviceResponse=nil;
        serviceError=nil;
    }
    return self;
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"An error happened"); 
    NSLog(@"%@", error);
    
    // @FIXME Complete with more information about the error.
    if(callback==nil){
        serviceError( error.description );
    }else{
        [callback serviceError:error.description];
        
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Data received."); 
    
    NSLog(@"Data temp %@",data);
   
    [self.connectionData appendData:data];
}

- (void) connectionDidFinishLoading :(NSURLConnection *)connection
{
    NSLog(@"Successfully downloaded the contents of the URL.");

    if(callback==nil){
            serviceResponse(connectionData);
    }else{
        [callback serviceResponse:connectionData];
    }
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.connectionData setLength:0];
    
    NSLog(@"Started to receive response information....");
}


@end
