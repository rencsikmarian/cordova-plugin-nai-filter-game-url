#import "NAIFilterGameUrlPlugin.h"

@interface NAIFilterGameUrlPlugin ()

@property (nonatomic, strong) NSArray *defaultBlockedDomains;
@property (nonatomic, strong) NSMutableArray *blockedDomains;
@property (nonatomic, strong) NSString *redirectAppUrl;
@property (nonatomic, strong) NSString *appUrl;

@end

@implementation NAIFilterGameUrlPlugin

- (void)pluginInitialize {
    [super pluginInitialize];
    
    NSLog(@"NAIFilterGameUrlPlugin loaded successfully!");
    
    // Initialize default blocked domains
    self.defaultBlockedDomains = @[
        @"admiralbet.es",
        @"admiralbet.de",
        @"stargames.de",
        @"starvegas.ch",
        @"admiral.ch",
        @"admiralcasino.co.uk",
        @"loteriesport.lu",
        @"admiral.ro",
        @"fenikss.lv",
        @"feniksscasino.lv"
    ];
    
    // Get the scheme and hostname
    NSString *scheme = @"ionic";
    NSString *hostname = @"localhost";
    
    self.appUrl = [NSString stringWithFormat:@"%@://%@", scheme, hostname];
    self.redirectAppUrl = self.appUrl;
    self.blockedDomains = [NSMutableArray arrayWithArray:self.defaultBlockedDomains];
    
    NSLog(@"🔹 App URL set to: %@", self.appUrl);
}

- (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(NSInteger)navigationType {
    NSLog(@"✅ shouldOverrideLoad called with URL: %@", request.URL.absoluteString);
    
    if (!request.URL) {
        return NO; // let WebView handle it
    }
    
    NSString *urlString = request.URL.absoluteString;
    NSString *host = request.URL.host;
    
    if (!host) {
        return NO; // let WebView handle it
    }
    
    BOOL isBlocked = NO;
    
    for (NSString *blockedDomain in self.blockedDomains) {
        if ([host containsString:blockedDomain]) {
            NSLog(@"NAIFilterGameUrlPlugin: Matched host: %@", host);
            NSString *scheme = request.URL.scheme ?: @"";
            
            if ([scheme isEqualToString:@"https"]) {
                self.redirectAppUrl = [[[urlString
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://staging.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://beta.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://www.%@", blockedDomain]
                    withString:self.appUrl];
            } else if ([scheme isEqualToString:@"http"]) {
                self.redirectAppUrl = [[[urlString
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://staging.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://beta.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://www.%@", blockedDomain]
                    withString:self.appUrl];
            }
            isBlocked = YES;
            break;
        }
        
        NSString *openUrlParam = @"OpenURL?url=";
        if ([urlString containsString:openUrlParam]) {
            NSArray *components = [urlString componentsSeparatedByString:openUrlParam];
            if (components.count > 1 && [[components lastObject] containsString:blockedDomain]) {
                NSLog(@"NAIFilterGameUrlPlugin: Matched blocked domain in OpenURL parameter: %@", [components lastObject]);
                self.redirectAppUrl = self.appUrl;
                isBlocked = YES;
                break;
            }
        }
    }
    
    if (isBlocked) {
        NSLog(@"NAIFilterGameUrlPlugin: Redirect from: %@ to: %@", urlString, self.redirectAppUrl);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *redirectURL = [NSURL URLWithString:self.redirectAppUrl];
            if (redirectURL) {
                [(WKWebView*)self.webViewEngine.webView loadRequest:[NSURLRequest requestWithURL:redirectURL]];
            }
        });
        return YES; // we handled the request
    }
    
    return NO; // let WebView handle it
}

@end 