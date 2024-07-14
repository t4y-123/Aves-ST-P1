enum AppMode {
  main,
  pickCollectionFiltersExternal,
  pickSingleMediaExternal,
  pickMultipleMediaExternal,
  pickFilteredMediaInternal,
  pickUnfilteredMediaInternal,
  pickFilterInternal,
  screenSaver,
  setWallpaper,
  slideshow,
  view,
  edit,
  fgwViewUsed,
  fgwViewOpen,
  fgwShareCopy,
}

extension ExtraAppMode on AppMode {
  bool get canNavigate => {
        AppMode.main,
        AppMode.pickCollectionFiltersExternal,
        AppMode.pickSingleMediaExternal,
        AppMode.pickMultipleMediaExternal,
        AppMode.fgwShareCopy,
      }.contains(this);

  bool get canEditEntry => {
        AppMode.main,
        AppMode.view,
        AppMode.fgwViewUsed,
        AppMode.fgwViewOpen,
        AppMode.fgwShareCopy,
      }.contains(this);

  bool get canSelectMedia => {
        AppMode.main,
        AppMode.pickMultipleMediaExternal,
        AppMode.fgwShareCopy
      }.contains(this);

  bool get canSelectFilter => this == AppMode.main;

  bool get canCreateFilter => {
        AppMode.main,
        AppMode.pickFilterInternal,
        AppMode.fgwShareCopy,
      }.contains(this);

  bool get isPickingMedia => {
        AppMode.pickSingleMediaExternal,
        AppMode.pickMultipleMediaExternal,
        AppMode.pickFilteredMediaInternal,
        AppMode.pickUnfilteredMediaInternal,
      }.contains(this);
}
