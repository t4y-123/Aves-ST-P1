import 'package:aves/model/covers.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/metadata/address.dart';
import 'package:aves/model/metadata/catalog.dart';
import 'package:aves/model/metadata/trash.dart';
import 'package:aves/model/vaults/details.dart';
import 'package:aves/model/video_playback.dart';

import '../foreground_wallpaper/fgw_used_entry_record.dart';
import '../foreground_wallpaper/filtersSet.dart';
import '../foreground_wallpaper/privacy_guard_level.dart';
import '../foreground_wallpaper/share_copied_entry.dart';
import '../foreground_wallpaper/wallpaper_schedule.dart';
import '../scenario/scenario.dart';
import '../scenario/scenario_step.dart';

abstract class MetadataDb {
  int get nextId;

  Future<void> init();

  Future<int> dbFileSize();

  Future<void> reset();

  Future<void> removeIds(Set<int> ids, {Set<EntryDataType>? dataTypes});

  // entries

  Future<void> clearEntries();

  Future<Set<AvesEntry>> loadEntries({int? origin, String? directory});

  Future<Set<AvesEntry>> loadEntriesById(Set<int> ids);

  Future<void> saveEntries(Set<AvesEntry> entries);

  Future<void> updateEntry(int id, AvesEntry entry);

  Future<Set<AvesEntry>> searchLiveEntries(String query, {int? limit});

  // date taken

  Future<void> clearDates();

  Future<Map<int?, int?>> loadDates();

  // catalog metadata

  Future<void> clearCatalogMetadata();

  Future<Set<CatalogMetadata>> loadCatalogMetadata();

  Future<Set<CatalogMetadata>> loadCatalogMetadataById(Set<int> ids);

  Future<void> saveCatalogMetadata(Set<CatalogMetadata> metadataEntries);

  Future<void> updateCatalogMetadata(int id, CatalogMetadata? metadata);

  // address

  Future<void> clearAddresses();

  Future<Set<AddressDetails>> loadAddresses();

  Future<Set<AddressDetails>> loadAddressesById(Set<int> ids);

  Future<void> saveAddresses(Set<AddressDetails> addresses);

  Future<void> updateAddress(int id, AddressDetails? address);

  // vaults

  Future<void> clearVaults();

  Future<Set<VaultDetails>> loadAllVaults();

  Future<void> addVaults(Set<VaultDetails> rows);

  Future<void> updateVault(String oldName, VaultDetails row);

  Future<void> removeVaults(Set<VaultDetails> rows);

  // trash

  Future<void> clearTrashDetails();

  Future<Set<TrashDetails>> loadAllTrashDetails();

  Future<void> updateTrash(int id, TrashDetails? details);

  // favourites

  Future<void> clearFavourites();

  Future<Set<FavouriteRow>> loadAllFavourites();

  Future<void> addFavourites(Set<FavouriteRow> rows);

  Future<void> updateFavouriteId(int id, FavouriteRow row);

  Future<void> removeFavourites(Set<FavouriteRow> rows);

  // covers

  Future<void> clearCovers();

  Future<Set<CoverRow>> loadAllCovers();

  Future<void> addCovers(Set<CoverRow> rows);

  Future<void> updateCoverEntryId(int id, CoverRow row);

  Future<void> removeCovers(Set<CollectionFilter> filters);

  // video playback

  Future<void> clearVideoPlayback();

  Future<Set<VideoPlaybackRow>> loadAllVideoPlayback();

  Future<VideoPlaybackRow?> loadVideoPlayback(int? id);

  Future<void> addVideoPlayback(Set<VideoPlaybackRow> rows);

  Future<void> removeVideoPlayback(Set<int> ids);

  //
  // Privacy Guard Level,

  Future<void> clearPrivacyGuardLevel();

  Future<Set<PrivacyGuardLevelRow>> loadAllPrivacyGuardLevels();

  Future<void> addPrivacyGuardLevels(Set<PrivacyGuardLevelRow> rows);

  Future<void> updatePrivacyGuardLevelId(int id, PrivacyGuardLevelRow row);

  Future<void> removePrivacyGuardLevels(Set<PrivacyGuardLevelRow> rows);

  // Filter Set for wallpaper,

  Future<void> clearFilterSet();

  Future<Set<FiltersSetRow>> loadAllFilterSet();

  Future<void> addFilterSet(Set<FiltersSetRow> rows);

  Future<void> updateFilterSetId(int id, FiltersSetRow row);

  Future<void> removeFilterSet(Set<FiltersSetRow> rows);

  // wallpaperScheduleTable

  Future<void> clearWallpaperSchedules();

  Future<Set<WallpaperScheduleRow>> loadAllWallpaperSchedules();

  Future<void> addWallpaperSchedules(Set<WallpaperScheduleRow> rows);

  Future<void> updateWallpaperSchedules(int id, WallpaperScheduleRow row);

  Future<void> removeWallpaperSchedules(Set<WallpaperScheduleRow> rows);

  // wallpaperScheduleTable

  Future<void> clearFgwUsedEntryRecord();

  Future<Set<FgwUsedEntryRecordRow>> loadAllFgwUsedEntryRecord();

  Future<void> addFgwUsedEntryRecord(Set<FgwUsedEntryRecordRow> rows);

  Future<void> updateFgwUsedEntryRecord(int id, FgwUsedEntryRecordRow row);

  Future<void> removeFgwUsedEntryRecord(Set<FgwUsedEntryRecordRow> rows);

  //
  // share copied entries
  Future<void> clearShareCopiedEntries();

  Future<Set<ShareCopiedEntryRow>> loadAllShareCopiedEntries();

  Future<void> addShareCopiedEntries(Set<ShareCopiedEntryRow> rows);

  Future<void> updateShareCopiedEntries(int id, ShareCopiedEntryRow row);

  Future<void> removeShareCopiedEntries(Set<ShareCopiedEntryRow> rows);

  // Scenario

  Future<void> clearScenarios();

  Future<Set<ScenarioRow>> loadAllScenarios();

  Future<void> addScenarios(Set<ScenarioRow> rows);

  Future<void> updateScenarioById(int id, ScenarioRow row);

  Future<void> removeScenarios(Set<ScenarioRow> rows);

  // Scenario steps

  Future<void> clearScenarioSteps();

  Future<Set<ScenarioStepRow>> loadAllScenarioSteps();

  Future<void> addScenarioSteps(Set<ScenarioStepRow> rows);

  Future<void> updateScenarioStepById(int id, ScenarioStepRow row);

  Future<void> removeScenarioSteps(Set<ScenarioStepRow> rows);
}
