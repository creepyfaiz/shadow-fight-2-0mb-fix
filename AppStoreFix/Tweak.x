#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Security/SecureTransport.h>
#import <substrate.h>
#import <dlfcn.h>
#import "ASFXBootstrapBridge.h"
#import "ASFXStoreCompatibility.h"

@interface SSAccount : NSObject
- (id)init;
- (NSString *)accountName;
- (void)setAccountName:(NSString *)name;
- (void)setStoreAccountAppleID:(NSString *)name;
- (void)setStoreAccountID:(NSNumber *)num;
- (void)setUniqueIdentifier:(NSNumber *)num;
- (void)setStoreFrontIdentifier:(NSString *)sf;
- (void)setAuthenticated:(BOOL)auth;
- (void)setActive:(BOOL)active;
- (BOOL)isAuthenticated;
- (BOOL)isValid;
@end

@interface SSAccountStore : NSObject
+ (id)defaultStore;
- (SSAccount *)activeAccount;
- (void)addAccount:(SSAccount *)account;
- (void)setActiveAccount:(SSAccount *)account;
- (void)saveAccount:(SSAccount *)account withCompletionHandler:(void(^)(BOOL success, NSError *error))handler;
@end

@interface SSAuthenticateResponse : NSObject
- (void)setAuthenticateResponseType:(NSInteger)type;
- (void)setAuthenticatedAccount:(SSAccount *)account;
@end

@interface ISDialog : NSObject
- (BOOL)exitOnDismiss;
- (void)setExitOnDismiss:(BOOL)exit;
- (NSArray *)textFields;
- (NSString *)message;
- (BOOL)isDisplayable;
@end

@interface SUClientController : NSObject
- (void)exitStoreWithReason:(NSInteger)reason;
@end

@interface ASClientApplicationController : SUClientController
@end

@interface SignInPromptOperation : NSObject
- (void)_setSignInResponse:(id)response;
- (void)setSuccess:(BOOL)success;
@end

@interface AuthenticateAttemptOperation : NSObject
- (void)_setAuthenticateResponseWithAccount:(id)account type:(NSInteger)type;
- (void)setSuccess:(BOOL)success;
@end

@interface AuthenticateOperation : NSObject
- (void)_setAuthenticateResponseWithAccount:(id)account type:(NSInteger)type;
- (void)setSuccess:(BOOL)success;
@end

static OSStatus (*ASFXOriginalSSLHandshake)(SSLContextRef context);

static OSStatus ASFXSSLHandshake(SSLContextRef context) {
    OSStatus minStatus = SSLSetProtocolVersionMin(context, kTLSProtocol1);
    OSStatus maxStatus = SSLSetProtocolVersionMax(context, kTLSProtocol12);
    OSStatus handshakeStatus = ASFXOriginalSSLHandshake(context);

    SSLProtocol negotiatedProtocol = kSSLProtocolUnknown;
    OSStatus negotiatedStatus =
        SSLGetNegotiatedProtocolVersion(context, &negotiatedProtocol);

    NSLog(@"[AppStoreFix] SecureTransport min=%d max=%d handshake=%d negotiated=%d read=%d",
          (int)minStatus,
          (int)maxStatus,
          (int)handshakeStatus,
          (int)negotiatedProtocol,
          (int)negotiatedStatus);

    return handshakeStatus;
}

static void ASFXEnsureAccountActive(void) {
    NSString *progName = [[NSProcessInfo processInfo] processName];
    if (![progName isEqualToString:@"Preferences"] &&
        ![progName isEqualToString:@"AppStore"]) {
        return;
    }

    Class accountStoreClass = NSClassFromString(@"SSAccountStore");
    Class accountClass = NSClassFromString(@"SSAccount");
    if (!accountStoreClass || !accountClass) {
        return;
    }

    SSAccountStore *defaultStore = [accountStoreClass defaultStore];
    if (!defaultStore) {
        return;
    }

    SSAccount *activeAccount = [defaultStore activeAccount];
    NSString *activeName = [activeAccount accountName];
    if (activeName && [activeName length] > 0) {
        NSLog(@"[AppStoreFix] Active store account already active: %@", activeName);
        return;
    }

    NSLog(@"[AppStoreFix] No active store account found. Activating creepyid@mail.ru...");
    SSAccount *acc = [[accountClass alloc] init];
    [acc setAccountName:@"creepyid@mail.ru"];
    if ([acc respondsToSelector:@selector(setStoreAccountAppleID:)]) {
        [acc setStoreAccountAppleID:@"creepyid@mail.ru"];
    }
    if ([acc respondsToSelector:@selector(setStoreAccountID:)]) {
        [acc setStoreAccountID:[NSNumber numberWithLongLong:20919833453ULL]];
    }
    if ([acc respondsToSelector:@selector(setUniqueIdentifier:)]) {
        [acc setUniqueIdentifier:[NSNumber numberWithLongLong:20919833453ULL]];
    }
    if ([acc respondsToSelector:@selector(setStoreFrontIdentifier:)]) {
        [acc setStoreFrontIdentifier:@"143469-16,2"];
    }
    if ([acc respondsToSelector:@selector(setAuthenticated:)]) {
        [acc setAuthenticated:YES];
    }
    if ([acc respondsToSelector:@selector(setActive:)]) {
        [acc setActive:YES];
    }

    if ([defaultStore respondsToSelector:@selector(addAccount:)]) {
        [defaultStore addAccount:acc];
    }
    if ([defaultStore respondsToSelector:@selector(setActiveAccount:)]) {
        [defaultStore setActiveAccount:acc];
    }
    if ([defaultStore respondsToSelector:@selector(saveAccount:withCompletionHandler:)]) {
        [defaultStore saveAccount:acc withCompletionHandler:^(BOOL success, NSError *err) {
            NSLog(@"[AppStoreFix] saveAccount completed: success=%d err=%@", success, err);
            if (success && [defaultStore respondsToSelector:@selector(setActiveAccount:)]) {
                [defaultStore setActiveAccount:acc];
            }
        }];
    }
}

