import 'package:aves/model/assign/enum/assign_item.dart';
import 'package:aves/model/fgw/enum/fgw_schedule_item.dart';
import 'package:aves/model/filters/recent.dart';
import 'package:aves/model/naming_pattern.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/widgets/explorer/explorer_page.dart';
import 'package:aves/widgets/filter_grids/albums_page.dart';
import 'package:aves/widgets/filter_grids/assign_page.dart';
import 'package:aves/widgets/filter_grids/countries_page.dart';
import 'package:aves/widgets/filter_grids/tags_page.dart';
import 'package:aves_model/aves_model.dart';

import '../scenario/enum/scenario_item.dart';
import 'enums/presentation.dart';

class SettingsDefaults {
  // app
  static const hasAcceptedTerms = false; // t4y temp set true accept for test

  static const canUseAnalysisService = false;
  static const isInstalledAppAccessAllowed = false;
  static const isErrorReportingAllowed = false;
  static const tileLayout = TileLayout.grid;
  static const entryRenamingPattern = '<${DateNamingProcessor.key}, yyyyMMdd-HHmmss> <${NameNamingProcessor.key}>';

  // display
  static const displayRefreshRateMode = DisplayRefreshRateMode.auto;
  // static const themeBrightness = AvesThemeBrightness.system;
  static const themeBrightness = AvesThemeBrightness.system;
  static const themeColorMode = AvesThemeColorMode.polychrome;
  static const enableDynamicColor = false;
  static const enableBlurEffect = true; // `enableBlurEffect` has a contextual default value
  static const maxBrightness = MaxBrightness.never;
  static const forceTvLayout = false;

  // navigation
  static const mustBackTwiceToExit = true;
  static const keepScreenOn = KeepScreenOn.always; // t4y temp for test
  //static const keepScreenOn = KeepScreenOn.viewerOnly;
  static const homePage = HomePageSetting.albums; // t4y prefer albums
  //static const homePage = HomePageSetting.collection;
  static const enableBottomNavigationBar = true;
  static const confirm = true;
  static const setMetadataDateBeforeFileOp = false;
  static final drawerTypeBookmarks = [
    null,
    RecentlyAddedFilter.instance,
  ];
  static const drawerPageBookmarks = [
    AlbumListPage.routeName,
    CountryListPage.routeName,
    TagListPage.routeName,
    ExplorerPage.routeName,
    AssignListPage.routeName,
  ];

  // collection
  static const collectionSectionFactor = EntryGroupFactor.month;
  static const collectionSortFactor = EntrySortFactor.date;
  static const collectionBrowsingQuickActions = [
    EntrySetAction.searchCollection,
  ];
  // t4y: for some app, the share way never get the original as-si pic.They will compress the pic.
  static const collectionSelectionQuickActions = [
    EntrySetAction.delete,
    EntrySetAction.shareByDateNow,
    EntrySetAction.shareByCopy,
  ];
  // t4y: collectionSelectionQuickActions pre value
  // static const collectionSelectionQuickActions = [
  //   EntrySetAction.share,
  //   EntrySetAction.delete,
  // ];
  static const showThumbnailFavourite = true;
  static const showThumbnailHdr = true;
  static const thumbnailLocationIcon = ThumbnailOverlayLocationIcon.none;
  static const thumbnailTagIcon = ThumbnailOverlayTagIcon.none;
  static const showThumbnailMotionPhoto = true;
  static const showThumbnailRating = true;
  static const showThumbnailRaw = true;
  static const showThumbnailVideoDuration = true;

  // filter grids
  static const albumGroupFactor = AlbumChipGroupFactor.importance;
  static const chipListSortFactor = ChipSortFactor.name;

  // viewer ,
  // t4y: personal prefer value
  static const viewerQuickActions = [
    EntryAction.shareByCopy,
    EntryAction.shareByDateNow,
    EntryAction.toggleFavourite,
    EntryAction.delete,
    EntryAction.rotateScreen,
  ];
  // t4y: pre value.
  // static const viewerQuickActions = [
  //   EntryAction.rotateScreen,
  //   EntryAction.toggleFavourite,
  //   EntryAction.share,
  //   EntryAction.delete,
  // ];

  static const showOverlayOnOpening = false; // t4y : I prefer not show on Opening
  //static const showOverlayOnOpening = true;
  static const showOverlayMinimap = false;
  static const overlayHistogramStyle = OverlayHistogramStyle.none;
  static const showOverlayInfo = true;
  static const showOverlayDescription = false;
  static const showOverlayRatingTags = false;
  static const showOverlayShootingDetails = false;
  static const showOverlayThumbnailPreview = true; // t4y : I prefer ThumbnailPreview
  //static const showOverlayThumbnailPreview = false;
  static const viewerGestureSideTapNext = false;
  static const viewerUseCutout = true;
  static const enableMotionPhotoAutoPlay = false;

