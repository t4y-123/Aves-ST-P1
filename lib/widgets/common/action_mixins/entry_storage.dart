import 'dart:async';
import 'dart:io';

import 'package:aves/app_mode.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/entry/extensions/multipage.dart';
import 'package:aves/model/entry/extensions/props.dart';
import 'package:aves/model/fgw/share_copied_entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/path.dart';
import 'package:aves/model/filters/trash.dart';
import 'package:aves/model/highlight.dart';
import 'package:aves/model/metadata/date_modifier.dart';
import 'package:aves/model/multipage.dart';
import 'package:aves/model/settings/enums/presentation.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/services/common/image_op_events.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/services/media/enums.dart';
import 'package:aves/services/media/media_edit_service.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/theme/themes.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/collection/entry_set_action_delegate.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/action_mixins/permission_aware.dart';
import 'package:aves/widgets/common/action_mixins/size_aware.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/dialogs/pick_dialogs/album_pick_page.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:aves/widgets/viewer/controls/notifications.dart';
import 'package:aves_model/aves_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

mixin EntryStorageMixin on FeedbackMixin, PermissionAwareMixin, SizeAwareMixin {
  Future<void> doExport(BuildContext context, Set<AvesEntry> targetEntries, EntryConvertOptions options) async {
    final destinationAlbum = await pickAlbum(context: context, moveType: MoveType.export);
    if (destinationAlbum == null) return;
    if (!await checkStoragePermissionForAlbums(context, {destinationAlbum})) return;

    if (!await checkFreeSpaceForMove(context, targetEntries, destinationAlbum, MoveType.export)) return;

    final transientMultiPageInfo = <MultiPageInfo>{};
    final selection = <AvesEntry>{};
    await Future.forEach(targetEntries, (targetEntry) async {
      if (targetEntry.isMultiPage) {
        final multiPageInfo = await targetEntry.getMultiPageInfo();
        if (multiPageInfo != null) {
          transientMultiPageInfo.add(multiPageInfo);
          if (targetEntry.isMotionPhoto) {
            await multiPageInfo.extractMotionPhotoVideo();
          }
          if (multiPageInfo.pageCount > 1) {
            selection.addAll(multiPageInfo.exportEntries);
          }
        }
      } else {
        selection.add(targetEntry);
      }
    });

    final l10n = context.l10n;

    var nameConflictStrategy = NameConflictStrategy.rename;
    final destinationDirectory = Directory(destinationAlbum);
    final destinationExtension = MimeTypes.extensionFor(options.mimeType);
    final names = [
      ...selection.map((v) => '${v.filenameWithoutExtension}$destinationExtension'),
      // do not guard up front based on directory existence,
      // as conflicts could be within moved entries scattered across multiple albums
      if (await destinationDirectory.exists()) ...destinationDirectory.listSync().map((v) => pContext.basename(v.path)),
    ].map((v) => v.toLowerCase()).toList();
    // case insensitive comparison
    final uniqueNames = names.toSet();
    if (uniqueNames.length < names.length) {
      final value = await showDialog<NameConflictStrategy>(
        context: context,
        builder: (context) => AvesSingleSelectionDialog<NameConflictStrategy>(
          initialValue: nameConflictStrategy,
          options: Map.fromEntries(NameConflictStrategy.values.map((v) => MapEntry(v, v.getName(context)))),
          message: l10n.nameConflictDialogSingleSourceMessage,
          confirmationButtonLabel: l10n.continueButtonLabel,
        ),
        routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
      );
      if (value == null) return;
      nameConflictStrategy = value;
    }

    final selectionCount = selection.length;
    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    await showOpReport<ExportOpEvent>(
      context: context,
      opStream: mediaEditService.export(
        selection,
        options: options,
        destinationAlbum: destinationAlbum,
        nameConflictStrategy: nameConflictStrategy,
      ),
      itemCount: selectionCount,
      onDone: (processed) async {
        final successOps = processed.where((e) => e.success).toSet();
        final exportedOps = successOps.where((e) => !e.skipped).toSet();
        final newUris = exportedOps.map((v) => v.newFields['uri'] as String?).whereNotNull().toSet();
        final isMainMode = context.read<ValueNotifier<AppMode>>().value == AppMode.main;

        source.resumeMonitoring();
        unawaited(source.refreshUris(newUris));

        // get navigator beforehand because
        // local context may be deactivated when action is triggered after navigation
        final navigator = Navigator.maybeOf(context);
        final showAction = isMainMode && newUris.isNotEmpty
            ? SnackBarAction(
                label: l10n.showButtonLabel,
                onPressed: () {
                  if (navigator != null) {
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: CollectionPage.routeName),
                        builder: (context) => CollectionPage(
                          source: source,
                          filters: {
                            AlbumFilter(destinationAlbum, source.getAlbumDisplayName(context, destinationAlbum))
                          },
                          highlightTest: (entry) => newUris.contains(entry.uri),
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
              )
            : null;
        final successCount = successOps.length;
        if (successCount < selectionCount) {
          final count = selectionCount - successCount;
          showFeedback(
            context,
            FeedbackType.warn,
            l10n.collectionExportFailureFeedback(count),
            showAction,
          );
        } else {
          showFeedback(
            context,
            FeedbackType.info,
            l10n.genericSuccessFeedback,
            showAction,
          );
        }
      },
    );
    transientMultiPageInfo.forEach((v) => v.dispose());
  }

  Future<void> deleteExpiredShareCopied(BuildContext context) async {
    final source = context.read<CollectionSource>();
    await shareCopiedEntries.refresh();
    //await shareCopiedEntries.init();
    final todoEntries = source.allEntries
        .where((entry) => {PathFilter(androidFileUtils.avesShareByCopyPath)}.any((f) => f.test(entry)))
        .toSet();
    final expiredEntries = todoEntries.where(shareCopiedEntries.isExpiredCopied).toSet();
    if (expiredEntries.isEmpty) return;
    debugPrint('$runtimeType deleteExpiredShareCopied\n'
        'todoEntries $todoEntries \n'
        'expiredEntries $expiredEntries\n');
    final expiredContentIds = expiredEntries.map((e) => e.contentId ?? 0).toSet();

    final entriesByDestination = <String, Set<AvesEntry>>{};
    entriesByDestination[AndroidFileUtils.trashDirPath] = expiredEntries;

    //debugPrint('$runtimeType deleteExpiredShareCopied\n'
    //     'settings.enableBin ${settings.enableBin} \n'
    //     ' settings.shareByCopyExpiredRemoveUseBin ${settings.shareByCopyExpiredRemoveUseBin}\n');
    //source.pauseMonitoring();
    final useBin = settings.enableBin && settings.shareByCopyExpiredRemoveUseBin;
    //debugPrint('$runtimeType deleteExpiredShareCopied delete to useBin $useBin \n');
    // delete forever trashed items
    await EntrySetActionDelegate().doDelete(
      context: context,
      entries: expiredEntries,
      enableBin: useBin,
      isShareByCopyDelete: true,
    );
    await shareCopiedEntries.removeIds(expiredContentIds);
    // remove expired ids.
    final expiredCopiedIds = shareCopiedEntries.all.where(shareCopiedEntries.isExpiredRecord).toSet();
    if (expiredCopiedIds.isNotEmpty) {
      await shareCopiedEntries.removeEntryContentIds(expiredCopiedIds);
    }
    //await delegate.setDateToNow(context,entries:todoEntries,showConfirm: false);
    return;
  }

  Future<void> doQuickMove(
    BuildContext context, {
    required MoveType moveType,
    required Map<String, Iterable<AvesEntry>> entriesByDestination,
    bool hideShowAction = false,
    VoidCallback? onSuccess,
    bool isShareByCopyDelete = false,
  }) async {
    Set<AvesEntry> updatedEntries = {};
    final entries = entriesByDestination.values.expand((v) => v).toSet();
    final todoCount = entries.length;
    assert(todoCount > 0);

    final toBin = moveType == MoveType.toBin;
    final copy = moveType == MoveType.copy || moveType == MoveType.shareByCopy;

    // permission for modification at destinations
    final destinationAlbums = entriesByDestination.keys.toSet();
    if (!await checkStoragePermissionForAlbums(context, destinationAlbums)) return;

    // permission for modification at origins
    final originAlbums = entries.map((e) => e.directory).whereNotNull().toSet();
    if ({MoveType.move, MoveType.toBin}.contains(moveType) &&
        !await checkStoragePermissionForAlbums(context, originAlbums, entries: entries)) return;

    final hasEnoughSpaceByDestination = await Future.wait(destinationAlbums.map((destinationAlbum) {
      return checkFreeSpaceForMove(context, entries, destinationAlbum, moveType);
    }));
    if (hasEnoughSpaceByDestination.any((v) => !v)) return;

    final l10n = context.l10n;
    var nameConflictStrategy = NameConflictStrategy.rename;
    if (!toBin && destinationAlbums.length == 1) {
      final destinationDirectory = Directory(destinationAlbums.single);
      final names = [
        ...entries.map((v) => '${v.filenameWithoutExtension}${v.extension}'),
        // do not guard up front based on directory existence,
        // as conflicts could be within moved entries scattered across multiple albums
        if (await destinationDirectory.exists())
          ...destinationDirectory.listSync().map((v) => pContext.basename(v.path)),
      ].map((v) => v.toLowerCase()).toList();
      // case insensitive comparison
      final uniqueNames = names.toSet();
      //t4y: in share by copy, always rename the items.to avoid the show dialog break the operation.
      if (uniqueNames.length < names.length && moveType != MoveType.shareByCopy) {
        final value = await showDialog<NameConflictStrategy>(
          context: context,
          builder: (context) => AvesSingleSelectionDialog<NameConflictStrategy>(
            initialValue: nameConflictStrategy,
            options: Map.fromEntries(NameConflictStrategy.values.map((v) => MapEntry(v, v.getName(context)))),
            message: originAlbums.length == 1
                ? l10n.nameConflictDialogSingleSourceMessage
                : l10n.nameConflictDialogMultipleSourceMessage,
            confirmationButtonLabel: l10n.continueButtonLabel,
          ),
          routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
        );
        if (value == null) return;
        nameConflictStrategy = value;
      }
    }

    if ({MoveType.move, MoveType.copy}.contains(moveType) && !await _checkUndatedItems(context, entries)) return;

    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    final opId = mediaEditService.newOpId;
    await showOpReport<MoveOpEvent>(
      context: context,
      opStream: mediaEditService.move(
        opId: opId,
        entriesByDestination: entriesByDestination,
        copy: copy,
        nameConflictStrategy: nameConflictStrategy,
      ),
      itemCount: todoCount,
      onCancel: () => mediaEditService.cancelFileOp(opId),
      onDone: (processed) async {
        final successOps = processed.where((v) => v.success).toSet();

        // move
        final movedOps = successOps.where((v) => !v.skipped && !v.deleted).toSet();
        final movedEntries = movedOps
            .map((v) => v.uri)
            .map((uri) => entries.firstWhereOrNull((entry) => entry.uri == uri))
            .whereNotNull()
            .toSet();
        //debugPrint('$runtimeType doQuickMove movedEntries:\n $movedEntries');
        await source.updateAfterMove(
          todoEntries: entries,
          moveType: moveType,
          destinationAlbums: destinationAlbums,
          movedOps: movedOps,
          onUpdatedEntries: (entries) {
            updatedEntries.addAll(entries);
            // debugPrint('$runtimeType doQuickMove entries:\n $entries');
            // debugPrint('$runtimeType doQuickMove updatedEntries:\n $updatedEntries');
          },
        );

        // delete (when trying to move to bin obsolete entries)
        final deletedOps = successOps.where((v) => v.deleted).toSet();
        final deletedUris = deletedOps.map((event) => event.uri).toSet();
        await source.removeEntries(deletedUris, includeTrash: true);

        source.resumeMonitoring();

        // cleanup// t4y: should not delete the share by copy dir.
        if ({MoveType.move, MoveType.toBin}.contains(moveType) && !isShareByCopyDelete) {
          await storageService.deleteEmptyRegularDirectories(originAlbums);
        }

        final successCount = successOps.length;
        if (successCount < todoCount) {
          final count = todoCount - successCount;
          showFeedback(
            context,
            FeedbackType.warn,
            copy ? l10n.collectionCopyFailureFeedback(count) : l10n.collectionMoveFailureFeedback(count),
          );
        } else {
          final count = movedOps.length;
          final appMode = context.read<ValueNotifier<AppMode>?>()?.value;

          SnackBarAction? action;
          if (count > 0 && appMode == AppMode.main) {
            // get navigator beforehand because
            // local context may be deactivated when action is triggered after navigation
            final navigator = Navigator.maybeOf(context);
            if (toBin) {
              if (movedEntries.isNotEmpty) {
                // t4y: share by copy not need to restore.
                if (!isShareByCopyDelete) {
                  action = SnackBarAction(
                    label: Themes.asButtonLabel(l10n.entryActionRestore),
                    onPressed: () {
                      if (navigator != null) {
                        doMove(
                          navigator.context,
                          moveType: MoveType.fromBin,
                          entries: movedEntries,
                          hideShowAction: true,
                        );
                      }
                    },
                  );
                }
              }
            } else if (!hideShowAction) {
              action = SnackBarAction(
                label: l10n.showButtonLabel,
                onPressed: () {
                  if (navigator != null) {
                    _showMovedItems(navigator.context, destinationAlbums, movedOps);
                  }
                },
              );
            }
          }

          if (!toBin || (toBin && settings.confirmAfterMoveToBin)) {
            showFeedback(
              context,
              FeedbackType.info,
              copy ? l10n.collectionCopySuccessFeedback(count) : l10n.collectionMoveSuccessFeedback(count),
              action,
            );
          }

          EntryMovedNotification(moveType, movedEntries).dispatch(context);
          onSuccess?.call();
        }
      },
    );

    if (moveType == MoveType.shareByCopy && settings.shareByCopyExpiredAutoRemove) {
      // await deleteExpiredShareCopied(context);
      final source = context.read<CollectionSource>();
      final allCopiedEntries = source.allEntries
          .where(
              (entry) => {PathFilter(androidFileUtils.avesShareByCopyPath)}.any((f) => f.test(entry) && !entry.trashed))
          .where(shareCopiedEntries.isShareCopied)
          .toSet();
      final todoEntries = switch (settings.shareByCopySetDateType) {
        ShareByCopySetDateType.onlyThisTimeCopiedEntries =>
          updatedEntries.isNotEmpty ? updatedEntries : allCopiedEntries,
        ShareByCopySetDateType.allCopiedEntries => allCopiedEntries,
      };
      await EntrySetActionDelegate()
          .setDateToNow(context, entries: todoEntries, showConfirm: false, isShareByCopy: true);
    }
  }

  Future<void> doMove(
    BuildContext context, {
    required MoveType moveType,
    required Set<AvesEntry> entries,
    bool hideShowAction = false,
    VoidCallback? onSuccess,
    bool isShareByCopyDelete = false,
    bool shareByCopyNeedRemove = true,
  }) async {
    // debugPrint('$runtimeType doMove in viewerMode?[$isViewerMode]:${context.read<ValueNotifier<AppMode>>().value}');
    if (moveType == MoveType.toBin && !isShareByCopyDelete) {
      final l10n = context.l10n;
      if (!await showSkippableConfirmationDialog(
        context: context,
        type: ConfirmationDialog.moveToBin,
        message: l10n.binEntriesConfirmationDialogMessage(entries.length),
        confirmationButtonLabel: l10n.deleteButtonLabel,
      )) return;
    }
    // t4y delete the expired items first.
    // when share by copy in viewer mode, not need to delete pre.

    final entriesByDestination = <String, Set<AvesEntry>>{};
    switch (moveType) {
      case MoveType.copy:
      case MoveType.move:
      case MoveType.export:
        final destinationAlbum = await pickAlbum(context: context, moveType: moveType);
        if (destinationAlbum == null) return;

        settings.recentDestinationAlbums = settings.recentDestinationAlbums
          ..remove(destinationAlbum)
          ..insert(0, destinationAlbum);
        entriesByDestination[destinationAlbum] = entries;
      case MoveType.toBin:
        entriesByDestination[AndroidFileUtils.trashDirPath] = entries;
      case MoveType.fromBin:
        groupBy<AvesEntry, String?>(entries, (e) => e.directory).forEach((originAlbum, dirEntries) {
          if (originAlbum != null) {
            entriesByDestination[originAlbum] = dirEntries.toSet();
          }
        });
      case MoveType.shareByCopy:
        final l10n = context.l10n;
        final deleteTimeString = formatToLocalDuration(context, Duration(seconds: settings.shareByCopyRemoveInterval));
        String dirName = pContext.basename(androidFileUtils.avesShareByCopyPath);
        // debugPrint('$runtimeType deleteTimeStrings:$deleteTimeString dirName:$dirName');

        if (!await showSkippableConfirmationDialog(
          context: context,
          type: ConfirmationDialog.shareByCopy,
          message: l10n.shareByCopyDialogMessage(androidFileUtils.avesShareByCopyPath, dirName, deleteTimeString),
          confirmationButtonLabel: l10n.continueButtonLabel,
        )) return;
        entriesByDestination[androidFileUtils.avesShareByCopyPath] = entries;
    }

    if (moveType == MoveType.shareByCopy &&
        settings.shareByCopyRemoveSequence == ShareByCopyRemoveSequence.removeBeforeCopy &&
        shareByCopyNeedRemove) {
      await deleteExpiredShareCopied(context);
    }

    await doQuickMove(
      context,
      moveType: moveType,
      entriesByDestination: entriesByDestination,
      onSuccess: onSuccess,
      isShareByCopyDelete: isShareByCopyDelete,
    );

    if (moveType == MoveType.shareByCopy &&
        settings.shareByCopyRemoveSequence == ShareByCopyRemoveSequence.removeAfterCopy &&
        shareByCopyNeedRemove) {
      await deleteExpiredShareCopied(context);
    }
  }

  Future<void> rename(
    BuildContext context, {
    required Map<AvesEntry, String> entriesToNewName,
    required bool persist,
    VoidCallback? onSuccess,
  }) async {
    final entries = entriesToNewName.keys.toSet();
    final todoCount = entries.length;
    assert(todoCount > 0);

    if (!await checkStoragePermission(context, entries)) return;

    if (!await _checkUndatedItems(context, entries)) return;

    final source = context.read<CollectionSource>();
    source.pauseMonitoring();
    final opId = mediaEditService.newOpId;
    await showOpReport<MoveOpEvent>(
      context: context,
      opStream: mediaEditService.rename(
        opId: opId,
        entriesToNewName: entriesToNewName,
      ),
      itemCount: todoCount,
      onCancel: () => mediaEditService.cancelFileOp(opId),
      onDone: (processed) async {
        final successOps = processed.where((e) => e.success).toSet();
        final movedOps = successOps.where((e) => !e.skipped).toSet();
        await source.updateAfterRename(
          todoEntries: entries,
          movedOps: movedOps,
          persist: persist,
        );
        source.resumeMonitoring();

        final l10n = context.l10n;
        final successCount = successOps.length;
        if (successCount < todoCount) {
          final count = todoCount - successCount;
          showFeedback(context, FeedbackType.warn, l10n.collectionRenameFailureFeedback(count));
        } else {
          final count = movedOps.length;
          showFeedback(context, FeedbackType.info, l10n.collectionRenameSuccessFeedback(count));
          onSuccess?.call();
        }
      },
    );
  }

  Future<bool> _checkUndatedItems(BuildContext context, Set<AvesEntry> entries) async {
    final undatedItems = entries.where((entry) {
      if (!entry.isCatalogued) return false;
      final dateMillis = entry.catalogMetadata?.dateMillis;
      return dateMillis == null || dateMillis == 0;
    }).toSet();
    if (undatedItems.isNotEmpty) {
      final confirmationDialogDelegate = MoveUndatedConfirmationDialogDelegate();
      final confirmed = await showSkippableConfirmationDialog(
        context: context,
        type: ConfirmationDialog.moveUndatedItems,
        delegate: confirmationDialogDelegate,
        confirmationButtonLabel: context.l10n.continueButtonLabel,
      );
      confirmationDialogDelegate.dispose();
      if (!confirmed) return false;

      if (settings.setMetadataDateBeforeFileOp) {
        final entriesToDate = undatedItems.where((entry) => entry.canEditDate).toSet();
        if (entriesToDate.isNotEmpty) {
          await EntrySetActionDelegate().editDate(
            context,
            entries: entriesToDate,
            modifier: DateModifier.copyField(DateFieldSource.fileModifiedDate),
            showResult: false,
          );
        }
      }
    }
    return true;
  }

  Future<void> _showMovedItems(
    BuildContext context,
    Set<String> destinationAlbums,
    Set<MoveOpEvent> movedOps,
  ) async {
    final newUris = movedOps.map((v) => v.newFields['uri'] as String?).toSet();
    bool highlightTest(AvesEntry entry) => newUris.contains(entry.uri);

    final collection = context.read<CollectionLens?>();
    if (collection == null || collection.filters.any((f) => f is AlbumFilter || f is TrashFilter)) {
      final source = context.read<CollectionSource>();
      final targetFilters = collection?.filters.where((f) => f != TrashFilter.instance).toSet() ?? {};
      // we could simply add the filter to the current collection
      // but navigating makes the change less jarring
      if (destinationAlbums.length == 1) {
        final destinationAlbum = destinationAlbums.single;
        targetFilters.removeWhere((f) => f is AlbumFilter);
        targetFilters.add(AlbumFilter(destinationAlbum, source.getAlbumDisplayName(context, destinationAlbum)));
      }
      unawaited(Navigator.maybeOf(context)?.pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: CollectionPage.routeName),
          builder: (context) => CollectionPage(
            source: source,
            filters: targetFilters,
            highlightTest: highlightTest,
          ),
        ),
        (route) => false,
      ));
    } else {
      // track in current page, without navigation
      await Future.delayed(ADurations.highlightScrollInitDelay);
      final targetEntry = collection.sortedEntries.firstWhereOrNull(highlightTest);
      if (targetEntry != null) {
        context.read<HighlightInfo>().trackItem(targetEntry, highlightItem: targetEntry);
      }
    }
  }
}

class MoveUndatedConfirmationDialogDelegate extends ConfirmationDialogDelegate {
  final ValueNotifier<bool> _setMetadataDate = ValueNotifier(false);

  MoveUndatedConfirmationDialogDelegate() {
    _setMetadataDate.value = settings.setMetadataDateBeforeFileOp;
  }

  void dispose() {
    _setMetadataDate.dispose();
  }

  @override
  List<Widget> build(BuildContext context) => [
        Padding(
          padding: const EdgeInsets.all(16) + const EdgeInsets.only(top: 8),
          child: Text(context.l10n.moveUndatedConfirmationDialogMessage),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _setMetadataDate,
          builder: (context, flag, child) => SwitchListTile(
            value: flag,
            onChanged: (v) => _setMetadataDate.value = v,
            title: Text(context.l10n.moveUndatedConfirmationDialogSetDate),
          ),
        ),
      ];

  @override
  void apply() => settings.setMetadataDateBeforeFileOp = _setMetadataDate.value;
}
