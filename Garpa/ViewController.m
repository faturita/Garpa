//
//  ViewController.m
//  Garpa
//
//  Created by Rodrigo Ramele on 19/03/2019.
//  Copyright © 2019 Baufest. All rights reserved.
//

#import "ViewController.h"
#import "StockCellTableViewCell.h"

#import "NSWSAsyncConsumer.h"

#import "Quote.h"

#import <SSKeychain.h>



@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextField *stock1;
@property (strong, nonatomic) IBOutlet UITableView *quotesTableView;
@property (strong, nonatomic) NSString* quantityHtml;
@property (strong, nonatomic) IBOutlet UIButton *totalButton;

@end

@implementation ViewController

NSMutableArray *tableData;

- (IBAction)doTotal:(id)sender {
    
    float total = 0.0;
    
    for (Quote *q in tableData) {
        float price = [q.price floatValue];
        float quantity = [q.quantity floatValue];
        
        
        if ([q.symbol isEqualToString:@"RO15.BA"])
            price = price * 10.0;
        else if ([q.symbol isEqualToString:@"AA17.BA"])
            price = price / 100.0;
        
        total+=(quantity*price);
        
    }
    
    [_totalButton setTitle:[[NSString alloc] initWithFormat:@"%.2f",total ] forState:UIControlStateNormal];
    
}

// This is the typical code which is used to dismiss the keyboard.  You have to put this, sorry.
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)addSymbol:(id)sender {
    
     //[dataset setString:_stock1.text  forKey:@"ALUA"];**/
}


- (IBAction)doSync:(id)sender {
    NSError *error = nil;
    
    NSString *accessToken = [SSKeychain passwordForService:@"Garpa" account:@"accessToken" error:&error];
    
    if ([error code] == kSSKeychainErrorDomain) {
        NSLog(@"Access Token not found");
    } else {
        _accessToken = accessToken;
    }
    
    [self loadPortfolio];
}


-(void)loadPortfolio
{
    __block ViewController *myself = self;
    
    NSURL *url = [[NSURL alloc] initWithString:[[NSString alloc]initWithFormat:@"https://api.invertironline.com/api/v2/portafolio/argentina?api_key=%@",_accessToken]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"api.invertironline.com" forHTTPHeaderField:@"Host"];
    [request setValue:[[NSString alloc]initWithFormat:@"Bearer %@",_accessToken ] forHTTPHeaderField:@"Authorization"];
    
    __block NSDictionary *json;
    
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
                                   //[myself processLogin:data];
                                   [myself processPortfolio:data];
                                   
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


-(void)reloadThisTable
{
    NSMutableArray *elements = [[NSMutableArray alloc] initWithArray:tableData];
    
    int count = [elements count];
    
    [tableData removeAllObjects];
    
    NSLog(@"Number of elements %lu", (unsigned long)[tableData count]);
    
    for (int i=0; i<count; i++) {
        Quote *q = [elements objectAtIndex:i];
        
        if (self.quantityHtml!=nil && (q.quantity == nil || q.quantity.length ==0) )
        {
            NSRange range = [q.symbol rangeOfString:@".BA"];
            
            q.quantity = [self loadAvailableStock:[q.symbol substringToIndex:range.location]  withHtml:self.quantityHtml];
        }
        
        [tableData addObject:q];
    }
    
    NSLog(@"Reloading everything...");
    
}

-(void)processPortfolio:(NSData*)jsonData
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:0
                                                           error:nil];
    
    
    NSArray *activos = [json valueForKey:@"activos"];
    NSLog(@"Number of symbols:%lu",activos.count);
    
    tableData = [[NSMutableArray alloc]init];
    
    for(int i=0;i<activos.count;i++)
    {
        NSDictionary *titulo = [activos[i] valueForKey:@"titulo"];
        NSString *simbolo = [titulo valueForKey:@"simbolo"];
        
        Quote *q = [[Quote alloc] init];
        
        q.price = [activos[i] valueForKey:@"ultimoPrecio"];
        q.symbol = simbolo;
        q.quantity = [activos[i] valueForKey:@"cantidad"];
        
        [tableData addObject:q];
    }
    
    [_quotesTableView reloadData];
    
}


