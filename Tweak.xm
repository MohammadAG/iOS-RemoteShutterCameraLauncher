#import <UIKit/UIKit.h>
#import <IOKit/hid/IOHIDEventSystem.h>
#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

#define VOL_BUTTON_UP 0xe9
#define VOL_UP_USAGE_PAGE 12
#define CAMERA_APP_TO_LAUNCH @"com.apple.camera"

@interface SpringBoard
- (_Bool)launchApplicationWithIdentifier:(id)arg1 suspended:(_Bool)arg2;
- (id)_accessibilityFrontMostApplication;
- (BOOL)areHeadsetControlsLikelyAvailable;
@end

@interface SBApplication
- (NSString *)displayIdentifier;
@end

static BOOL suppressNextUpEvent = NO;

%hook SpringBoard

%new
- (BOOL)areHeadsetControlsLikelyAvailable
{
    // Get array of current audio outputs (there should only be one)
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    
    NSString *portName = [[outputs objectAtIndex:0] portName];
    
    if ([portName isEqual:AVAudioSessionPortBuiltInSpeaker]
        || [portName isEqualToString:AVAudioSessionPortAirPlay]
        || [portName isEqual:AVAudioSessionPortLineOut]) {
        return NO;
    }
    
    return YES;
}

- (_Bool)__handleHIDEvent:(struct __IOHIDEvent *)event {
    // Maybe we should check where the IOHIDEvent came from, rather than
    // completely bailing if a headset is connected, but how?
    if ([self areHeadsetControlsLikelyAvailable])
        return %orig;

    IOHIDEventType type = IOHIDEventGetType(event);
    int usage = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardUsage);
    int usagePage = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardUsagePage);
    int down = IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardDown);
    
    if (usage != VOL_BUTTON_UP || usagePage != VOL_UP_USAGE_PAGE || type != kIOHIDEventTypeKeyboard)
        return %orig;

    if (down) {
        SpringBoard *sb = (SpringBoard *) [UIApplication sharedApplication];
        SBApplication *frontApp = [sb _accessibilityFrontMostApplication];
        NSString *currentAppDisplayID = [frontApp displayIdentifier];
        
        if (![currentAppDisplayID isEqual:CAMERA_APP_TO_LAUNCH]) {
            [sb launchApplicationWithIdentifier:CAMERA_APP_TO_LAUNCH suspended:NO];
            suppressNextUpEvent = YES;
            return NO;
        } else {
            return %orig;
        }
    }
    
    if (!down && suppressNextUpEvent) {
        suppressNextUpEvent = NO;
        return NO;
    }
    return %orig;
}

%end
