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


@protocol SBHOccludable
@end

@interface SBHRootSidebarController : UIViewController
@property (nonatomic, retain) UIViewController *avocadoViewController;
@end

@interface SBHomeScreenOverlayViewController : UIViewController
@property (nonatomic, retain) UIViewController<SBHOccludable> *rightSidebarViewController;
@property (nonatomic,readonly) SBHRootSidebarController * contentViewController;
@property (nonatomic,retain) NSLayoutConstraint * contentWidthConstraint;
@end

@interface MTMaterialView : UIView
@end

@interface SBHLibrarySearchController : UIViewController
@end

@interface SBHLibraryViewController : UIViewController
@end

@interface SBNestingViewController : UIViewController
@end

@interface SBFolderController : SBNestingViewController
@end

@interface SBHLibraryPodFolderController : SBFolderController
@property (nonatomic,readonly) UIView * containerView;
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property (assign, nonatomic) NSUInteger numberOfLandscapeRows;
@property (assign, nonatomic) NSUInteger numberOfLandscapeColumns;
@property (assign, nonatomic) NSUInteger numberOfPortraitRows;
@property (assign, nonatomic) NSUInteger numberOfPortraitColumns;
@end

@interface SBIconListGridLayout : NSObject
@end

@interface SBFolderControllerConfiguration : NSObject
@property (assign, nonatomic) NSUInteger allowedOrientations;
@end

@interface SBRootFolderControllerConfiguration : SBFolderControllerConfiguration
@property NSUInteger folderPageManagementAllowedOrientations;
@property NSUInteger ignoresOverscrollOnLastPageOrientations;
@end

@interface SBIconListViewLayoutMetrics : NSObject
@property NSUInteger columnsUsedForLayout;
@end

typedef struct SBHIconGridSize {
	uint16_t columns;
	uint16_t rows;
} SBHIconGridSize;

%hook SBIconController
- (bool)isAppLibraryAllowed {
	return YES;
}
- (bool)isAppLibrarySupported {
	return YES;
}
- (void)iconManager:(SBHIconManager *)iconManager willUseRootFolderControllerConfiguration:(SBRootFolderControllerConfiguration *)configuration {
    %orig;
    configuration.folderPageManagementAllowedOrientations = 26;
    configuration.ignoresOverscrollOnLastPageOrientations = 26;
}
%end

%hook SBHIconManager
- (bool)rootFolder:(id)arg1 canAddIcon:(id)arg2 toIconList:(id)arg3 inFolder:(id)folder {
	bool origValue = %orig;
	if ( [folder isKindOfClass:%c( SBHLibraryCategoriesRootFolder )] ) {
		return YES;
	}
	return origValue;
}
%end

%hook SBHomeScreenOverlayViewController
- (CGFloat)presentationProgress {
	CGFloat origValue = %orig;
	[self rightSidebarViewController].view.alpha = origValue;
	return origValue;
}
- (SBHRootSidebarController *)contentViewController {
	SBHRootSidebarController *origValue = %orig;
	CGRect containerViewFrame = origValue.view.frame;
	origValue.view.frame = containerViewFrame;
	return origValue;
}
- (void)viewWillLayoutSubviews {
	%orig;
	if ( [[self contentViewController].avocadoViewController isKindOfClass:%c(SBHLibraryViewController)] ) {
		[[self contentWidthConstraint] setConstant:[UIScreen mainScreen].bounds.size.width];
	} else {
		[[self contentWidthConstraint] setConstant:393];
	}
}
%end

%hook SBHLibrarySearchController
- (void)viewDidAppear:(bool)arg1 {
	%orig;
	UIView *containerView = [self valueForKey:@"_containerView"];
	UIView *contentContainerView = [self valueForKey:@"_contentContainerView"];
	UIView *searchResultsContainerView = [self valueForKey:@"_searchResultsContainerView"];

	CGRect selfFrame = self.view.frame;
	containerView.frame = selfFrame;
	contentContainerView.frame = selfFrame;
	searchResultsContainerView.frame = selfFrame;
}
- (void)_layoutSearchViews {
	%orig;
	MTMaterialView *searchBackdropView = [self valueForKey:@"_searchBackdropView"];

	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	CGFloat height = [[UIScreen mainScreen] bounds].size.height;

	CGRect fullScreenFrame = CGRectMake(
		-100,
		-100,
		width + 200,
		height + 200
	);
	searchBackdropView.bounds = fullScreenFrame;
	searchBackdropView.frame = fullScreenFrame;
}
%end

%hook SBHLibraryPodFolderController
- (void)viewDidAppear:(bool)arg1 {
	%orig;
	UIView *containerView = [self containerView];
	CGRect containerFrame = containerView.frame;
	self.view.frame = containerFrame;
}
%end

%hook SBHLibraryPodFolderControllerConfiguration
- (void)setAllowedOrientations:(NSUInteger)orientation {
    %orig(26);
}
%end

%hook SBHDefaultIconListLayoutProvider
- (SBIconListGridLayout *)makeLayoutForIconLocation:(NSString *)iconLocation {
	SBIconListGridLayout *layout = %orig;
	if ([iconLocation isEqualToString:@"SBIconLocationAppLibrary"]) {
		SBIconListGridLayoutConfiguration *config = [layout valueForKey:@"_layoutConfiguration"];
		config.numberOfLandscapeColumns = 8;
	}
	return layout;
}
%end

//	%hook _SBHLibraryPodIconListView
//	- (CGRect)frame {
//		CGRect origValue = %orig;
//		CGRect newContainerFrame = origValue;
//		newContainerFrame.size.width = ?;
//		return newContainerFrame;
//	}
//	%end
%hook SBIconListView
- (NSMutableIndexSet *)visibleGridCellIndexesWithMetrics:(SBIconListViewLayoutMetrics *)metrics {
	if (metrics.columnsUsedForLayout == -1)
		metrics.columnsUsedForLayout = 4;
	return %orig;
}
%end

extern "C" bool _os_feature_enabled_impl(const char *domain, const char *feature);
%hookf(bool, _os_feature_enabled_impl, const char *domain, const char *feature) {
	if (strcmp(domain, "SpringBoard") == 0 && strcmp(feature, "Dewey") == 0) {
		return true;
	}
	return %orig;
}

%ctor {
	%init;
}