// ----------------- COMMON HOOKS (Both AppStore & itunesstored) -----------------
%group CommonHooks

%hook SSAccount

- (BOOL)isAuthenticated {
    return YES;
}

- (BOOL)isValid {
    return YES;
}

%end

%hook SSAuthenticateRequest

- (void)startWithAuthenticateResponseBlock:(void (^)(id response, NSError *error))block {
    NSLog(@"[AppStoreFix] SSAuthenticateRequest BYPASSED with success!");
    if (block) {
        Class respClass = NSClassFromString(@"SSAuthenticateResponse");
        id resp = [[respClass alloc] init];
        if ([resp respondsToSelector:@selector(setAuthenticateResponseType:)]) {
            [resp setAuthenticateResponseType:0]; // 0 = SSAuthenticateResponseTypeSuccess
        }
        Class storeClass = NSClassFromString(@"SSAccountStore");
        id acc = [[storeClass defaultStore] activeAccount];
        if ([resp respondsToSelector:@selector(setAuthenticatedAccount:)]) {
            [resp setAuthenticatedAccount:acc];
        }
        block(resp, nil);
        return;
    }
    %orig(block);
}

- (BOOL)start {
    NSLog(@"[AppStoreFix] SSAuthenticateRequest start BYPASSED!");
    return YES;
}

%end

%hook ISDialog

- (BOOL)exitOnDismiss {
    return NO;
}

- (void)setExitOnDismiss:(BOOL)exit {
    %orig(NO);
}

- (BOOL)isDisplayable {
    NSArray *fields = nil;
    if ([self respondsToSelector:@selector(textFields)]) {
        fields = [self textFields];
    }
    if ([fields count] > 0) {
        NSLog(@"[AppStoreFix] Suppressed password prompt ISDialog: %@", [self message]);
        return NO;
    }
    return %orig;
}

%end

%hook ISURLBag

- (id)urlForKey:(id)key inBagContext:(id)context {
    if ([key isEqualToString:@"authenticateAccount"] ||
        [key isEqualToString:@"authenticateSrv"] ||
        [key isEqualToString:@"authenticate"]) {
        NSLog(@"[AppStoreFix] ISURLBag urlForKey:%@ inBagContext: -> Relay", key);
        return [NSURL URLWithString:@"https://appstore-relay.ios6-relay.workers.dev/authenticate"];
    }
    return %orig(key, context);
}

- (id)urlForKey:(id)key {
    if ([key isEqualToString:@"authenticateAccount"] ||
        [key isEqualToString:@"authenticateSrv"] ||
        [key isEqualToString:@"authenticate"]) {
        NSLog(@"[AppStoreFix] ISURLBag urlForKey:%@ -> Relay", key);
        return [NSURL URLWithString:@"https://appstore-relay.ios6-relay.workers.dev/authenticate"];
    }
    return %orig(key);
}

- (id)valueForKey:(id)key inBagContext:(id)context {
    if ([key isEqualToString:@"authenticateAccount"] ||
        [key isEqualToString:@"authenticateSrv"] ||
        [key isEqualToString:@"authenticate"]) {
        NSLog(@"[AppStoreFix] ISURLBag valueForKey:%@ inBagContext: -> Relay", key);
        return @"https://appstore-relay.ios6-relay.workers.dev/authenticate";
    }
    return %orig(key, context);
}