  // info
  static const infoMapZoom = 12.0;
  static const coordinateFormat = CoordinateFormat.dms;
  static const unitSystem = UnitSystem.metric;

  // tag editor

  static const tagEditorCurrentFilterSectionExpanded = true;

  // converter

  static const convertMimeType = MimeTypes.jpeg;
  static const convertQuality = 95;
  static const convertWriteMetadata = true;

  // rendering
  static const imageBackground = EntryBackground.white;

  // search
  static const saveSearchHistory = true;

  // bin
  static const enableBin = true;

  // accessibility
  static const showPinchGestureAlternatives = false;
  static const accessibilityAnimations = AccessibilityAnimations.system;
  static const timeToTakeAction = AccessibilityTimeout.s3;

  // file picker
  static const filePickerShowHiddenFiles = false;

  // slideshow
  static const slideshowRepeat = false;
  static const slideshowShuffle = false;
  static const slideshowFillScreen = false;
  static const slideshowAnimatedZoomEffect = true;
  static const slideshowTransition = ViewerTransition.random;
  static const slideshowVideoPlayback = SlideshowVideoPlayback.playMuted;
  static const slideshowInterval = 5;

  // widget
  static const widgetOutline = false;
  static const widgetShape = WidgetShape.rrect;
  static const widgetOpenPage = WidgetOpenPage.viewer;
  static const widgetDisplayedItem = WidgetDisplayedItem.random;

  // platform settings
  static const isRotationLocked = false;
  static const areAnimationsRemoved = false;

  //t4y: foreground wallpaper
  static const int fgwNewUpdateInterval = 30;
  static const int fgwGuardLevel = 1;
  //for easily test, debug set to most recent,else, release change to random.
  static const fgwDisplayedItem = FgwDisplayedType.random;
  // for default schedule type : 3/4/6 for home and lock, o r3/3/3 for only home.Format: levelsCount/filtersCount/scheduleCount
  // set to type333 in release for some os,like miui,
  //  third part app will not be able to set the lock screen wallpaper for having strict limit.
  static const fgwScheduleSet = FgwScheduleSetType.type333;

  static const showFgwChipButton = false;

  //
  static const int maxFgwUsedEntryRecord = 10;
  static const int resetFgwGuardLevelDuration = 15; // seconds
  // diff type share.
  static const confirmSetDateToNow = true;
  static const confirmShareByCopy = true;
  static const shareByCopyExpiredAutoRemove = true;
  static const shareByCopyExpiredRemoveUseBin = true;
  // t4y: in collection page, default auto remove. in viewer page or view mode,
  // it is fine copied one by one to accumulate many to share.
  static const shareByCopyCollectionPageAutoRemove = true;
  static const shareByCopyViewerPageAutoRemove = false;
  static const shareByCopyAppModeViewAutoRemove = false;
  static const shareByCopyRemoveInterval = 10; // seconds
  static const shareByCopyObsoleteRecordRemoveInterval = 10; // seconds
  static const shareByCopySetDateType = ShareByCopySetDateType.onlyThisTimeCopiedEntries;
  static const shareByCopyRemoveSequence = ShareByCopyRemoveSequence.removeBeforeCopy;
  // t4y: Data is precious,
  // in some phone, it may always overwrite the original pic without ask while the user may want to keep the origin with a edited new.
  // so,always force to copy a new item before edit, then edit the copied item.
  static const confirmEditAsCopiedFirst = true;

  static const useScenarios = true;
  static const scenarioLockType = CommonLockType.pin;
  static const scenarioLock = false;
  static const guardLevelLockType = CommonLockType.pin;
  static const guardLevelLock = false;
  static const pinDefaultPass = '1234';
  static const widgetUpdateWhenOpen = false;

  static const useScenarioFeature = true;
  // t4y: to make the scenario change not affect the fore ground wallpaper.
  static const canScenarioAffectFgw = false;
  // filter grids
  static const scenarioGroupFactor = ScenarioChipGroupFactor.intersectBeforeUnion;
  static const scenarioChipListSortFactor = ChipSortFactor.name;

  // t4y: assign:
  static const assignSortFactor = ChipSortFactor.name;
  static const assignTemporaryFollowAction = AssignTemporaryFollowAction.activeExcludeAndLock;
  static const assignTemporaryExpiredInterval = 15;
  static const canAutoRemoveExpiredTempAssign = true; // seconds
  static const confirmRemoveScenario = true;
  static const confirmRemoveAssign = true;
  static const autoRemoveCorrespondScenarioAsTempAssignRemove = true;
  static const autoRemoveTempAssignAsCorrespondScenarioRemove = true;
}
