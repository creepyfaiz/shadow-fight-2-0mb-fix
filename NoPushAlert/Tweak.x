#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// -----------------------------------------------------------------------------
// Declarations for SpringBoard internal classes
// -----------------------------------------------------------------------------
@interface SBAlertItem : NSObject
- (void)configure:(BOOL)requirePasscode requirePasscodeForActions:(BOOL)requireForActions;
- (void)deactivate;
- (id)alertSheet;
@end

@interface SBRemoteNotificationNeedIdentityAlert : SBAlertItem
- (id)initWithApplication:(id)app;
@end

@interface SBAlertItemsController : NSObject
+ (id)sharedInstance;
- (void)activateAlertItem:(id)item;
- (void)deactivateAlertItem:(id)item;
@end

// -----------------------------------------------------------------------------
// SpringBoard Hooks
// -----------------------------------------------------------------------------
%group SpringBoardHooks

%hook SBAlertItemsController

- (void)activateAlertItem:(id)item {
    if (item != nil) {
        NSString *className = NSStringFromClass([item class]);
        
        // 1. Check exact class name or substring
        if ([className isEqualToString:@"SBRemoteNotificationNeedIdentityAlert"] ||
            [className rangeOfString:@"NeedIdentity"].location != NSNotFound) {
            NSLog(@"[NoPushAlert] Suppressed SpringBoard alert item: %@", className);
            return;
        }
        
        // 2. Check alert sheet title if present
        if ([item respondsToSelector:@selector(alertSheet)]) {
            id sheet = [item alertSheet];
            if (sheet && [sheet respondsToSelector:@selector(title)]) {
                NSString *title = [sheet title];
                if (title && [title rangeOfString:@"iTunes" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    if ([title rangeOfString:@"push" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [title rangeOfString:@"уведомлен" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                        [title rangeOfString:@"notif" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        NSLog(@"[NoPushAlert] Suppressed SpringBoard alert sheet with title: %@", title);
                        return;
                    }
                }
            }
        }
    }
    %orig;
}

%end

%hook SBRemoteNotificationNeedIdentityAlert

- (id)initWithApplication:(id)app {
    NSLog(@"[NoPushAlert] Blocked SBRemoteNotificationNeedIdentityAlert initialization");
    self = %orig;
    if (self) {
        [self release];
        self = nil;
    }
    return nil;
}

- (void)configure:(BOOL)requirePasscode requirePasscodeForActions:(BOOL)requireForActions {
    NSLog(@"[NoPushAlert] Blocked SBRemoteNotificationNeedIdentityAlert configure");
    return;
}

%end

%end // SpringBoardHooks

// -----------------------------------------------------------------------------
// UIKit Hooks (for any app that might display a modal alert)
// -----------------------------------------------------------------------------
%group UIKitHooks

%hook UIAlertView

- (void)show {
    NSString *title = [self title];
    if (title != nil) {
        if ([title rangeOfString:@"iTunes" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            if ([title rangeOfString:@"push" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [title rangeOfString:@"уведомлен" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [title rangeOfString:@"notif" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                NSLog(@"[NoPushAlert] Suppressed UIAlertView with title: %@", title);
                return;
            }
        }
    }
    %orig;
}

%end

%end // UIKitHooks

// -----------------------------------------------------------------------------
// Constructor
// -----------------------------------------------------------------------------
%ctor {
    @autoreleasepool {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSLog(@"[NoPushAlert] Loaded in process: %@", bundleId);
        
        if (objc_getClass("SBAlertItemsController") != Nil) {
            NSLog(@"[NoPushAlert] SBAlertItemsController detected, initializing SpringBoard hooks");
            %init(SpringBoardHooks);
        }
        
        %init(UIKitHooks);
    }
}
