//
//  LoginViewController.m
//  Garpa
//
//  Created by Rodrigo Ramele on 21/03/2019.
//  Copyright © 2019 Baufest. All rights reserved.
//

#import "LoginViewController.h"
#import "ViewController.h"

#import "NSWSAsyncConsumer.h"

#import "Quote.h"

#import <SSKeychain.h>

@interface LoginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) NSString* accessToken;
@end

@implementation LoginViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _username.delegate = self;
    _password.delegate = self;

    NSError *error = nil;
    
    NSString *username = [SSKeychain passwordForService:@"Garpa" account:@"username" error:&error];
    NSString *password = [SSKeychain passwordForService:@"Garpa" account:@"rramele" error:&error];
    
    if ([error code] == kSSKeychainErrorDomain) {
        NSLog(@"Password not found");
    } else {
        _password.text = password;
        _username.text = username;
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"MainSegue"])
    {
        ViewController *viewController = [segue destinationViewController];
        viewController.accessToken = _accessToken;
    }
}


-(void)doEffectiveLogin:(NSString*)pusername withPassword:(NSString*)ppassword
{
    __block LoginViewController *myself = self;
    
    NSURL *url = [[NSURL alloc] initWithString:@"https://api.invertironline.com/token"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"api.invertironline.com" forHTTPHeaderField:@"Host"];
    
    //NSString *stringData = @"{ username: 'fdsfdsfdsfds', password: 'kjkdfsd' }";
    
    NSString *credentials = [[NSString alloc]initWithFormat:@"username=%@&password=%@&grant_type=password", pusername, ppassword ];
    
    NSData *data = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    
    __block NSDictionary *json;
    
    [request setHTTPBody:data];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               
                               NSLog(@"Response: %@",httpResponse);
                               
                               NSLog(@"Status Code: %u", [httpResponse statusCode]);
                               
                               if ([data length] >0 && connectionError == nil && [httpResponse statusCode] == 200)
                               {
                                   
                                   NSLog(@"Login JSON: %@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                                   
                                   json = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:nil];
                                   NSLog(@"Async JSON: %@", json);
                                   
                                   //NSString *cookie = [self getCookie:httpResponse];
                                   
                                   //[myself getPortfolio:cookie];
                                   [myself processLogin:data];
                                   
                               }
                               else if ([data length] == 0 && connectionError == nil)
                               {
                                   NSLog(@"Nothing was downloaded.");
                               }
                               else if (connectionError != nil){
                                   NSLog(@"Error = %@", connectionError);
                               }
                               
                           }];
    
}

-(void)processLogin:(NSData*)jsonData
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:0
                                                           error:nil];
    
    // Get bearer token and refresh token
    
    // Once expired, use the refresh token to get a new set
    NSString *accessToken = [json valueForKey:@"access_token"];
    
    NSLog(@"Access Token %@", accessToken);
    
    _accessToken = accessToken;
    
    [SSKeychain setPassword:accessToken forService:@"Garpa" account:@"accessToken"];
    
}


- (IBAction)doLogin:(id)sender {
    //[self doSomeNastyThings:self.username.text withPassword:self.password.text];
    
    [self doEffectiveLogin:self.username.text withPassword:self.password.text];
    
    [SSKeychain setPassword:_username.text forService:@"Garpa" account:@"username"];
    [SSKeychain setPassword:_password.text forService:@"Garpa" account:_username.text];
    

    [self performSegueWithIdentifier:@"MainSegue" sender:sender];
    
}

@end
