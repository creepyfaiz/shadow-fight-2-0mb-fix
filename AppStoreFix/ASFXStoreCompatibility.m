#import "ASFXStoreCompatibility.h"
#import <sys/stat.h>
#import <unistd.h>

void ASFXFixStorePermissions(void) {
    mkdir("/var/mobile/Library/com.apple.itunesstored", 0777);
    chmod("/var/mobile/Library/com.apple.itunesstored", 0777);
    chown("/var/mobile/Library/com.apple.itunesstored", 501, 501);
    
    chmod("/var/mobile/Library/com.apple.itunesstored/kvs.sqlitedb", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/kvs.sqlitedb", 501, 501);
    chmod("/var/mobile/Library/com.apple.itunesstored/kvs.sqlitedb-journal", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/kvs.sqlitedb-journal", 501, 501);
    chmod("/var/mobile/Library/com.apple.itunesstored/itunesstored2.sqlitedb", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/itunesstored2.sqlitedb", 501, 501);
    chmod("/var/mobile/Library/com.apple.itunesstored/itunesstored2.sqlitedb-journal", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/itunesstored2.sqlitedb-journal", 501, 501);
    chmod("/var/mobile/Library/com.apple.itunesstored/itunesstored_private.sqlitedb", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/itunesstored_private.sqlitedb", 501, 501);
    chmod("/var/mobile/Library/com.apple.itunesstored/itunesstored_private.sqlitedb-journal", 0666);
    chown("/var/mobile/Library/com.apple.itunesstored/itunesstored_private.sqlitedb-journal", 501, 501);
    
    chmod("/var/mobile/Library/Accounts", 0777);
    chown("/var/mobile/Library/Accounts", 501, 501);
    chmod("/var/mobile/Library/Accounts/Accounts3.sqlite", 0666);
    chown("/var/mobile/Library/Accounts/Accounts3.sqlite", 501, 501);
    chmod("/var/mobile/Library/Accounts/Accounts3.sqlite-journal", 0666);
    chown("/var/mobile/Library/Accounts/Accounts3.sqlite-journal", 501, 501);
    
    chmod("/var/mobile/Library/Cookies", 0777);
    chown("/var/mobile/Library/Cookies", 501, 501);
}

static BOOL ASFXIsHistoricalStoreHost(NSString *host) {
    if ([host isEqualToString:@"ax.init.itunes.apple.com"])
        return YES;
    return [host isEqualToString:@"phobos.apple.com"];
}

static BOOL ASFXIsStoreSessionPath(NSString *path) {
    if ([path length] == 0) {
        return NO;
    }

    return [path rangeOfString:@"/bag.xml" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [path rangeOfString:@"/WebObjects/MZInit.woa/" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

NSURL *ASFXStoreURLForRequest(NSURL *url) {
    if (url == nil) {
        return nil;
    }

    NSString *host = [[url host] lowercaseString];
    NSString *path = [url path];
    if (!ASFXIsHistoricalStoreHost(host) || !ASFXIsStoreSessionPath(path)) {
        return url;
    }

    NSString *scheme = [[url scheme] lowercaseString];
    if ([scheme isEqualToString:@"http"]) {
        return url;
    }

    NSMutableString *rewritten = [NSMutableString stringWithString:@"https://init.itunes.apple.com"];
    [rewritten appendString:path ?: @"/"];

    NSString *query = [url query];
    if ([query length] != 0) {
        [rewritten appendFormat:@"?%@", query];
    }

    NSURL *result = [NSURL URLWithString:rewritten];
    if (result != nil) {
        NSLog(@"[AppStoreFix] URL bag endpoint: %@ -> %@", url, result);
        return result;
    }

    return url;
}

static NSString * const ASFXRelayAuthURL = @"https://appstore-relay.ios6-relay.workers.dev/authenticate";

NSURL *ASFXLoginURLForURL(NSURL *url) {
    if (!url) return nil;
    NSString *query = [url query];
    NSMutableString *newURLString = [NSMutableString stringWithString:ASFXRelayAuthURL];
    if ([query length] != 0) {
        [newURLString appendFormat:@"?%@", query];
    }
    return [NSURL URLWithString:newURLString];
}

BOOL ASFXIsAuthenticateRequestURL(NSURL *url) {
    if (!url) return NO;
    NSString *host = [[url host] lowercaseString];
    NSString *path = [url path];
    BOOL isBuyHost = [host hasSuffix:@"buy.itunes.apple.com"] ||
                     [host isEqualToString:@"buy.itunes.apple.com"] ||
                     [host isEqualToString:@"auth.itunes.apple.com"] ||
                     [host isEqualToString:@"appstore-relay.ios6-relay.workers.dev"];
    BOOL isAuthPath = [path caseInsensitiveCompare:@"/WebObjects/MZFinance.woa/wa/authenticate"] == NSOrderedSame ||
                      [path hasPrefix:@"/WebObjects/MZFinance.woa/wa/authenticate"] ||
                      [path hasPrefix:@"/auth/v1/native"] ||
                      [path hasPrefix:@"/authenticate"];
    return isBuyHost && isAuthPath;
}

NSMutableURLRequest *ASFXPrepareLoginRequest(NSMutableURLRequest *request) {
    if (![request isKindOfClass:[NSMutableURLRequest class]]) {
        return request;
    }

    NSURL *url = [request URL];
    if (ASFXIsAuthenticateRequestURL(url)) {
        NSURL *newURL = ASFXLoginURLForURL(url);
        if (newURL != nil) {
            [request setURL:newURL];
            NSLog(@"[AppStoreFix] login endpoint rewritten: %@ -> %@", url, newURL);
        }
    }
    return request;
}

BOOL ASFXIsLoginURL(NSURL *url) {
    NSString *host = [[url host] lowercaseString];
    return [host isEqualToString:@"appstore-relay.ios6-relay.workers.dev"] ||
           [host isEqualToString:@"auth.itunes.apple.com"];
}

static const double ASFXCoreFoundationVersionIOS4 = 550.32;
static const double ASFXCoreFoundationVersionIOS6 = 793.00;

static NSString *ASFXNativeStoreFrontPlatform(void) {
    if (kCFCoreFoundationVersionNumber >= ASFXCoreFoundationVersionIOS6) {
        return @",16";
    }
    if (kCFCoreFoundationVersionNumber >= ASFXCoreFoundationVersionIOS4) {
        return @",2";
    }
    return @",4";
}

NSString *ASFXRepairStoreFront(NSString *storeFront) {
    if (![storeFront isKindOfClass:[NSString class]] || [storeFront length] == 0) {
        return storeFront;
    }
    NSRange comma = [storeFront rangeOfString:@"," options:NSBackwardsSearch];
    if (comma.location == NSNotFound) {
        return [storeFront stringByAppendingString:ASFXNativeStoreFrontPlatform()];
    }
    NSString *prefix = [storeFront substringToIndex:comma.location];
    return [prefix stringByAppendingString:ASFXNativeStoreFrontPlatform()];
}

NSURLResponse *ASFXPrepareLoginResponse(NSURLResponse *response) {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return response;
    }

    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    NSMutableDictionary *headers = [[http allHeaderFields] mutableCopy];
    BOOL changed = NO;
    for (NSString *key in [headers allKeys]) {
        if ([key caseInsensitiveCompare:@"X-Set-Apple-Store-Front"] != NSOrderedSame) {
            continue;
        }

        NSString *storeFront = [headers objectForKey:key];
        NSString *repaired = ASFXRepairStoreFront(storeFront);
        if (![repaired isEqualToString:storeFront]) {
            [headers setObject:repaired forKey:key];
            changed = YES;
            NSLog(@"[AppStoreFix] login storefront %@ -> %@", storeFront, repaired);
        }
    }

    if (!changed) {
        return response;
    }

    return [[NSHTTPURLResponse alloc] initWithURL:[http URL]
                                       statusCode:[http statusCode]
                                      HTTPVersion:@"HTTP/1.1"
                                     headerFields:headers] ?: response;
}

NSMutableURLRequest *ASFXPrepareStoreRequest(NSMutableURLRequest *request) {
    if (![request isKindOfClass:[NSMutableURLRequest class]]) {
        return request;
    }

    NSString *requestStoreFront = [request valueForHTTPHeaderField:@"X-Apple-Store-Front"];
    NSString *repairedStoreFront = ASFXRepairStoreFront(requestStoreFront);
    if (requestStoreFront != nil && ![repairedStoreFront isEqualToString:requestStoreFront]) {
        [request setValue:repairedStoreFront forHTTPHeaderField:@"X-Apple-Store-Front"];
    }

    NSURL *url = [request URL];
    NSString *absolute = [url absoluteString];
    if ([absolute rangeOfString:@"/WebObjects/MZStore.woa/wa/search"].location != NSNotFound ||
        [absolute rangeOfString:@"/WebObjects/MZSearch.woa/wa/search"].location != NSNotFound) {
        
        NSString *rewritten = absolute;
        if ([rewritten rangeOfString:@"MZStore.woa"].location != NSNotFound) {
            rewritten = [rewritten stringByReplacingOccurrencesOfString:@"MZStore.woa"
                                                             withString:@"MZSearch.woa"];
        }

        if ([rewritten rangeOfString:@"media=software"].location == NSNotFound) {
            if ([rewritten rangeOfString:@"?"].location != NSNotFound) {
                rewritten = [rewritten stringByAppendingString:@"&media=software"];
            } else {
                rewritten = [rewritten stringByAppendingString:@"?media=software"];
            }
        }

        NSURL *searchURL = [NSURL URLWithString:rewritten];
        if (searchURL != nil) {
            [request setURL:searchURL];
            NSLog(@"[AppStoreFix] search endpoint rewritten: %@ -> %@", url, searchURL);
        }
    } else if ([absolute rangeOfString:@"/WebObjects/MZBuy.woa/wa/buyProduct"].location != NSNotFound &&
               [[request HTTPMethod] isEqualToString:@"POST"] &&
               [request valueForHTTPHeaderField:@"Content-Type"] == nil) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }

    return request;
}

static __attribute__((unused)) BOOL ASFXPreferenceEnabled(NSString *key) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.victorlobe.appstorefix.plist"];
    return [[prefs objectForKey:key] boolValue];
}

static __attribute__((unused)) BOOL ASFXIsGeniusTab(id tab) {
    if (![tab isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    return [[tab objectForKey:@"canonical-name"] isEqual:@"genius"] ||
        [[tab objectForKey:@"url-bag-key"] isEqual:@"p2-panda-appRecommendations"];
}

static NSArray *ASFXSectionIdentifiers(NSDictionary *dictionary) {
    id tabs = [dictionary objectForKey:@"tabs"];
    if ([tabs isKindOfClass:[NSDictionary class]]) {
        return ASFXSectionIdentifiers(tabs);
    }
    if (![tabs isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray *identifiers = [NSMutableArray array];
    for (id tab in tabs) {
        id identifier = [tab isKindOfClass:[NSDictionary class]] ? [tab objectForKey:@"canonical-name"] : nil;
        if ([identifier isKindOfClass:[NSString class]]) {
            [identifiers addObject:identifier];
        }
    }
    return identifiers;
}

static void ASFXResetStaleTabOrdering(NSDictionary *dictionary) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *ordering = [defaults arrayForKey:@"SURootSections"];
    NSArray *identifiers = ASFXSectionIdentifiers(dictionary);
    if (ordering == nil || [identifiers count] == 0 || [ordering isEqualToArray:identifiers]) {
        return;
    }
    if (![ordering containsObject:@"genius"] && ![identifiers containsObject:@"genius"]) {
        return;
    }

    [defaults removeObjectForKey:@"SURootSections"];
    [defaults synchronize];
    NSLog(@"[AppStoreFix] tab ordering reset: %@ -> %@",
          [ordering componentsJoinedByString:@","], [identifiers componentsJoinedByString:@","]);
}

static __attribute__((unused)) void ASFXResetGeniusNavigationPath(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *path = [defaults dataForKey:@"SUSectionNavigationPath"];
    NSData *genius = [@"p2-panda-appRecommendations" dataUsingEncoding:NSUTF8StringEncoding];
    if (path == nil || [path rangeOfData:genius options:0 range:NSMakeRange(0, [path length])].location == NSNotFound) {
        return;
    }
    
    [defaults removeObjectForKey:@"SUSectionNavigationPath"];
    [defaults synchronize];
    NSLog(@"[AppStoreFix] saved Genius page dropped");
}

NSDictionary *ASFXPrepareStoreSectionsDictionary(NSDictionary *dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return dictionary;
    }

    NSMutableDictionary *dictCopy = [dictionary mutableCopy];
    id tabs = [dictCopy objectForKey:@"tabs"];
    if ([tabs isKindOfClass:[NSArray class]]) {
        NSMutableArray *newTabs = [NSMutableArray array];
        for (id tab in tabs) {
            if ([tab isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *mTab = [tab mutableCopy];
                NSString *name = [mTab objectForKey:@"canonical-name"];
                if ([name isEqualToString:@"genius"]) {
                    continue;
                }
                if ([name isEqualToString:@"search"]) {
                    [mTab setObject:@1 forKey:@"active-tab"];
                } else if ([name isEqualToString:@"featured"]) {
                    [mTab setObject:@0 forKey:@"active-tab"];
                    [mTab setObject:@"https://appstore-relay.ios6-relay.workers.dev/featured" forKey:@"url"];
                } else {
                    [mTab setObject:@0 forKey:@"active-tab"];
                }
                [newTabs addObject:mTab];
            }
        }
        [dictCopy setObject:newTabs forKey:@"tabs"];
    }

    ASFXResetStaleTabOrdering(dictCopy);
    return dictCopy;
}

static BOOL ASFXDictionaryLooksLikeStoreBag(NSDictionary *dictionary) {
    if (dictionary == nil) {
        return NO;
    }

    NSArray *markers = @[
        @"certs",
        @"protocols",
        @"urls",
        @"storefront",
        @"storefront-version",
        @"country-code"
    ];
    for (NSString *key in markers) {
        if ([dictionary objectForKey:key] != nil) {
            return YES;
        }
    }
    
    return NO;
}

BOOL ASFXLooksLikeStoreURLBagData(id data) {
    if ([data isKindOfClass:[NSDictionary class]]) {
        return ASFXDictionaryLooksLikeStoreBag((NSDictionary *)data);
    }

    if (![data isKindOfClass:[NSData class]]) {
        return NO;
    }

    NSData *bytes = (NSData *)data;
    if (!bytes.length) {
        return NO;
    }

    id propertyList = [NSPropertyListSerialization propertyListWithData:bytes
                                                                options:0
                                                                 format:NULL
                                                                  error:NULL];
    if ([propertyList isKindOfClass:[NSDictionary class]] && ASFXDictionaryLooksLikeStoreBag(propertyList)) {
        return YES;
    }

    NSString *text = [[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
    BOOL hasAppleURL = [text rangeOfString:@"itunes.apple.com"
                                   options:NSCaseInsensitiveSearch].location != NSNotFound;
    BOOL hasBagField = [text rangeOfString:@"storefront"
                                   options:NSCaseInsensitiveSearch].location != NSNotFound ||
                       [text rangeOfString:@"certs"
                                   options:NSCaseInsensitiveSearch].location != NSNotFound;
    if (hasAppleURL && hasBagField) {
        return YES;
    }

    return NO;
}

NSDictionary *ASFXPrepareStoreURLBag(NSDictionary *bag) {
    if (![bag isKindOfClass:[NSDictionary class]]) {
        return bag;
    }

    NSMutableDictionary *preparedBag = [bag mutableCopy];
    if (!preparedBag) {
        preparedBag = [NSMutableDictionary dictionaryWithDictionary:bag];
    }

    NSString *relayAuth = @"https://appstore-relay.ios6-relay.workers.dev/authenticate";
    [preparedBag setObject:relayAuth forKey:@"authenticateAccount"];
    [preparedBag setObject:relayAuth forKey:@"authenticate"];
    [preparedBag setObject:relayAuth forKey:@"authenticateSrv"];

    id certs = [bag objectForKey:@"certs"];
    if ([certs isKindOfClass:[NSArray class]]) {
        NSLog(@"[AppStoreFix] URL bag accepted with %lu server certificates",
              (unsigned long)[certs count]);
    } else if (certs == nil) {
        NSLog(@"[AppStoreFix] URL bag has no certificate list.... using system trust");
    }

    return preparedBag;
}
