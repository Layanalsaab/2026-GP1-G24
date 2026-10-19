# Structure and inputs widgets

Folders: `headers/`, `forms/`, `chips/` (import with relative paths). Logos are in `assets/images/logo_small.png` and `logo_full.png`.

## Overlap rule (important)
Headers that are overlapped by content (card, list, avatar, search bar) report a height smaller than they paint (`HeaderOverlap`). Put the next widget DIRECTLY after the header in a Column, with no negative margin. Defaults: `AuthHeader`/`StepHeader` 44 (for `AuthCard`), `RoleHeader` 48, `AuthHeader(overlap: OverlapList.overlap)` 48 for lists, `HomeHeader` 24 (`HomeHeader.searchOverlap`; the 46 px search bar goes right below, list starts 18 px under it), `ProfileBanner` 48 (avatar). `TabbedHeader` overlaps nothing. All headers add the status-bar inset on top.

## headers/
- `ArchBackground({height = 130, opacity = .22, inner = true})`, `.home()`, `.banner()`: inside a Stack.
- `ArchHeaderShell({child, padding, bottomRadius = 28, overlap = 0, arches, safeTop = true})`, `HeaderOverlap({overlap, child})`: building blocks.
- `HeaderLogo({size = 42, rightMargin = 6, animate = true})`.
- `AppIconButton({icon, onTap, semanticLabel, color, iconSize = 24, size = 44, stroke, child})`: plain 44 px icon button.
- `HeaderBackButton({onTap, semanticLabel = 'Back', color, close = false})`, `.profile({onTap})` (stroked chevron).
- `GlassIconButton({icon, onTap, semanticLabel, iconSize = 20, stroke, child, selected})`, `.share({onTap})`.
- `HeaderBookmarkButton({bookmarked, onTap, glass = true, color})`: never for guests.
- `GoldPillButton({label, onTap, icon, size})`, `.signUp({onTap})`, `.add({onTap, label = 'Add'})`.
- `ProfileEditPill({onTap, label = 'Edit profile'})`.
- `StepProgressBar({total, current})`; `HeaderTopRow({onBack, trailing, backLabel, close})`; `HeaderTitle(text, {style, margin})`.
- `AuthHeader({title, onBack, trailing, subtitle, overlap = 44})`: log in, forgot, My Startups (`trailing: GoldPillButton.add`, `subtitle: '2 startups'`), calculator.
- `StepHeader({step, total, title, onBack, edit = false, label, overlap = 44})`: null `onBack` shows the spacer. `StepHeader.labelFor(step, total, edit:)`.
- `RoleHeader({title, onBack, overlap = 48})`.
- `TabbedHeader({title, tabs, selectedIndex, onTabChanged, onBack, actions, avatar, pitch, subline, infoLine, metaLeft, metaRight, closeIcon})` with `HeaderTab(label, {badge})`, `HeaderAvatarTile({initials, size = 60, radius = 17, fontSize = 20})`, `HeaderTabBar`, `TabPaneSlide({index, child})` (pane slide-in, wrap the tab content).
- `HomeHeader({title, initials, guest, hasNotification, menuLabel, onAvatarTap, onSignUp, tabs, selectedTab, onTabChanged})`, `ExploreTab` (`ExploreTab.defaults`), `ExploreTabs`.
- `ProfileBanner({onBack, trailing, overlap = 48})`, `.edit({onBack, onEdit})`, `.glass({onBack, onShare, onBookmark, bookmarked, showBookmark})`.
- `AuthCard({child, animate = true})`, `OverlapList({children, gap = 12, animate = true})` (role: gap 14).

## forms/
- `FormPageScaffold({header, children, footer, controller})`: Scaffold with header + children in one scroll view, pinned footer.
- `FormFooter({primary, link})` (padding 12 24 24), `FooterLink({prefix, linkLabel, onTap, ..., padding})`, `.moss(...)`.
- `FieldLabel(label, {required, hasError, onInfoTap, infoOpen})`, `InfoButton`, `InfoButton.light`, `InfoTip(text)`.
- `AppField({child, label, required, info, infoOpen, onInfoToggle, subLabel, error, hint, counter, below, linkLabel, onLink})`: `infoOpen == null` = self managed; pass it (+ toggle) to keep one tip open at a time. `FieldHelperRow`, `FormFieldColumn({children, padding, gap = 20})`.
- `AppTextField({controller | value + onChanged, hint, keyboardType, inputFormatters, maxLength, multiline, rows = 4, prefix, prefixStyle, suffix, password, valid, hasError, enabled, focusNode, autofillHints, textCapitalization, dense, ...})`: the box only (border, ring, eye, ok check). Never owns a passed controller.
- `LabeledTextField({label, required, controller | value + onChanged, placeholder, maxLength, error, hint, valid, prefix, suffix, password, multiline, info..., linkLabel, onLink, below, counterFrom, ...})`: AppField + AppTextField with auto `n/max` counter. Default choice for text fields.
- `PasswordRules({password})`, `evaluatePasswordRules(password)`, `passwordRulesMet(password)`.
- `SelectField({placeholder, onTap, value, hasError, semanticLabel})`, `SelectField.otherText(other)`.
- `AppSwitch({value, onChanged, semanticLabel})`, `ToggleCard({icon, title, description, value, onChanged})`.
- `ThousandsFormatter({maxDigits = 13})` (`parse`, `format`), `MoneyField({controller | value + onChanged, prefix = 'SAR', hint = '0', maxDigits, hasError, dense})`, `TrioField({entries: [TrioEntry(label, controller | value, onChanged, hasError)], layout: TrioLayout.row | stack})` (Year 1/2/3, Minimum/Maximum as row; TAM/SAM/SOM as stack).
- `PhotoPickerPlaceholder({onTap, hasPhoto, initials, label, image})`, `LogoPickerRow({onTap, hasLogo, initials, image})`, `DashedBorderPainter` (dashed outline for the "Add team member" button).

## chips/
- `AppChip({label, selected, onTap})`; `AppFilterChip({label, selected, onTap})` (request/interest filters; named to avoid Material's FilterChip); `RemovableChip({label, onRemove})` (home results row); `RangeControl({labels, selectedIndex, onChanged})`.
- `ChipGroup({options, selected, onTap, otherLabel, otherController | otherValue + onOtherChanged, otherHint, otherError, otherMax = 40})`: single or multi (owner updates `selected`); shows the write-in when "Other" is selected and an Other handler is passed.
- `OtherWriteIn`, `ChipGroupField({label, options, selected, onTap, multi, required, error, info..., other...})`: label + "Select all that apply · N selected" + chips + error.
