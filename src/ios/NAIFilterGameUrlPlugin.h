#import <Cordova/CDVPlugin.h>
#import <WebKit/WebKit.h>

@interface NAIFilterGameUrlPlugin : CDVPlugin

- (void)pluginInitialize;
- (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(NSInteger)navigationType;

@end 