#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface SBAlertItem : NSObject
- (void)configure:(BOOL)requirePasscode requirePasscodeForActions:(BOOL)requireForActions;
- (void)deactivate;
@end

@interface SBAlertItemsController : NSObject
+ (id)sharedInstance;
- (void)activateAlertItem:(id)item;
- (void)deactivateAlertItem:(id)item;
@end

%hook SBAlertItemsController

- (void)activateAlertItem:(id)item {
    if (item == nil) {
        return;
    }

    Class needIdentityClass = objc_getClass("SBRemoteNotificationNeedIdentityAlert");
    if (needIdentityClass != Nil && [item isKindOfClass:needIdentityClass]) {
        NSLog(@"[NoPushAlert] Suppressed SBRemoteNotificationNeedIdentityAlert item (%p)", item);
        return;
    }

    NSString *className = NSStringFromClass([item class]);
    if (className != nil && [className rangeOfString:@"NeedIdentity"].location != NSNotFound) {
        NSLog(@"[NoPushAlert] Suppressed alert item of class %@", className);
        return;
    }

    %orig(item);
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[NoPushAlert] Loaded into SpringBoard");
        %init;
    }
}
