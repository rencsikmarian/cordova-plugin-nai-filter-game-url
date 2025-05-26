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
    NSString *hostname = @"localhost:8100";
    
    self.appUrl = [NSString stringWithFormat:@"%@://%@", scheme, hostname];
    self.redirectAppUrl = self.appUrl;
    self.blockedDomains = [NSMutableArray arrayWithArray:self.defaultBlockedDomains];
    
    NSLog(@"🔹 App URL set to: %@", self.appUrl);
}

- (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(NSInteger)navigationType {
    NSLog(@"✅ shouldOverrideLoad called with URL: %@", request.URL.absoluteString);
    
      if (!request.URL) {
          NSLog(@"❌ No URL present in request");
          return YES; // let WebView handle it
      }
      
      NSString *urlString = [request.URL.absoluteString lowercaseString];
      NSString *scheme = request.URL.scheme;
      NSString *host = request.URL.host;
      
      // Allow ionic:// scheme to pass through
      if ([scheme isEqualToString:@"ionic"]) {
          NSLog(@"✅ Allowing ionic scheme to pass through");
          return YES; // let WebView handle it
      }
      
      if (!host) {
          NSLog(@"❌ No host present in URL");
          return YES; // let WebView handle it
      }
    
    BOOL isBlocked = NO;
    
    for (NSString *blockedDomain in self.blockedDomains) {
        if ([host containsString:blockedDomain]) {
            NSLog(@"NAIFilterGameUrlPlugin: Matched host: %@", host);
            NSString *scheme = request.URL.scheme ?: @"";
            NSArray *allowedPrefixes = @[@"", @"www.", @"staging.", @"beta."];
            BOOL shouldRedirect = NO;
            
            for (NSString *prefix in allowedPrefixes) {
                if ([host isEqualToString:[NSString stringWithFormat:@"%@%@", prefix, blockedDomain]]) {
                    shouldRedirect = YES;
                    break;
                }
            }
            
            if (!shouldRedirect) {
                break;
            }
            
            if ([scheme isEqualToString:@"https"]) {
                self.redirectAppUrl = [[[[urlString
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://staging.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://beta.%@", blockedDomain]
                    withString:self.appUrl]
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"https://www.%@", blockedDomain]
                    withString:self.appUrl];
            } else if ([scheme isEqualToString:@"http"]) {
                self.redirectAppUrl = [[[[urlString
                    stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://%@", blockedDomain]
                    withString:self.appUrl]
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
        
        NSString *openUrlParam = @"openurl?url=";
        if ([urlString containsString:openUrlParam]) {
            NSArray *components = [urlString componentsSeparatedByString:openUrlParam];
            if (components.count > 1 && [[components lastObject] containsString:blockedDomain]) {
                NSLog(@"NAIFilterGameUrlPlugin: Matched blocked domain in OpenURL parameter: %@", [components lastObject]);
                self.redirectAppUrl = self.appUrl;
                isBlocked = YES;
                break;
            }
        }
        if ([host containsString:@"lobbyiframelaunch"]) {
            NSLog(@"NAIFilterGameUrlPlugin: Matched blocked domain 'lobbyiframelaunch'");
            self.redirectAppUrl = self.appUrl;
            isBlocked = YES;
            break;
        }
        if ([urlString hasSuffix:@"/lobbyiframelaunch"]) {
            NSLog(@"NAIFilterGameUrlPlugin: Matched URL ending with '/lobbyiframelaunch'");
            self.redirectAppUrl = self.appUrl;
            isBlocked = YES;
            break;
        }
    }
    
    if (isBlocked) {
        NSLog(@"NAIFilterGameUrlPlugin: Redirect from: %@ to: %@", urlString, self.redirectAppUrl);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *redirectURL = [NSURL URLWithString:self.redirectAppUrl];
            if (redirectURL) {
              [(WKWebView*)self.webViewEngine loadRequest:[NSURLRequest requestWithURL:redirectURL]];
            }
        });
        return NO; // we handled the request
    }
    
    return YES; // let WebView handle it
}

@end 