-(void)processData:(NSData*)jsonData
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:0
                                                           error:nil];
    
    NSDictionary *query = [json valueForKey:@"query"];
    
    int count = [[query valueForKey:@"count"] intValue];
    
    NSDictionary *results = [query valueForKey:@"results"];
    NSArray *quote = [results valueForKey:@"quote"];
    
    tableData = [[NSMutableArray alloc]init];
    
    NSLog(@"Number of elements %lu", (unsigned long)[tableData count]);
    
    for (int i=0; i<count; i++) {
        Quote *q = [[Quote alloc] init];
        
        q.price = [quote[i] valueForKey:@"LastTradePriceOnly"];
        q.symbol = [quote[i] valueForKey:@"symbol"];
        
        [tableData addObject:q];
    }
    
    [_quotesTableView reloadData];
    
    
}

-(void)processError:(NSString*)errorMsg
{
    NSLog(@"Error:%@", errorMsg);
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _stock1.delegate = self;
    
    NSString *quotes = @"(%22EDN.BA%22%2C%22ERAR.BA%22%2C%22PAMP.BA%22%2C%22RO15.BA%22%2C%22TS.BA%22%2C%22YPFD.BA%22%2C%22ALUA.BA%22%2C%22AA17.BA%22%2C%22APBR.BA%22)";
    
    NSString *queryString = @"https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quote%20where%20symbol%20in%20";
    
    queryString=[queryString stringByAppendingString:quotes];
    queryString=[queryString stringByAppendingString:@"&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="];
    
    NSLog(@"%@",queryString);
    
    NSURL *urfl = [[NSURL alloc] initWithString:@"https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quote%20where%20symbol%20in%20(%22ALUA.BA%22%2C%22AA17.BA%22%2C%22APBR.BA%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="];
    
    NSURL *url = [[NSURL alloc]initWithString:queryString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    
    
    __block NSDictionary *json;
    
    /**
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               json = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:nil];
                               NSLog(@"Async JSON: %@", json);
                               
                               [myself processData:data];
                           }];
    
    **/
    
    /**
     AWSCognitoDataset *dataset = [[AWSCognito defaultCognito] openOrCreateDataset:@"Quotes"];
     
     NSDictionary *dictionary = [dataset getAll];
     
     [_stock1 setText:[dictionary valueForKey:@"ALUA"]];
     **/
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(NSString*)getCookie:(NSURLResponse*)response
{
    NSString *cookieValue = nil;
    
    NSHTTPURLResponse *httpResponse=(NSHTTPURLResponse*)response;
    
    if (httpResponse != nil) {
        if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
            NSDictionary *dictionary = [httpResponse allHeaderFields];
            
            if (dictionary != nil)
            {
                NSLog(@"%@", [dictionary description]);
                
                NSLog(@"Cookie Value: %@", [dictionary valueForKey:@"Set-Cookie"]);
            }
            
            NSArray *authToken = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields]
                                                                        forURL:[NSURL URLWithString:@""]];
            
            for (NSHTTPCookie *cookie in authToken) {
                NSLog(@"Cookie: %@, :%@", [cookie name], [cookie value]);
                
                if ([[cookie name] isEqualToString:@"__sid"])
                {
                    //[[[NSUserDefaults standardUserDefaults] valueForKey:kSyncEngineInitialCompleteKey] boolValue];
                    
                    NSLog(@"Registering cookie into UserDefaults");
                    
                    NSLog(@"Cookie:%@", [cookie value]);
                    
                    cookieValue = [cookie value];
                    
                    /**
                     [[NSUserDefaults standardUserDefaults] setValue:[cookie value]
                     forKey:@"MYSAPSSO2"];**/
                }
            }
        }
    }
    return cookieValue;
    
}

-(NSString*)getStringFrom:(NSString*)html WithValue:(NSString*)value
{
    NSString *szHaystack= html;
    NSString *szNeedle= value;
    NSRange range = [szHaystack rangeOfString:szNeedle];
    
    if (range.location == NSNotFound)
        return @"";
    
    NSInteger idx = range.location + range.length;
    NSString *szResult = [szHaystack substringFromIndex:idx];
    return szResult;
}

-(NSString*)loadAvailableStock:(NSString*)symbol withHtml:(NSString*)html
{
    NSString *quantity = @"";
    
    NSString *stock1 = [self getStringFrom:html WithValue:symbol];
    
    if (stock1.length!=0)
    {
        NSString *stock2 = [self getStringFrom:stock1 WithValue:@"Disponibles: "];
        
        NSString *vals = [self getStringFrom:stock2 WithValue:@">"];
        
        NSRange range = [vals rangeOfString:@"<"];
        
        NSLog(@"Value:%@",[vals substringToIndex:range.location ]);
        
        quantity = [vals substringToIndex:range.location ];
    }
    
    return quantity;
}