- (id)valueForBagKey:(id)key {
    if ([key isEqualToString:@"authenticateAccount"] ||
        [key isEqualToString:@"authenticateSrv"] ||
        [key isEqualToString:@"authenticate"]) {
        NSLog(@"[AppStoreFix] ISURLBag valueForBagKey:%@ -> Relay", key);
        return @"https://appstore-relay.ios6-relay.workers.dev/authenticate";
    }
    return %orig(key);
}

- (id)URLForURLBagKey:(id)key {
    if ([key isEqualToString:@"authenticateAccount"] ||
        [key isEqualToString:@"authenticateSrv"] ||
        [key isEqualToString:@"authenticate"]) {
        NSLog(@"[AppStoreFix] ISURLBag URLForURLBagKey:%@ -> Relay", key);
        return [NSURL URLWithString:@"https://appstore-relay.ios6-relay.workers.dev/authenticate"];
    }
    return %orig(key);
}

%end

%hook ISURLOperation

- (id)newRequestWithURL:(NSURL *)url {
    NSURL *rewritten = ASFXStoreURLForRequest(url);
    NSMutableURLRequest *request = %orig(rewritten);

    NSURL *requestURL = [request URL];
    if (ASFXIsAuthenticateRequestURL(requestURL)) {
        request = ASFXPrepareLoginRequest(request);
    } else {
        request = ASFXPrepareStoreRequest(request);
    }
    return request;
}

- (BOOL)_runRequestWithURL:(NSURL *)url {
    NSURL *rewritten = ASFXStoreURLForRequest(url);
    return %orig(rewritten);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (ASFXIsLoginURL([response URL])) {
        response = ASFXPrepareLoginResponse(response);
    }
    %orig(connection, response);
}

- (BOOL)_isTrustExtendedValidation:(SecTrustRef)trust {
    if (!trust) {
        return NO;
    }

    SecTrustResultType result = kSecTrustResultInvalid;
    OSStatus status = SecTrustEvaluate(trust, &result);
    BOOL accepted = NO;
    if (status == errSecSuccess) {
        accepted = result == kSecTrustResultProceed || result == kSecTrustResultUnspecified;
    }
    NSLog(@"[AppStoreFix] trust evaluation status=%d result=%d accepted=%d",
          (int)status, (int)result, accepted ? 1 : 0);
    return accepted;
}

%end

%hook ISStoreURLOperation

- (id)newRequestWithURL:(NSURL *)url {
    return ASFXPrepareStoreRequest(%orig(url));
}

%end

%hook ISCertificate

- (BOOL)checkData:(id)data againstSignature:(id)signature {
    if (ASFXLooksLikeStoreURLBagData(data)) {
        NSLog(@"[AppStoreFix] accepted Store URL bag signature");
        return YES;
    }

    return %orig;
}

%end

%hook ISLoadURLBagOperation

- (void)operation:(id)operation finishedWithOutput:(NSDictionary *)outputBag {
    NSDictionary *preparedBag = ASFXPrepareStoreURLBag(outputBag);
    %orig(operation, preparedBag);
}

%end

%hook NSMutableURLRequest

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field caseInsensitiveCompare:@"X-Apple-Store-Front"] == NSOrderedSame) {
        value = ASFXRepairStoreFront(value);
    }
    %orig(value, field);
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field caseInsensitiveCompare:@"X-Apple-Store-Front"] == NSOrderedSame) {
        value = ASFXRepairStoreFront(value);
    }
    %orig(value, field);
}

- (void)setURL:(NSURL *)url {
    if (ASFXIsAuthenticateRequestURL(url)) {
        NSURL *rewritten = ASFXLoginURLForURL(url);
        if (rewritten) {
            NSLog(@"[AppStoreFix] [NSMutableURLRequest setURL:] %@ -> %@", url, rewritten);
            url = rewritten;
        }
    }
    %orig(url);
}

%end

%hook NSURLRequest

- (id)initWithURL:(NSURL *)url {
    if (ASFXIsAuthenticateRequestURL(url)) {
        NSURL *rewritten = ASFXLoginURLForURL(url);
        if (rewritten) {
            NSLog(@"[AppStoreFix] [NSURLRequest initWithURL:] %@ -> %@", url, rewritten);
            url = rewritten;
        }
    }
    return %orig(url);
}

- (id)initWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    if (ASFXIsAuthenticateRequestURL(url)) {
        NSURL *rewritten = ASFXLoginURLForURL(url);
        if (rewritten) {
            NSLog(@"[AppStoreFix] [NSURLRequest initWithURL:cachePolicy:...] %@ -> %@", url, rewritten);
            url = rewritten;
        }
    }
    return %orig(url, cachePolicy, timeoutInterval);
}

%end

%end // CommonHooks

// ----------------- APP STORE UI HOOKS -----------------
%group AppStoreUIHooks

%hook SUClientController

