#import "AppUpdaterPlugin.h"
#import <app_updater/app_updater-Swift.h>

@implementation AppUpdaterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppUpdaterPlugin registerWithRegistrar:registrar];
}
@end
