/*	
    WebMainResourceClient.m
    Copyright (c) 2001, 2002, Apple Computer, Inc. All rights reserved.
*/

#import <WebKit/WebMainResourceClient.h>

#import <WebFoundation/WebCookieConstants.h>
#import <WebFoundation/WebError.h>

#import <WebFoundation/WebFileTypeMappings.h>
#import <WebFoundation/WebNSURLExtras.h>
#import <WebFoundation/NSURLConnection.h>
#import <WebFoundation/NSURLRequest.h>
#import <WebFoundation/NSURLRequestPrivate.h>
#import <WebFoundation/NSURLResponse.h>
#import <WebFoundation/NSURLResponsePrivate.h>


#import <WebKit/WebDataSourcePrivate.h>
#import <WebKit/WebDefaultPolicyDelegate.h>
#import <WebKit/WebDocument.h>
#import <WebKit/WebDownloadPrivate.h>
#import <WebKit/WebFrameView.h>
#import <WebKit/WebFramePrivate.h>
#import <WebKit/WebKitErrors.h>
#import <WebKit/WebKitLogging.h>
#import <WebKit/WebLocationChangeDelegate.h>
#import <WebKit/WebPolicyDelegatePrivate.h>
#import <WebKit/WebNSURLResponseExtras.h>
#import <WebKit/WebStandardPanelsPrivate.h>
#import <WebKit/WebViewPrivate.h>

// FIXME: More that is in common with WebSubresourceClient should move up into WebBaseResourceHandleDelegate.

@implementation WebMainResourceClient

- initWithDataSource:(WebDataSource *)ds
{
    self = [super init];
    
    if (self) {
        [self setDataSource:ds];
        proxy = [[WebResourceDelegateProxy alloc] init];
        [proxy setDelegate:self];
    }

    return self;
}

- (void)dealloc
{
    [proxy setDelegate:nil];
    [proxy release];
    
    [super dealloc];
}

- (void)receivedError:(WebError *)error
{
    // Calling _receivedError will likely result in a call to release, so we must retain.
    [self retain];
    [dataSource _receivedError:error complete:YES];
    [super resource:resource didFailLoadingWithError:error];
    [self release];
}

- (void)cancelContentPolicy
{
    [listener _invalidate];
    [listener release];
    listener = nil;
    [policyResponse release];
    policyResponse = nil;
}

-(void)cancelWithError:(WebError *)error
{
    [self cancelContentPolicy];
    [resource cancel];
    [self receivedError:error];
}

- (WebError *)interruptForPolicyChangeError
{
    return [WebError errorWithCode:WebKitErrorLocationChangeInterruptedByPolicyChange
                          inDomain:WebErrorDomainWebKit
                        failingURL:[[request URL] absoluteString]];
}

-(void)stopLoadingForPolicyChange
{
    [self cancelWithError:[self interruptForPolicyChangeError]];
}

-(void)continueAfterNavigationPolicy:(NSURLRequest *)_request formState:(WebFormState *)state
{
    [[dataSource _controller] setDefersCallbacks:NO];
    if (!_request) {
	[self stopLoadingForPolicyChange];
    }
}

-(NSURLRequest *)resource:(NSURLConnection *)h willSendRequest:(NSURLRequest *)newRequest
{
    // Note that there are no asserts here as there are for the other callbacks. This is due to the
    // fact that this "callback" is sent when starting every load, and the state of callback
    // deferrals plays less of a part in this function in preventing the bad behavior deferring 
    // callbacks is meant to prevent.
    ASSERT(newRequest != nil);

    NSURL *URL = [newRequest URL];

    LOG(Redirect, "URL = %@", URL);
    
    // Update cookie policy base URL as URL changes, except for subframes, which use the
    // URL of the main frame which doesn't change when we redirect.
    if ([dataSource webFrame] == [[dataSource _controller] mainFrame]) {
        NSMutableURLRequest *mutableRequest = [newRequest mutableCopy];
        [mutableRequest HTTPSetCookiePolicyBaseURL:URL];
        newRequest = [mutableRequest autorelease];
    }

    // note super will make a copy for us, so reassigning newRequest is important
    newRequest = [super resource:h willSendRequest:newRequest];

    // Don't set this on the first request.  It is set
    // when the main load was started.
    [dataSource _setRequest:newRequest];
    
    [[dataSource _controller] setDefersCallbacks:YES];
    [[dataSource webFrame] _checkNavigationPolicyForRequest:newRequest
                                                 dataSource:dataSource
                                                  formState:nil
                                                    andCall:self
                                               withSelector:@selector(continueAfterNavigationPolicy:formState:)];

    return newRequest;
}

-(void)continueAfterContentPolicy:(WebPolicyAction)contentPolicy response:(NSURLResponse *)r
{
    [[dataSource _controller] setDefersCallbacks:NO];
    NSURLRequest *req = [dataSource request];

    switch (contentPolicy) {
    case WebPolicyUse:
	if (![WebView canShowMIMEType:[r MIMEType]]) {
	    [[dataSource webFrame] _handleUnimplementablePolicyWithErrorCode:WebKitErrorCannotShowMIMEType forURL:[req URL]];
	    [self stopLoadingForPolicyChange];
	    return;
	}
        break;

    case WebPolicyDownload:
        [proxy setDelegate:nil];
        [WebDownload _downloadWithLoadingResource:resource
                                          request:request
                                         response:r
                                         delegate:[self downloadDelegate]
                                            proxy:proxy];
        [proxy release];
        proxy = nil;
        [self receivedError:[self interruptForPolicyChangeError]];
        return;

    case WebPolicyIgnore:
	[self stopLoadingForPolicyChange];
	return;
    
    default:
	ASSERT_NOT_REACHED();
    }

    [super resource:resource didReceiveResponse:r];

    if ([[req URL] _web_shouldLoadAsEmptyDocument]) {
	[self resourceDidFinishLoading:resource];
    }
}

