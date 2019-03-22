//
//  NSWSAsyncConsumer.h
//  SancorCotizadorAutomotor
//
//  Created by Rodrigo Ramele on 08/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void (^ServiceResponseBlock) (NSData*);
typedef void (^ServiceErrorBlock) (NSString*);
                                        


@protocol ServiceCompletionCallback <NSObject>

@required

-(void) serviceResponse:(NSData *)responseMsg;
-(void) serviceError:(NSString*) errorMsg;


@end


@interface NSWSAsyncConsumer : NSObject
{
@public
    NSURLConnection     *connection;
    NSMutableData       *connectionData;
    
    ServiceResponseBlock serviceResponse;
    
    ServiceErrorBlock serviceError;
   id <ServiceCompletionCallback>       callback;
}

// Properties to handle asynchronous WebService execution.
@property (nonatomic, retain) NSURLConnection                           *connection;
@property (nonatomic, retain) NSMutableData                             *connectionData;

- (id)initWithBlock:(ServiceResponseBlock) serviceResponseBlock andErrorBlock:(ServiceErrorBlock) serviceErrorBlock;

- (id)initWithCallback:(id <ServiceCompletionCallback>) callback;

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

- (void) connectionDidFinishLoading :(NSURLConnection *)connection;

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;


@end


