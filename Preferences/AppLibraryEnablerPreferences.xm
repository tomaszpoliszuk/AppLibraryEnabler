/* App Library Enabler - Enable App Library on iPadOS
 * Copyright (C) 2020 Tomasz Poliszuk
 *
 * App Library Enabler is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * App Library Enabler is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with App Library Enabler. If not, see <https://www.gnu.org/licenses/>.
 */

#include <SpringBoard/SBIconController.h>

#include <Preferences/PSSpecifier.h>
#include <Preferences/PSListController.h>

#define kPackage @"com.apple.springboard"
#define kSettingsChanged @"com.apple.springboard-prefsChanged"

@interface PSSpecifier (AppLibraryEnabler)
- (void)setValues:(id)values titles:(id)titles;
@end

@interface DBSHomeScreenListController : PSListController
@end

@interface SBIconController (Additions)
-(void)_showsBadgesInAppLibraryDidChange;
@end

%hook DBSHomeScreenListController
- (NSMutableArray *)specifiers {
	NSMutableArray *specifiers = %orig;

	PSSpecifier* appDownloadsGoTo = [PSSpecifier groupSpecifierWithName:@"Newly Downloaded Apps"];
	[appDownloadsGoTo setProperty:@"APP_DOWNLOADS_GO_TO" forKey:@"ID"];

	PSSpecifier *automaticallyAddsNewApplications = [PSSpecifier preferenceSpecifierNamed:@"SBHomeAutomaticallyAddsNewApplications"
		target:self
		set:@selector(setPreferenceValue:specifier:)
		get:@selector(readPreferenceValue:)
		detail:nil
		cell:PSSegmentCell
		edit:nil
	];
	[automaticallyAddsNewApplications setProperty:@"999" forKey:@"default"];
	[automaticallyAddsNewApplications setProperty:@"SBHomeAutomaticallyAddsNewApplications" forKey:@"key"];
	[automaticallyAddsNewApplications setValues:@[ @"YES", @"NO" ] titles:@[ @"Add to Home Screen", @"App Library Only" ]];
	[automaticallyAddsNewApplications setProperty:kPackage forKey:@"defaults"];
	[automaticallyAddsNewApplications setProperty:kSettingsChanged forKey:@"PostNotification"];
	[automaticallyAddsNewApplications setProperty:@"55" forKey:@"height"];

	PSSpecifier* notificationBadges = [PSSpecifier groupSpecifierWithName:@"Notification Badges"];
	[notificationBadges setProperty:@"NOTIFICATION_BADGES" forKey:@"ID"];

	PSSpecifier *showInAppLibrary = [PSSpecifier preferenceSpecifierNamed:@"Show in App Library"
		target:self
		set:@selector(setPreferenceValue:specifier:)
		get:@selector(readPreferenceValue:)
		detail:nil
		cell:PSSwitchCell
		edit:nil
	];
	[showInAppLibrary setProperty:@"YES" forKey:@"default"];
	[showInAppLibrary setProperty:@"SBHomeScreenShowsBadgesInAppLibrary" forKey:@"key"];
	[showInAppLibrary setProperty:@"Show in App Library" forKey:@"ID"];
	[showInAppLibrary setProperty:@"Show in App Library" forKey:@"label"];
	[showInAppLibrary setProperty:kPackage forKey:@"defaults"];
	[showInAppLibrary setProperty:kSettingsChanged forKey:@"PostNotification"];
	[showInAppLibrary setProperty:@"55" forKey:@"height"];

	[specifiers addObject:appDownloadsGoTo];
	[specifiers addObject:automaticallyAddsNewApplications];
	[specifiers addObject:notificationBadges];
	[specifiers addObject:showInAppLibrary];

	return specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	%orig;
	PSSpecifier *showinAppLibrary = [self specifierForID:@"Show in App Library"];
	if (specifier == showinAppLibrary) {
		[[%c(SBIconController) sharedInstance] _showsBadgesInAppLibraryDidChange];
	}
}
%end
