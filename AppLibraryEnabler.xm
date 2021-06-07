/* App Library Enabler - Enable App Library on iPadOS
 * Copyright (C) 2020 Tomasz Poliszuk
 *
 * App Library Enabler is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License.
 *
 * App Library Enabler is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with App Library Enabler. If not, see <https://www.gnu.org/licenses/>.
 */


@interface UIView (AppLibraryEnabler)
- (id)_viewControllerForAncestor;
@end

@interface SBIconView : UIView
@end

@interface SBHSearchBar : UIView
@property (assign,nonatomic) UIEdgeInsets searchTextFieldHorizontalEdgeInsets;
@end

@protocol SBHOccludable
@end

@interface SBHomeScreenOverlayViewController : UIViewController
@property (nonatomic, retain) UIViewController<SBHOccludable> *rightSidebarViewController;
@end

@interface MTMaterialView : UIView
@end

@interface SBHLibrarySearchController : UIViewController
@end

@interface SBNestingViewController : UIViewController
@end
@interface SBFolderController : SBNestingViewController
@end
@interface SBHLibraryPodFolderController : SBFolderController
@property (nonatomic,readonly) UIView * containerView;
@end

%hook SBIconController
- (bool)isAppLibraryAllowed {
	return YES;
}
- (bool)isAppLibrarySupported {
	return YES;
}
%end

%hook SBRootFolderView
- (bool)_shouldIgnoreOverscrollOnLastPageForCurrentOrientation {
	return YES;
}
- (bool)_shouldIgnoreOverscrollOnLastPageForOrientation:(NSInteger)orientation {
	return YES;
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
-(CGFloat)presentationProgress {
	CGFloat origValue = %orig;
	[[self rightSidebarViewController].view setAlpha:origValue];
	return origValue;
}
%end

%hook SBHLibrarySearchController
- (void)viewDidAppear:(bool)arg1 {
	%orig;
	SBHSearchBar *searchBar = [self valueForKey:@"_searchBar"];
	UIView *containerView = [self valueForKey:@"_containerView"];
	UIView *contentContainerView = [self valueForKey:@"_contentContainerView"];
	UIView *searchResultsContainerView = [self valueForKey:@"_searchResultsContainerView"];

	CGRect selfFrame = self.view.frame;
	[containerView setFrame:selfFrame];
	[contentContainerView setFrame:selfFrame];
	[searchResultsContainerView setFrame:selfFrame];

	UIEdgeInsets searchTextFieldHorizontalEdgeInsets = [searchBar searchTextFieldHorizontalEdgeInsets];

	searchTextFieldHorizontalEdgeInsets.left = 23;
	searchTextFieldHorizontalEdgeInsets.right = 23;

	[searchBar setSearchTextFieldHorizontalEdgeInsets:searchTextFieldHorizontalEdgeInsets];
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
	[searchBackdropView setBounds:fullScreenFrame];
	[searchBackdropView setFrame:fullScreenFrame];
}
%end

%hook SBHLibraryPodFolderController
- (void)viewDidAppear:(bool)arg1 {
	%orig;
	UIView *containerView = [self containerView];
	CGRect containerFrame = containerView.frame;
	[self.view setFrame:containerFrame];
}
%end

%hook _SBHLibraryPodIconListView
- (CGRect)frame {
	CGRect origValue = %orig;
	CGRect newContainerFrame = origValue;
	newContainerFrame.size.width = 393;
	return newContainerFrame;
}
- (CGRect)iconLayoutRect {
	CGRect origValue = %orig;
	CGRect newFrame = origValue;
	newFrame.size.width = 393;
	return newFrame;
}

- (CGSize)iconSpacing {
	CGSize origValue = %orig;
	CGSize newSize = origValue;
	newSize.width = 33;
	newSize.height = 37;
	return newSize;
}
- (CGSize)effectiveIconSpacing {
	CGSize origValue = %orig;
	CGSize newSize = origValue;
	newSize.width = 33;
	newSize.height = 37;
	return newSize;
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
