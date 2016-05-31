//
//  AIBHTMLWebView.m
//  AIBHTMLWebView
//
//  Created by Thomas Parslow on 05/04/2015.
//  Copyright (c) 2015 Thomas Parslow. MIT License.
//

#import "AIBHTMLWebView.h"

#import <UIKit/UIKit.h>
#import "RCTEventDispatcher.h"
#import "UIView+React.h"
#import "RCTView.h"

@interface AIBHTMLWebView () <UIWebViewDelegate>

@end

@implementation AIBHTMLWebView
{
    RCTEventDispatcher *_eventDispatcher;
    UIWebView *_webView;
    BOOL autoHeight;
}

- (void)setHTML:(NSString *)HTML
{
    // TODO: Do we need to ensure that duplicate sets are ignored?
    [_webView loadHTMLString:HTML baseURL: [NSURL URLWithString: @""]];
    [self reportHeight];
}

- (void)setAutoHeight:(BOOL) enable
{
    _webView.scrollView.scrollEnabled = !enable;
    autoHeight = enable;
}


- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super initWithFrame:CGRectZero])) {
        super.backgroundColor = [UIColor clearColor];
        _eventDispatcher = eventDispatcher;
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.delegate = self;
        [self addSubview:_webView];
        autoHeight = false;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _webView.frame = self.bounds;
    [self reportHeight];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    CGFloat alpha = CGColorGetAlpha(backgroundColor.CGColor);
    self.opaque = _webView.opaque = (alpha == 1.0);
    _webView.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor
{
    return _webView.backgroundColor;
}

- (void)reportHeight
{
    if (!autoHeight) {
        return;
    }
    CGRect frame = _webView.frame;
    frame.size.height = 1;
    _webView.frame = frame;
    frame.size.height = [[_webView stringByEvaluatingJavaScriptFromString: @"document.documentElement.scrollHeight"] floatValue];
    NSNumber *height = [NSNumber numberWithFloat: frame.size.height];
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary: @{
                                                                                    @"target": self.reactTag,
                                                                                    @"contentHeight": height
                                                                                    }];
    [_eventDispatcher sendInputEventWithName:@"changeHeight" body:event];
    _webView.frame = frame;
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL scheme] isEqual:@"file"] && navigationType==UIWebViewNavigationTypeOther) {
        // When we load from HTML string it still shows up as a request, so let's let that through
        return YES;
    } else {
        NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary: @{
                                                                                        @"target": self.reactTag,
                                                                                        @"url": [request.URL absoluteString]
                                                                                        }];
        [_eventDispatcher sendInputEventWithName:@"link" body:event];
        return NO; // Tells the webView not to load the URL
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self reportHeight];
}

@end