-(void)continueAfterContentPolicy:(WebPolicyAction)policy
{
    NSURLResponse *r = [policyResponse retain];
    [self cancelContentPolicy];
    [self continueAfterContentPolicy:policy response:r];
    [r release];
}

-(void)checkContentPolicyForResponse:(NSURLResponse *)r
{
    listener = [[WebPolicyDecisionListener alloc]
		   _initWithTarget:self action:@selector(continueAfterContentPolicy:)];
    policyResponse = [r retain];

    WebView *c = [dataSource _controller];
    [c setDefersCallbacks:YES];
    [[c _policyDelegateForwarder] webView:c decideContentPolicyForMIMEType:[r MIMEType]
                                                                   andRequest:[dataSource request]
                                                                      inFrame:[dataSource webFrame]
                                                             decisionListener:listener];
}


-(void)resource:(NSURLConnection *)h didReceiveResponse:(NSURLResponse *)r
{
    ASSERT(![h defersCallbacks]);
    ASSERT(![self defersCallbacks]);
    ASSERT(![[dataSource _controller] defersCallbacks]);

    LOG(Loading, "main content type: %@", [r MIMEType]);

    [dataSource _setResponse:r];
    _contentLength = [r expectedContentLength];

    // Figure out the content policy.
    [self checkContentPolicyForResponse:r];
}

- (void)resource:(NSURLConnection *)h didReceiveData:(NSData *)data
{
    ASSERT(data);
    ASSERT([data length] != 0);
    ASSERT(![h defersCallbacks]);
    ASSERT(![self defersCallbacks]);
    ASSERT(![[dataSource _controller] defersCallbacks]);
 
    LOG(Loading, "URL = %@, data = %p, length %d", [dataSource _URL], data, [data length]);

    [dataSource _receivedData:data];
    [[dataSource _controller] _mainReceivedBytesSoFar:[[dataSource data] length]
                                       fromDataSource:dataSource
                                             complete:NO];

    [super resource:h didReceiveData:data];
    _bytesReceived += [data length];

    LOG(Loading, "%d of %d", _bytesReceived, _contentLength);
}

- (void)resourceDidFinishLoading:(NSURLConnection *)h
{
    ASSERT(![h defersCallbacks]);
    ASSERT(![self defersCallbacks]);
    ASSERT(![[dataSource _controller] defersCallbacks]);

    LOG(Loading, "URL = %@", [dataSource _URL]);
        
    // Calls in this method will most likely result in a call to release, so we must retain.
    [self retain];

    [dataSource _finishedLoading];
    [[dataSource _controller] _mainReceivedBytesSoFar:[[dataSource data] length]
                                       fromDataSource:dataSource
                                             complete:YES];
    [super resourceDidFinishLoading:h];
    
    [self release];
}

- (void)resource:(NSURLConnection *)h didFailLoadingWithError:(WebError *)error
{
    ASSERT(![h defersCallbacks]);
    ASSERT(![self defersCallbacks]);
    ASSERT(![[dataSource _controller] defersCallbacks]);

    LOG(Loading, "URL = %@, error = %@", [error failingURL], [error errorDescription]);

    [self receivedError:error];
}

- (void)startLoading:(NSURLRequest *)r
{
    if ([[r URL] _web_shouldLoadAsEmptyDocument]) {
	[self resource:resource willSendRequest:r];

	NSURLResponse *rsp = [[NSURLResponse alloc] init];
	[rsp setURL:[[[self dataSource] request] URL]];
	[rsp setMIMEType:@"text/html"];
	[rsp setExpectedContentLength:0];
	[self resource:resource didReceiveResponse:rsp];
	[rsp release];
    } else {
	[resource loadWithDelegate:proxy];
    }
}

- (void)setDefersCallbacks:(BOOL)defers
{
    if (request && !([[request URL] _web_shouldLoadAsEmptyDocument])) {
	[super setDefersCallbacks:defers];
    }
}


@end

@implementation WebResourceDelegateProxy

- (void)setDelegate:(id <NSURLConnectionDelegate>)theDelegate
{
    delegate = theDelegate;
}

- (NSURLRequest *)resource:(NSURLConnection *)resource willSendRequest:(NSURLRequest *)request
{
    ASSERT(delegate);
    return [delegate resource:resource willSendRequest:request];
}

-(void)resource:(NSURLConnection *)resource didReceiveResponse:(NSURLResponse *)response
{
    ASSERT(delegate);
    [delegate resource:resource didReceiveResponse:response];
}

-(void)resource:(NSURLConnection *)resource didReceiveData:(NSData *)data
{
    ASSERT(delegate);
    [delegate resource:resource didReceiveData:data];
}

-(void)resourceDidFinishLoading:(NSURLConnection *)resource
{
    ASSERT(delegate);
    [delegate resourceDidFinishLoading:resource];
}

-(void)resource:(NSURLConnection *)resource didFailLoadingWithError:(WebError *)error
{
    ASSERT(delegate);
    [delegate resource:resource didFailLoadingWithError:error];
}

@end
