# Widgets: content, overlays and navigation

All paths are under `lib/shared_ui/widgets/`. Import with relative paths. Everything is presentational (values + callbacks).

## cards/avatars.dart
- `String appInitials(String? name)` : initials rule (first + last word letter; one word: first two letters).
- `HueAvatar({required String name, HueAvatarKind kind = startup, double size = 58, double? fontSize})` : hue avatar; `HueAvatarKind { startup, investor, program }` (investor = circle, others rounded square). Sizes 58/50/44/36.
- `TileAvatar({required String initials, TileTone tone = moss, double size = 46, double? radius, double? fontSize, bool round = false, List<BoxShadow>? shadows})` : gradient tile; `TileTone { moss, gold }`. Profile header gold: size 60, radius 17, fontSize 20; team member moss 40/12/13; request rows round 38; My Startups gold 48/14/16.

## cards/pills.dart
- `AppPill({required String label, AppPillTone tone = moss, String? icon, double height = 28, double fontSize = 13, FontWeight weight})` : `AppPillTone { moss, gold, grey }`; `icon` is a filled AppIcons path.
- `TagChip(String label)` : card tag chip.
- `LiveDot({bool on = true})` : 7 px live dot with ring.

## cards/home_card.dart
- `HomeCard({required name, required tag, required city, required body, HueAvatarKind kind, VoidCallback? onTap, onShare, onBookmark, bool bookmarked = false, int? matchPercent, String? matchReason, int index = 0, bool animate = true})` : `onBookmark == null` hides bookmark (guests); `onShare == null && onBookmark == null` hides the action area. `index` staggers cardIn (40 ms x index); change a key on the list to replay.
- `RailCard({required name, required tag, required city, required body, required String joined, HueAvatarKind kind, VoidCallback? onTap})` : "New on Start.sa" card; pass inside `SnapRail`.
- `SnapRail({required List<Widget> children, double peek = 60, double gap = 12, EdgeInsets padding = fromLTRB(16,2,16,10), ScrollController? controller})` : snapping horizontal rail, full-bleed (place it outside the page's 16 px padding); gives each child width = rail - 60.

## cards/trending.dart
- `TrendingBox({required List<Widget> children, bool animate = true})` : white box with separators, cardIn 300 ms.
- `TrendingRow({required int rank, required String category, required String name, HueAvatarKind kind, VoidCallback? onTap})` : kicker "N · Trending in X" (rank 1 gold).
- `TrendingNote(String text)` : caption under the box.

## cards/profile_blocks.dart
- `ProfileCard({required String icon, required String title, required Widget child, ProfileIconTone tone = moss})` : `ProfileIconTone { moss, gold, red }`.
- `ProfileText(String text, {bool muted = false})` : 14.5/22 paragraph.
- `ProfileSection({required String title, required Widget child, String? actionLabel, VoidCallback? onAction, bool rise = true, Duration delay})` : e.g. actionLabel "+ Add".
- `InfoRow({required String label, required String value, String? icon, bool showDivider = false})`.
- `KeyValueGrid({required List<(String, String)> items})` : 2-col cream cells.
- `ListRow({required Widget leading, required String title, String? subtitle, VoidCallback? onTap, bool showDivider, Widget? trailing, bool showChevron})` and `ListRow.card(...)` (same params; startup-profile "Associated investors" style).
- `StatDelta(String text)` : "+18%" pill with trend icon.

## cards/charts.dart
- `RevenueBars({required List<double> values, required List<String> labels, required List<String> valueLabels})` : 3 bars, last gold.
- `MarketCircles({String? tam, String? sam, String? som})` : nested circles + legend.
- `AreaChart({required List<double> values, List<String> axisLabels = const [], double height = 80})` : animates between data sets (400 ms).
- `OwnershipBar({required List<OwnershipSegment> segments})`, `OwnershipSegment(double percent, Color color)` : keep the segment count constant (use 0 for hidden).

## lists/
- `SegmentedSwitch({required List<String> labels, required int selectedIndex, required ValueChanged<int> onChanged})`.
- `SectionHeader({required String title, VoidCallback? onSeeAll, String seeAllLabel = 'See all', Widget? trailing})` : use `trailing: RangeDropdown(...)` for Trending.
- `ResultsRow({required String title, required VoidCallback onClearAll, List<ResultChip> chips})`; `ResultChip({required label, required onRemove, quoted})`, `ResultChip.query(String text, {required onRemove})` (adds curly quotes).
- `EmptyState({required title, required message, String icon = AppIcons.search, String? actionLabel, VoidCallback? onAction})`, `EmptyState.noMatches({required onAction})`.
- `IllustratedEmptyCard({required Widget illustration, required title, required message, String? actionLabel, VoidCallback? onAction, String? actionIcon = AppIcons.plus, bool float = true})` : My Startups empty (white card, illustration wrapped in `Float`).
- `GuestJoinCard({required VoidCallback onSignUp})`.
- `PressSurface({required child, onTap, pressedColor, borderRadius, semanticLabel, selected})` : tap region with a pressed tint.

## overlays/
- `showAppOverlay<T>(context, {builder, dim, dimDuration, duration, entry, curve, label, dismissible})` / `AppOverlayRoute` : generic dim + panel route (`AppOverlayEntry { slideUp, slideLeft, fadeScale }`). Closes on back and outside tap; reduced motion = 200 ms fade.
- `showAppBottomSheet<T>(context, {required WidgetBuilder builder, String barrierLabel})` : builder returns an `AppSheetScaffold`.
- `AppSheetScaffold({required Widget child, String? title, bool tall = false, VoidCallback? onClose, Color color})` : handle, title row + close, 84 % max or tall (top 64). `Navigator.pop` to close.
- `showPickerSheet(context, {required title, required List<String> options, String? selected, String? otherText, String? searchHint, String noResultsText = 'No results found', String? otherNoun, String otherLabel = 'Other', int otherMax = 40, VoidCallback? onUndoOther, bool tall}) -> Future<PickerResult?>`; `PickerResult(String value, {String? otherText})`. City: `searchHint: 'Search cities', noResultsText: 'No cities found'`; stage: `otherNoun: 'stage'`.  `PickerSheet` is the widget.
- `showAdvancedSearchSheet(context, {required List<AdvancedSearchGroup> groups, required AdvancedSelection initial, required int Function(AdvancedSelection) countFor}) -> Future<AdvancedSelection?>` : returns the draft on "Show N results", null when closed. `AdvancedSearchGroup({required title, required options, bool single = false})`, `typedef AdvancedSelection = Map<String, Set<String>>`, `advancedSelectionCount(groups, selection)` (badge count, ignores single groups).
- `showAppDialog<T>(context, {required builder, bool dismissible = true, barrierLabel})`; `AppDialog({required child})` (card); `VerifyEmailDialog({required email, required onResend, required onClose, needLogin = false, inSignup = false})`.
- `showInfoSheet(context, {required title, required text})` / `InfoSheet`.
- `showConfirmSheet(context, {required title, required message, required confirmLabel, cancelLabel = 'Cancel', icon = AppIcons.trash}) -> Future<bool>` / `ConfirmSheet`.
- `AppToast.show(BuildContext, String)`, `AppToast.showGlobal(String)`, `AppToast.navigatorKey` (assign to `MaterialApp.navigatorKey`).
- `AppDropdown({required anchorBuilder(context, open), required menuBuilder(context, close), AppDropdownOrigin origin, double minMenuWidth, semanticLabel})`, `DropdownCaret({required open, color, size})`, `DropdownOption({required label, required selected, required onTap})`.
- `RangeDropdown({required List<String> options, required int selectedIndex, required ValueChanged<int> onSelected})` : Trending range pill.
- `MatchesForDropdown({required List<MatchesForOption> options, required int selectedIndex, required ValueChanged<int> onSelected, kicker = 'Matches for'})`; `MatchesForOption({required name, required subtitle})`.

## nav/
- `AppBottomNav({required int currentIndex, required ValueChanged<int> onSelect})` : 0 Support Channels, 1 Hub, 2 Explore. Adds bottom safe area.
- `openAppDrawer(context, {required name, required initials, required roleLine, required List<AppDrawerItem> items, required onViewProfile, required onLogOut, logOutLabel = 'Log out'})`; `AppDrawerItem({required label, required icon, required onTap, int? badge})` (icon = AppIcons.menuRocket / menuBookmark / menuSpark / menuBell / menuGear / menuWallet). Callbacks run after the drawer closes.
- `HomeSearchBar({required TextEditingController controller, required VoidCallback onFilterTap, onChanged, onSubmitted, int activeCount = 0, hint = 'Search', double overlap = 24})` : put right after the green header in a Column; it overlaps the header by `overlap` and the overlapped strip stays tappable.