-(void)doSomeNastyThings:(NSString*)pusername withPassword:(NSString*)ppassword
{
    __block ViewController *myself = self;
    
    NSURL *url = [[NSURL alloc] initWithString:@"https://www.invertironline.com/User/DoLogin"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request setValue:@"52" forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"www.invertironline.com" forHTTPHeaderField:@"Host"];
    [request setValue:@"https://www.invertironline.com" forHTTPHeaderField:@"Origin"];
    [request setValue:@"https://www.invertironline.com/User/Logout" forHTTPHeaderField:@"Referer"];
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    
    //NSString *stringData = @"{ username: 'fdsfdsfdsfds', password: 'kjkdfsd' }";
    
    NSString *credentials = [[NSString alloc]initWithFormat:@"username=%@&password=%@", pusername, ppassword ];
    
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
                                   
                                   NSLog(@"Login Html: %@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                                   
                                   NSString *cookie = [self getCookie:httpResponse];
                                   
                                   [myself getPortfolio:cookie];
                                   
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


-(void)getPortfolio:(NSString*)cookie
{
    __block ViewController *myself = self;
    
    NSURL *url = [[NSURL alloc] initWithString:@"https://www.invertironline.com/MiCuenta/MiPortafolio"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:[[NSString alloc]initWithFormat:@"__sid=%@;",cookie] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request setValue:@"www.invertironline.com" forHTTPHeaderField:@"Host"];
    [request setValue:@"https://www.invertironline.com" forHTTPHeaderField:@"Origin"];
    [request setValue:@"https://www.invertironline.com/User/DoLogin" forHTTPHeaderField:@"Referer"];
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               
                               NSLog(@"Response: %@",httpResponse);
                               
                               NSLog(@"Status Code: %u", [httpResponse statusCode]);
                               
                               if ([data length] >0 && connectionError == nil)
                               {
                                   
                                   NSLog(@"Portfolio html: %@", [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                                   
                                   myself.quantityHtml = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                   
                                   /**
                                    [self performSelectorOnMainThread:@selector(reloadTable) withObject:self waitUntilDone:YES];**/
                                   
                                   
                                   /**[self reloadThisTable];**/
                                   
                                   [_quotesTableView    performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                                   
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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [tableData count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"StockCell";
    
    StockCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[StockCellTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    Quote *q = [tableData objectAtIndex:indexPath.row];
    
    NSLog(@"%@", q);
    
    
/**
    if (self.quantityHtml!=nil && (q.quantity == nil || q.quantity.length ==0) )
    {
        NSRange range = [q.symbol rangeOfString:@".BA"];
        
        q.quantity = [self loadAvailableStock:[q.symbol substringToIndex:range.location]  withHtml:self.quantityHtml];
    }
 **/
    
    
    /**
    if (q.quantity == nil || q.quantity.length == 0)
    {
        cell.textLabel.text = q.symbol;
        cell.detailTextLabel.text = q.price;
    } else {
        cell.textLabel.text = [[NSString alloc]initWithFormat:@"%@ (%@@%@)", q.symbol, q.quantity, q.price ];
        
        float price = [q.price floatValue];
        float quantity = [q.quantity floatValue];
        
        
        if ([q.symbol isEqualToString:@"RO15.BA"])
            price = price * 10.0;
        else if ([q.symbol isEqualToString:@"AA17.BA"])
            price = price / 100.0;
        
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%.2f",price*quantity ];
        
    }**/
    
    cell.qty.text = [[NSString alloc]initWithFormat:@"%@", q.quantity];
    cell.title.text = [[NSString alloc]initWithFormat:@"%@", q.symbol ];
    
    float price = [q.price floatValue];
    float quantity = [q.quantity floatValue];
    
    
    if ([q.symbol isEqualToString:@"RO15.BA"])
        price = price * 10.0;
    else if ([q.symbol isEqualToString:@"AA17.BA"])
        price = price / 100.0;
    
    cell.price.text = [[NSString alloc] initWithFormat:@"%.2f",price*quantity ];
    
    NSLog(@"Value %@", cell.textLabel.text);
    
    return cell;
}


@end

