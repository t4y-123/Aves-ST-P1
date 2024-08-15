enum ChipSetAction {
  // general
  configureView,
  select,
  selectAll,
  selectNone,
  lockScenario,
  unlockScenario,
  settingScenario,
  // browsing
  search,
  toggleTitleSearch,
  createAlbum,
  createVault,
  // browsing or selecting
  map,
  slideshow,
  stats,
  // selecting (single/multiple filters)
  delete,
  hide,
  pin,
  unpin,
  lockVault,
  showCountryStates,
  showCollection,
  // selecting (single filter)
  rename,
  setCover,
  configureVault,

  // t4y : wallpaper service
  foregroundWallpaperService,
}

class ChipSetActions {
  static const general = [
    ChipSetAction.configureView,
    ChipSetAction.select,
    ChipSetAction.selectAll,
    ChipSetAction.selectNone,
  ];

  // `null` items are converted to dividers
  static const browsing = [
    ChipSetAction.search,
    ChipSetAction.toggleTitleSearch,
    null,
    ChipSetAction.lockScenario,
    ChipSetAction.unlockScenario,
    ChipSetAction.settingScenario,
    null,
    ChipSetAction.map,
    ChipSetAction.slideshow,
    ChipSetAction.stats,
    // t4y : wallpaper service
    ChipSetAction.foregroundWallpaperService,
    // t4y end
    null,
    ChipSetAction.createAlbum,
    ChipSetAction.createVault,
  ];

  // `null` items are converted to dividers
  static const selection = [
    ChipSetAction.setCover,
    ChipSetAction.pin,
    ChipSetAction.unpin,
    ChipSetAction.delete,
    ChipSetAction.rename,
    ChipSetAction.showCountryStates,
    ChipSetAction.hide,
    null,
    ChipSetAction.showCollection,
    ChipSetAction.map,
    ChipSetAction.slideshow,
    ChipSetAction.stats,
    null,
    ChipSetAction.configureVault,
    ChipSetAction.lockVault,
  ];
}