- (void)exitStoreWithReason:(NSInteger)reason {
    NSLog(@"[AppStoreFix] Suppressed SUClientController exitStoreWithReason: %ld", (long)reason);
}

%end

%hook ASClientApplicationController

- (void)exitStoreWithReason:(NSInteger)reason {
    NSLog(@"[AppStoreFix] Suppressed ASClientApplicationController exitStoreWithReason: %ld", (long)reason);
}

%end

%hook SUSectionsResponse

- (id)_newSectionsFromDictionary:(NSDictionary *)dictionary {
    return %orig(ASFXPrepareStoreSectionsDictionary(dictionary));
}

%end

%end // AppStoreUIHooks

// ----------------- ITUNESSTORED DAEMON HOOKS -----------------
%group DaemonHooks

%hook SignInPromptOperation

- (void)run {
    NSLog(@"[AppStoreFix] SignInPromptOperation BYPASSED without dialog!");
    Class storeClass = NSClassFromString(@"SSAccountStore");
    id acc = [[storeClass defaultStore] activeAccount];
    Class respClass = NSClassFromString(@"SSAuthenticateResponse");
    id resp = [[respClass alloc] init];
    if ([resp respondsToSelector:@selector(setAuthenticateResponseType:)]) {
        [resp setAuthenticateResponseType:0];
    }
    if ([resp respondsToSelector:@selector(setAuthenticatedAccount:)]) {
        [resp setAuthenticatedAccount:acc];
    }
    if ([self respondsToSelector:@selector(_setSignInResponse:)]) {
        [self _setSignInResponse:resp];
    }
    if ([self respondsToSelector:@selector(setSuccess:)]) {
        [self setSuccess:YES];
    }
}

%end

%hook AuthenticateAttemptOperation

- (void)run {
    NSLog(@"[AppStoreFix] AuthenticateAttemptOperation BYPASSED with success!");
    Class storeClass = NSClassFromString(@"SSAccountStore");
    id acc = [[storeClass defaultStore] activeAccount];
    if ([self respondsToSelector:@selector(_setAuthenticateResponseWithAccount:type:)]) {
        [self _setAuthenticateResponseWithAccount:acc type:0];
    }
    if ([self respondsToSelector:@selector(setSuccess:)]) {
        [self setSuccess:YES];
    }
}

%end

%hook AuthenticateOperation

- (void)run {
    NSLog(@"[AppStoreFix] AuthenticateOperation BYPASSED with success!");
    Class storeClass = NSClassFromString(@"SSAccountStore");
    id acc = [[storeClass defaultStore] activeAccount];
    if ([self respondsToSelector:@selector(_setAuthenticateResponseWithAccount:type:)]) {
        [self _setAuthenticateResponseWithAccount:acc type:0];
    }
    if ([self respondsToSelector:@selector(setSuccess:)]) {
        [self setSuccess:YES];
    }
}

%end

%end // DaemonHooks

%ctor {
    NSString *progName = [[NSProcessInfo processInfo] processName];
    if (getuid() == 0) {
        ASFXFixStorePermissions();
        NSLog(@"[AppStoreFix] Permissions repaired by root daemon (pid=%d)", getpid());
        return;
    }

    if (![progName isEqualToString:@"AppStore"] &&
        ![progName isEqualToString:@"itunesstored"] &&
        ![progName isEqualToString:@"Preferences"] &&
        ![progName isEqualToString:@"MobileStore"]) {
        return;
    }

    dlopen("/System/Library/PrivateFrameworks/StoreServices.framework/StoreServices", RTLD_NOW | RTLD_GLOBAL);
    dlopen("/System/Library/PrivateFrameworks/iTunesStore.framework/iTunesStore", RTLD_NOW | RTLD_GLOBAL);

    MSHookFunction((void *)SSLHandshake,
                   (void *)ASFXSSLHandshake,
                   (void **)&ASFXOriginalSSLHandshake);

    %init(CommonHooks);

    if ([progName isEqualToString:@"AppStore"] || [progName isEqualToString:@"MobileStore"]) {
        dlopen("/System/Library/PrivateFrameworks/iTunesStoreUI.framework/iTunesStoreUI", RTLD_NOW | RTLD_GLOBAL);
        dlopen("/System/Library/PrivateFrameworks/AppStoreUI.framework/AppStoreUI", RTLD_NOW | RTLD_GLOBAL);
        [ASFXBootstrapBridge install];
        %init(AppStoreUIHooks);
    }

    if ([progName isEqualToString:@"itunesstored"]) {
        %init(DaemonHooks);
    }

    NSLog(@"[AppStoreFix] Store compatibility loaded for %@ (pid=%d uid=%d)", progName, getpid(), getuid());
    ASFXEnsureAccountActive();
}
