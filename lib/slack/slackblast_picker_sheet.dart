import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../model/f3_nation_fetcher.dart';
import '../model/formatted_workout.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/cupertino_sheet_fork.dart';
import '../ui/simple_alert.dart';
import '../utils/shared_app_prefs.dart';
import 'slackblast_picker_section.dart';
import 'slackblast_search_field.dart';

/// Opens the Region-to-AO-to-event picker for posting [workout] as a backblast.
Future<void> showSlackblastPicker(
  BuildContext context, {
  required Workout workout,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return showAdaptiveModalSheet<void>(
    context: navigator.context,
    child: _SlackblastPickerSheet(workout: workout),
  );
}

class _SlackblastPickerSheet extends ConsumerStatefulWidget {
  final Workout workout;

  const _SlackblastPickerSheet({required this.workout});

  @override
  ConsumerState<_SlackblastPickerSheet> createState() =>
      _SlackblastPickerSheetState();
}

class _SlackblastPickerSheetState
    extends ConsumerState<_SlackblastPickerSheet> {
  final _aoSectionKey = GlobalKey();
  final _dateSectionKey = GlobalKey();
  late final TextEditingController _regionSearchController;
  late final TextEditingController _aoSearchController;
  final _regionSearchFocusNode = FocusNode();
  final _aoSearchFocusNode = FocusNode();
  Timer? _regionSearchDebounce;
  Timer? _aoSearchDebounce;
  late Future<List<F3Region>> _regionsFuture;
  Future<List<F3Ao>>? _aosFuture;
  Future<List<F3EventInstanceSummary>>? _datesFuture;
  F3Region? _selectedRegion;
  F3Ao? _selectedAo;
  var _isPosting = false;

  F3NationFetcher get _fetcher => ref.read(f3NationFetcherProvider.notifier);

  @override
  /// Restores saved selections, loads Regions, and focuses the search.
  void initState() {
    super.initState();
    _regionSearchController = TextEditingController();
    _aoSearchController = TextEditingController();
    _regionsFuture = _loadRegionsAndRestoreSelection();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _regionSearchFocusNode.requestFocus(),
    );
  }

  @override
  /// Cancels pending work and releases the sheet's input resources.
  void dispose() {
    _regionSearchDebounce?.cancel();
    _aoSearchDebounce?.cancel();
    _regionSearchController.dispose();
    _aoSearchController.dispose();
    _regionSearchFocusNode.dispose();
    _aoSearchFocusNode.dispose();
    super.dispose();
  }

  /// Clears saved selections and debounces a Region search request.
  void _updateRegionSearch(String value) {
    _aoSearchDebounce?.cancel();
    _aoSearchController.clear();
    SharedAppPrefs.instance.lastSlackblastRegionId.value = null;
    SharedAppPrefs.instance.lastSlackblastAoId.value = null;
    setState(() {
      _selectedRegion = null;
      _selectedAo = null;
      _aosFuture = null;
      _datesFuture = null;
    });
    _regionSearchDebounce?.cancel();
    _regionSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _regionsFuture = _fetcher.listRegions(searchTerm: value.trim());
      });
    });
  }

  /// Clears the saved AO selection and debounces its search request.
  void _updateAoSearch(String value) {
    SharedAppPrefs.instance.lastSlackblastAoId.value = null;
    setState(() {
      _selectedAo = null;
      _datesFuture = null;
    });
    _aoSearchDebounce?.cancel();
    _aoSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _selectedRegion == null) return;
      setState(() {
        _aosFuture = _fetcher.listAos(
          regionId: _selectedRegion!.id,
          searchTerm: value.trim(),
        );
      });
    });
  }

  /// Selects [region], saves its ID, resets dependent choices, and loads AOs.
  void _selectRegion(F3Region region) {
    if (_selectedRegion == region) return;
    _regionSearchController.text = region.name;
    SharedAppPrefs.instance.lastSlackblastRegionId.value = region.id;
    _aoSearchDebounce?.cancel();
    _aoSearchController.clear();
    SharedAppPrefs.instance.lastSlackblastAoId.value = null;
    setState(() {
      _regionsFuture = _fetcher.listRegions(searchTerm: region.name);
      _selectedRegion = region;
      _selectedAo = null;
      _datesFuture = null;
      _aosFuture = _fetcher.listAos(regionId: region.id);
    });
    _scrollTo(_aoSectionKey);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _aoSearchFocusNode.requestFocus(),
    );
  }

  /// Selects [ao], saves its ID, filters the AO list, and loads event dates.
  void _selectAo(F3Ao ao) {
    if (_selectedAo == ao) return;
    _aoSearchController.text = ao.name;
    SharedAppPrefs.instance.lastSlackblastAoId.value = ao.id;
    setState(() {
      _aosFuture = _fetcher.listAos(
        regionId: _selectedRegion!.id,
        searchTerm: ao.name,
      );
      _selectedAo = ao;
      _datesFuture = _fetcher.listAvailableDates(aoOrgId: ao.id);
    });
    _scrollTo(_dateSectionKey);
  }

  /// Loads the saved Region directly, or lists all Regions if none is saved.
  Future<List<F3Region>> _loadRegionsAndRestoreSelection() async {
    final regionId = SharedAppPrefs.instance.lastSlackblastRegionId.value;
    if (regionId == null) return _fetcher.listRegions();

    final region = await _loadSavedRegion(regionId);
    if (region == null) return _fetcher.listRegions();

    if (mounted) {
      _regionSearchController.text = region.name;
      setState(() {
        _selectedRegion = region;
        _aosFuture = _loadAosAndRestoreSelection(region);
      });
      _scrollTo(_aoSectionKey);
    }
    return [region];
  }

  /// Loads the saved AO directly, or lists all AOs if none is saved.
  Future<List<F3Ao>> _loadAosAndRestoreSelection(F3Region region) async {
    final aoId = SharedAppPrefs.instance.lastSlackblastAoId.value;
    if (aoId == null) return _fetcher.listAos(regionId: region.id);

    final ao = await _loadSavedAo(aoId);
    if (ao == null) return _fetcher.listAos(regionId: region.id);

    if (mounted && _selectedRegion == region) {
      _aoSearchController.text = ao.name;
      setState(() {
        _selectedAo = ao;
        _datesFuture = _fetcher.listAvailableDates(aoOrgId: ao.id);
      });
      _scrollTo(_dateSectionKey);
    }
    return [ao];
  }

  /// Retrieves a saved Region and clears stale Region/AO selections on 404.
  Future<F3Region?> _loadSavedRegion(int regionId) async {
    try {
      return await _fetcher.fetchRegion(regionId: regionId);
    } on F3NationApiException catch (error) {
      if (error.statusCode == 404) {
        SharedAppPrefs.instance.lastSlackblastRegionId.value = null;
        SharedAppPrefs.instance.lastSlackblastAoId.value = null;
        return null;
      }
      rethrow;
    }
  }

  /// Retrieves a saved AO and clears its selection if the API returns 404.
  Future<F3Ao?> _loadSavedAo(int aoId) async {
    try {
      return await _fetcher.fetchAo(aoId: aoId);
    } on F3NationApiException catch (error) {
      if (error.statusCode == 404) {
        SharedAppPrefs.instance.lastSlackblastAoId.value = null;
        return null;
      }
      rethrow;
    }
  }

  /// Scrolls the newly revealed drill-down section into view.
  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = key.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0,
      );
    });
  }

  /// Posts the workout text to [event] and reports the result to the user.
  Future<void> _postBackblast(F3EventInstanceSummary event) async {
    if (_isPosting) return;
    setState(() => _isPosting = true);
    try {
      await _fetcher.updateBackblast(
        eventInstanceId: event.id,
        name: widget.workout.name,
        backblastRich: widget.workout.richTextForSlackPost,
      );
      if (!mounted) return;
      await showSimpleAlert(
        context,
        title: L10n.of(context)!.slackblastPostSuccessTitle,
        message: L10n.of(context)!.slackblastPostSuccessMessage,
      );
      if (mounted) Navigator.of(context).pop();
    } on F3NationApiException catch (error) {
      if (!mounted) return;
      await showSimpleAlert(
        context,
        title: L10n.of(context)!.slackblastPostErrorTitle,
        message: error.message,
      );
      if (mounted) setState(() => _isPosting = false);
    } on Object catch (_) {
      if (!mounted) return;
      await showSimpleAlert(
        context,
        title: L10n.of(context)!.slackblastPostErrorTitle,
        message: L10n.of(context)!.slackblastLoadErrorMessage,
      );
      if (mounted) setState(() => _isPosting = false);
    }
  }

  /// Formats an event's date, time, and name for its selectable list row.
  String _eventLabel(F3EventInstanceSummary event) {
    final date = DateFormat.yMMMd().format(event.startDate);
    final time = event.startTime;
    return time == null || time.isEmpty
        ? '$date - ${event.name}'
        : '$date, $time - ${event.name}';
  }

  /// Dims events before today while retaining full contrast for today's event.
  TextStyle? _eventTextStyle(
    BuildContext context,
    F3EventInstanceSummary event,
  ) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (!event.startDate.isBefore(today)) return null;
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return PlatformScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: BottomSheetScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  leading: PlatformIconButton(
                    padding: const EdgeInsets.only(right: 14),
                    icon: Icon(AdaptiveIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    l10n.postToBackblastText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.6),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SlackblastPickerSection<F3Region>(
                    title: l10n.slackblastRegionsTitle,
                    headerChild: SlackblastSearchField(
                      controller: _regionSearchController,
                      focusNode: _regionSearchFocusNode,
                      hintText: l10n.slackblastRegionSearchHint,
                      onChanged: _updateRegionSearch,
                    ),
                    future: _regionsFuture,
                    itemLabel: (region) => region.name,
                    selectedItem: _selectedRegion,
                    onSelect: _selectRegion,
                    emptyLabel: l10n.slackblastRegionsEmptyLabel,
                    errorLabel: l10n.slackblastLoadErrorMessage,
                    onRetry: () async {
                      setState(
                        () => _regionsFuture = _fetcher.listRegions(
                          searchTerm: _regionSearchController.text.trim(),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedRegion != null)
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _aoSectionKey,
                      child: SlackblastPickerSection<F3Ao>(
                        title: l10n.slackblastAosTitle,
                        headerChild: SlackblastSearchField(
                          controller: _aoSearchController,
                          focusNode: _aoSearchFocusNode,
                          hintText: l10n.slackblastAoSearchHint,
                          onChanged: _updateAoSearch,
                        ),
                        future: _aosFuture,
                        itemLabel: (ao) => ao.name,
                        selectedItem: _selectedAo,
                        onSelect: _selectAo,
                        emptyLabel: l10n.slackblastAosEmptyLabel,
                        errorLabel: l10n.slackblastLoadErrorMessage,
                        onRetry: () => setState(
                          () => _aosFuture = _fetcher.listAos(
                            regionId: _selectedRegion!.id,
                            searchTerm: _aoSearchController.text.trim(),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_selectedAo != null)
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _dateSectionKey,
                      child: SlackblastPickerSection<F3EventInstanceSummary>(
                        title: l10n.slackblastDatesTitle,
                        future: _datesFuture,
                        itemLabel: _eventLabel,
                        itemTextStyle: _eventTextStyle,
                        selectedItem: null,
                        onSelect: _postBackblast,
                        emptyLabel: l10n.slackblastDatesEmptyLabel,
                        errorLabel: l10n.slackblastLoadErrorMessage,
                        onRetry: () => setState(
                          () => _datesFuture = _fetcher.listAvailableDates(
                            aoOrgId: _selectedAo!.id,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            if (_isPosting)
              ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
