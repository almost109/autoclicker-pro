# AutoClicker Pro UI Review Report

Review date: 28 July 2026  
Scope: Current working tree after the latest branding, Network Time, and START-button layout changes.  
Method: Static source review, localization-key comparison, repository-wide branding search, and inspection of the current successful Xcode build configuration. No source code was modified.

## 1. UI Layout Review

### Summary

The START countdown is no longer constrained by a fixed button width. Its label uses a 21-point monospaced font, a single line, and an intrinsic horizontal size; `ThemedButtonStyle` now treats its `width` argument as a minimum. At the default 600-point window width, the 220-point START button, 120-point STOP button, spacing, padding, and shortcut hints fit without truncating the countdown.

The remaining layout risks are primarily caused by non-wrapping localized text, large sentence-style action rows, fixed-size modal/settings content, and aggressive compression in the Network Time footer.

### Findings

| Severity | File and lines | Description | Recommendation |
|---|---|---|---|
| Medium | `auto-clicker/Views/Main/MainView.swift:73-128`; `ActionStageLine.swift:17-24` | The three action rows are single horizontal compositions rendered at 32 points. They have no wrapping strategy and depend on a trailing `Spacer`. Range mode is especially wide because it adds two number fields, a separator, and a duration selector. Longer translations or larger accessibility text can compress or clip controls. | Use a responsive layout (`ViewThatFits`, a wrapping layout, or a vertical fallback) and give interactive controls explicit layout priority. |
| Medium | `auto-clicker/Views/Main/MainView.swift:132-152` | “Start mode” is forced to intrinsic width with `fixedSize`, while the segmented picker has a 280-point minimum and both segments have `lineLimit(1)`. This currently fits at 600 points, but German/Spanish and increased text size have little flexibility. | Prefer a vertical fallback at constrained widths, or lower the picker minimum while ensuring each segment receives adequate intrinsic width. |
| Low | `auto-clicker/Views/Main/MainView.swift:155-170` | The delay sentence is a 25-point single-row composition with no wrapping behavior. The localized pluralized phrase can become wider than the window. | Allow a multi-line/vertical fallback or reduce the sentence composition into separately aligned label and control regions. Do not reduce the font solely to fit. |
| Medium | `auto-clicker/Views/Main/MainView.swift:172-186` | “Target time” is fixed to its intrinsic width, the time field is capped at 200 points, and the row cannot wrap. The current placeholder/value fits, but localization and accessibility sizing may compress the field. | Use a vertical fallback for narrow layouts and add an explicit accessibility label to the field. |
| Pass | `auto-clicker/Views/Main/MainView.swift:197-229`; `ThemedButtonStyle.swift:38-47` | START has a 220-point minimum rather than a fixed width. The countdown is monospaced, single-line, and horizontally fixed to its intrinsic content size without `minimumScaleFactor`. No current constraint should truncate `00:45.000` or the maximum minute-form value. | Retain the adaptive minimum-width implementation. Add a layout regression preview/test using the longest countdown string and all supported locales. |
| Low | `auto-clicker/Views/Main/MainView.swift:197-229` | Leading and trailing `Spacer(minLength: 20)` center the two-button group as a unit, not the START button itself. Because START and STOP have different widths, the START control is visually left of the window center. | If visual centering of START is intended, use a grid or equal-width columns rather than symmetric outer spacers. |
| Medium | `auto-clicker/Views/Main/MainView.swift:241-258`; `StatBox.swift:17-26` | Stats are separated using three unconstrained spacers. Date values have no monospaced font, line limit, wrapping policy, or minimum width. At constrained width or larger text sizes, values can compress unpredictably. | Use a two-column grid with equal flexible columns, monospaced digits, and an intentional wrapping/truncation policy. |
| Medium | `auto-clicker/Views/Main/Components/NetworkTimeDashboard.swift:108-124` | The dashboard uses a four-column grid. Server and localized last-sync text compete for space with fixed-size labels. Long hostnames and localized dates can be scaled or clipped. | Use two label/value rows per logical column, or switch to a two-column/vertical layout when width is constrained. Give values a clear truncation policy and tooltip. |
| Medium | `auto-clicker/Views/Main/Components/NetworkTimeDashboard.swift:185-209` | The footer forces all descendants to one line and scales them as low as 70%. Three equal flexible regions can still truncate long status text, server names, or the “waiting” placeholder, especially in German. | Avoid applying `lineLimit` and scaling to the entire container. Permit the right-hand server region to truncate in the middle with a tooltip, and allow status text to keep its natural readable size. |
| Low | `auto-clicker/Views/Main/Components/NetworkTimeDashboard.swift:245-254` | Dashboard values scale to 80%. This protects the grid but can make already-small 12-point text harder to read. | Prefer adaptive column structure or selective truncation over shrinking all values. |
| Medium | `auto-clicker/Views/Main/Components/DynamicWidthTextField.swift:15-27` | Width begins from a measured zero-sized state and is continuously set to the exact measured text width. Empty placeholders, caret room, and text-field chrome can make the control too narrow; exact `frame(width:)` also prevents graceful compression/expansion. | Add a practical minimum width and small caret/chrome allowance. Prefer local size measurement over global coordinates. |
| Medium | `auto-clicker/Views/Main/Components/DynamicWidthTextField.swift:37-47` | Geometry changes dispatch an asynchronous state update during layout. This older measurement pattern can cause extra layout passes and visible width jitter while typing. | Replace with a modern `PreferenceKey`, `Layout`, or `sizeThatFits`-based measurement when deployment constraints allow. |
| Low | `auto-clicker/Views/Main/Components/ActionStageLine.swift:17-24` | The nested `HStack` plus trailing `Spacer` adds hierarchy without defining spacing, alignment, or compression priorities. | Collapse to one explicit `HStack(alignment:spacing:)` and document its intended responsive behavior. |
| Low | `auto-clicker/Views/Main/Components/StatBox.swift:18-26` | Default `VStack` spacing and centered alignment are implicit, and title/value styling is very small relative to the rest of the interface. | Specify spacing/alignment and use semantic fonts or scalable metrics. |
| Low | `auto-clicker/Views/Main/Components/DurationModal.swift:36`; `MouseMoveModal.swift:36`; `PressKeyListenerModal.swift:58` | Modal dimensions are fixed. They are acceptable for current short content but do not accommodate longer localization or accessibility sizes. | Use minimum/ideal sizes and allow content-driven expansion. |

## 2. Branding Audit

### User-visible result

No user-visible occurrence of “Othyn,” “with ❤️ by Othyn,” `main_window_repo_vanity`, “Auto Clicker,” or `macos-auto-clicker` remains in application UI/localization resources. Current About and Help links consistently point to `https://github.com/almost109/AutoClicker-Pro`.

### Remaining occurrences and classification

| Occurrence | Location | Classification | Disposition |
|---|---|---|---|
| `auto-clicker` in file-header comments | Line 3 of Swift source files throughout `auto-clicker/` | Source history (keep) | Safe to ignore; not compiled as visible text and explicitly protected by branding requirements. |
| “auto clicker” in explanatory code comments | `AutoClickSimulator.swift:266`; localization comments in settings views | Source history (keep) | Safe to ignore; developer-only comments. |
| `auto-clicker` source directory | Project group/path entries in `project.pbxproj:267,281,297,790,796,801,822,828,833`; `.swiftlint.yml:2`; workflow globs | Internal identifier | Safe to ignore. Renaming would be a repository migration, not a UI-branding change. |
| `auto-clicker pro` target/project name | `project.pbxproj:429-489,852,861`; shared scheme `BlueprintName` and project container references | Internal identifier | Safe to ignore. Built product metadata is “AutoClicker Pro.” |
| `auto-clicker` scheme/workspace names | `fastlane/Fastfile:64-65,85`; `CONTRIBUTING.md:38`; workspace paths | Internal identifier / Documentation | Keep until the underlying scheme/workspace is deliberately renamed. Some Fastlane paths should be validated because `auto-clicker.xcodeproj` does not match the current `auto-clicker pro.xcodeproj`. |
| `auto-clicker` URL type and scheme | `auto-clicker/Build Assets/Info.plist:27,30` | Internal identifier | Safe to ignore for visible branding; retain for deep-link backward compatibility unless a migration is planned. |
| `othyn/DateStrings` | `project.pbxproj:875`; both `Package.resolved` files at line 7 | External dependency provenance | Safe to ignore. Replacing it would point to a different package rather than rebrand the app. |
| Original branding and paths in archived Fastlane output | `ref/fastlane_build_example.log`, `ref/fastlane_init.log` | Source/build history (keep) | Safe to ignore; historical diagnostic logs are not shipped to users. |
| “auto clicker” in README description | `README.md:7` | Documentation | Generic product-category wording, not an old proper name. Safe to keep, though “auto-clicking utility” would avoid ambiguity. |
| Current GitHub clone/release/issue links | `README.md:85`; `CONTRIBUTING.md:52,56,63,147,151`; `Fastfile:106`; `HelpCommands.swift:11`; localized `about_url` | Documentation / User-visible current branding | Correct; no replacement needed. |
| `about_url` / `about_url_short` | Lines 8-9 of all three `Localizable.strings`; `AboutView.swift:55-56` | User-visible branding | Correct and consistently targets `almost109/AutoClicker-Pro`. |
| External implementation/documentation links | Swift comments, Fastlane documentation, Gemfile/Pluginfile, Apple plist DTD URLs | Documentation / dependency metadata | Safe to ignore. They are not branding links. |
| `main_window_repo_vanity` | No occurrence | User-visible branding | Successfully removed. |
| `Othyn` in application resources | No occurrence except case-insensitive dependency/history references above | User-visible branding | No action required. |

## 3. Localization Audit

### Key parity and correctness

No duplicate keys were found in any `Localizable.strings` file.

| Severity | Location | Issue | Recommendation |
|---|---|---|---|
| High | `AppDelegate.swift:52-62` | `menu_bar_item_hide_show_suffix` is referenced but absent from **all** locales. Users will see the raw key appended to Show/Hide menu commands. | Add the key to en-GB, de, and es-419, with the value “AutoClicker Pro” or restructure the menu title to use `Bundle.main.displayName`. |
| Medium | `de.lproj/Localizable.strings`; `es-419.lproj/Localizable.strings` | Six keys present in en-GB are missing: `main_window_stop_mousemove`, `main_window_stop_mousemove_end`, `main_window_stop_mousemove_pixel`, `mousemove_enabled`, `mousemove_disabled`, and `mousemove_modal_cancel_button`. The last three are actively used by `MouseMove`/`MouseMoveModal`, so German and Spanish can display raw English keys or fall back inconsistently. | Add translations for all six keys or remove genuinely dead keys after confirming feature usage. |
| Medium | `en-GB.lproj/Localizable.strings:38-39` | “Minutes(s)” and “Hours(s)” are grammatical errors. | Use “Minute(s)” and “Hour(s),” or preferably proper plural localization. |
| Low | `en-GB.lproj/Localizable.strings:96` | “dissapear” is misspelled. | Change to “disappear.” |
| Low | `en-GB.lproj/Localizable.strings:136` and other status strings | Three periods are used instead of a typographic ellipsis, while the rest of the UI mixes conventions. | Standardize UI ellipses to `…` in all locales where appropriate. |
| Medium | `MainView.swift:85,91` | “Min” and “Max” are hardcoded English placeholders. | Add localized keys or accessibility labels for minimum/maximum interval. |
| Low | `MainView.swift:187` | `HH:mm:ss` is a format token rather than prose, so VoiceOver needs a semantic explanation. | Keep the visual format token and provide localized label/help text describing 24-hour time including seconds. |
| Medium | `MenuBarView.swift:15-18` | “Button 1” is hardcoded English placeholder text in a view included in the project. | Remove the dead placeholder view or localize/implement it before use. |
| Low | `NetworkTimeDashboard.swift:74,111,199` | The em-dash placeholder is hardcoded. It is culturally neutral and acceptable visually, but it has no semantic accessibility value. | Supply an accessibility value such as localized “Not available.” |

### Apparently unused keys

Static reference scanning found these keys with no current source reference:

- `main_window_stop_mousemove`
- `main_window_stop_mousemove_end`
- `main_window_stop_mousemove_pixel`
- `min: %lld, max: %lld` (marked legacy)
- `settings_general_launch_on_login_title`
- `settings_notifications`

Some enum-provided localization keys may be resolved indirectly, so deletion should follow a runtime/feature check. `settings_notifications` appears unused because the Notifications settings tab is not currently added to `SettingsView`.

## 4. Button Review

### `ThemedButtonStyle`

| Area | Status | Review |
|---|---|---|
| Adaptive width | Pass | `frame(minWidth:minHeight:)` allows the label to expand beyond its configured baseline. |
| Minimum width | Pass | Callers can specify an appropriate minimum; START uses 220 points. |
| Text clipping | Pass for START | The countdown retains intrinsic width and no longer scales down. |
| Hover state | Pass with caveat | Hover color is implemented, but animation placement is overly broad. |
| Pressed state | Needs improvement | `configuration.isPressed` is not used, so START/STOP have no visual pressed feedback. |
| Disabled state | Needs validation | Disabled foreground/background colors are theme-derived and may have insufficient contrast. |
| Keyboard focus | Needs improvement | No focus-ring styling or explicit focused appearance is provided. |

Findings:

- **Medium — `ThemedButtonStyle.swift:36-51`:** `withAnimation` wraps view construction. Prefer value-driven `.animation(..., value: isHover)` and a distinct pressed transform/color. This is a recommended implementation-quality improvement and does not require architecture changes.
- **Medium — `ThemedButtonStyle.swift:44-47`:** hover state is visible, but pressed state is ignored. Add subtle pressed feedback while preserving semantics.
- **Medium — `ThemedButtonStyle.swift:40,46`:** custom disabled colors should be contrast-tested for every selectable theme.
- **Low — `ThemedButtonStyle.swift:23`:** `SuperAmazingButton` is unclear production naming. Rename to a concise private implementation name.

### Other custom styles

- **ModalButtonStyle (`ModalButtonStyle.swift:18-54`) — Medium:** supports hover and pressed colors only while hovered. Keyboard activation without pointer hover has little or no pressed feedback. It also does not read `isEnabled`.
- **UnderlinedButtonStyle (`UnderlinedButtonStyle.swift:16-22`) — Medium:** correctly reflects disabled opacity but ignores `configuration.isPressed`, hover, and keyboard focus.
- **UnderlinedTextFieldStyle (`UnderlinedTextFieldStyle.swift:16-21`) — Low:** uses the underscored `_body` API, which is less stable than public styling APIs.

## 5. Network Time UI Review

### Coverage

The dashboard presents all requested information:

- Synchronization status
- Current time source
- Active NTP server
- Clock offset
- Round-trip delay
- Last successful synchronization

The footer presents status, source, offset, RTT, and server. `NetworkTimeFooter` is declared in `NetworkTimeDashboard.swift:141-211`; there is no separate `NetworkTimeFooter.swift`.

### Findings

| Severity | Lines | Description | Recommendation |
|---|---|---|---|
| Medium | `NetworkTimeDashboard.swift:24-62` and `149-170` | Status presentation and `usesNetworkTime` logic are duplicated between dashboard and footer. Future status changes can diverge visually. | Extract a small shared presentation model/helper without changing networking architecture. |
| Medium | `NetworkTimeDashboard.swift:64-76` and `172-183` | Offset/RTT formatting and synchronization-state derivation are duplicated. | Centralize display formatting in private helpers or a UI presentation value. |
| Medium | `NetworkTimeDashboard.swift:108-124` | Four grid columns produce a dense information hierarchy and weak association between labels and values at narrow widths. | Use two balanced label/value groups or adaptive vertical rows. |
| Medium | `NetworkTimeDashboard.swift:185-209` | Footer typography is only 9-10 points and can scale to 7 points. This is difficult to read and conflicts with accessibility. | Keep a minimum readable size; truncate secondary server data selectively rather than scaling the entire footer. |
| Low | `NetworkTimeDashboard.swift:64-70` | Offset uses three decimal places while RTT uses one. This can be appropriate, but the precision hierarchy is undocumented. | Confirm the precision reflects meaningful SNTP accuracy; otherwise use consistent, user-relevant precision. |
| Low | `NetworkTimeDashboard.swift:82-102` | Color and symbols communicate status well, so status is not color-only. | Retain the symbols; add consolidated VoiceOver labels/values. |
| Low | `NetworkTimeDashboard.swift:72-77` | Static `DateFormatter` is appropriate and avoids repeated allocation. | No change needed. |

## 6. Window Review

| Severity | File and lines | Description | Recommendation |
|---|---|---|---|
| Medium | `AutoClickerApp.swift:17-27`; `WindowStateService.swift:13-15` | Main content is constrained to 600×590 minimum/ideal and 780×767 maximum. The maximum prevents users from enlarging the window beyond 1.3×, which limits accessibility and localization accommodation. | Remove or substantially relax the maximum dimensions unless there is a product requirement for a compact fixed-range window. |
| Medium | `AutoClickerApp.swift:27` | `.windowResizability(.contentSize)` combined with min/ideal/max frames makes resize behavior tightly coupled to the current view hierarchy. Added content can unexpectedly change allowed window sizing. | Validate all modes/locales at minimum and maximum sizes; consider explicit NSWindow content constraints if predictable sizing is required. |
| Medium | `MainView.swift:68-267` | The root is a non-scrollable vertical stack. At the minimum 590-point height, larger system text, longer translations, or additional vertical content can clip because there is no scroll fallback. | Wrap the main content in an appropriate scroll container or provide a compact layout at constrained heights. |
| Low | `ACWindow.swift:17-25` | The root ZStack is simple and fills the window correctly. | No change needed. |
| Medium | `AppDelegate.swift:25` | `NSApp.windows[0]` assumes at least one window and can crash if launch ordering changes. | Safely access `windows.first`; this is robustness rather than visual behavior. |
| Low | `SettingsView.swift:14-52`; `WindowStateService.swift:17` | Settings uses a fixed 600-point width and tab-specific magic-number heights. This can clip localized or accessibility-sized content. | Use content-driven minimum sizing or scrollable tab content. |
| Low | `AboutView.swift:67` | About uses minimum dimensions only, so it can expand with content. | No change needed. |

## 7. Accessibility Review

### Findings

| Severity | File and lines | Description | Recommendation |
|---|---|---|---|
| High | `MainView.swift:179-183` | Target-time text field has only a format placeholder and no semantic accessibility label, hint, or invalid-value announcement. | Add localized `accessibilityLabel`, format hint, and validation feedback. |
| High | `DynamicWidthNumberField.swift:13-32`; `DynamicWidthTextField.swift:17-29` | Number fields rely on nearby sentence fragments for meaning. VoiceOver may announce an unlabeled text field or an ambiguous placeholder, especially where placeholder is empty. | Provide explicit labels/values/hints per field (interval, minimum interval, maximum interval, press amount, repeat count, delay). |
| Medium | `MainView.swift:201-225` | START/STOP labels are understandable, but the START label becomes a raw countdown while waiting. Its purpose/state is not explicitly announced, and 25 Hz target countdown updates could overwhelm VoiceOver if treated as live changes. | Supply a stable accessibility label (“Start countdown”) and a controlled accessibility value; avoid announcing every 40 ms update. |
| Medium | `NetworkTimeDashboard.swift:137,209` | `.accessibilityElement(children: .contain)` preserves many small child elements rather than providing concise status/value semantics. Labels and values may be read separately without context. | Combine each metric into a labeled accessibility element and expose a concise dashboard/footer summary. |
| Medium | `NetworkTimeDashboard.swift:74,111,199` | “—” has no meaningful spoken value. | Use localized “Not available” for accessibility values. |
| Medium | `ThemedButtonStyle.swift`; `ModalButtonStyle.swift`; `UnderlinedButtonStyle.swift` | Custom controls lack explicit keyboard-focus visuals. Native button semantics remain, but focus visibility depends on system behavior through custom backgrounds. | Test full keyboard access and add a clear focused state where the custom styling suppresses system focus cues. |
| Medium | Theme-dependent text throughout main views | Foreground and background colors are composed from user-selectable theme variants without documented WCAG/APCA checks. Disabled text and footer text are the highest risk. | Measure contrast for every theme in normal, hover, and disabled states. |
| Low | `MenuBarService.swift:166-176` | Menu bar symbols have the accessibility description “AutoClicker Pro,” but dynamic state is conveyed visually by color and not in the description. | Update the accessibility description/value when countdown/running state changes. |
| Low | `PermissionsView.swift:14-16` | The System Settings URL is force-unwrapped; while stable, failure would crash rather than provide an accessible error. | Safely create/open the URL and expose failure feedback. |
| Pass | Global keyboard shortcuts | START and STOP retain global keyboard shortcuts and visible shortcut hints. | Retain and test with VoiceOver/full keyboard access. |

### Focus order

SwiftUI source order gives a generally logical sequence: action configuration, start mode, timing input, START/STOP, network dashboard, stats, footer. However, the sentence-style rows interleave static text and fields, which can be verbose and ambiguous under VoiceOver. No explicit focus management is present for switching between Delay and Target Time modes.

## 8. Code Quality Review

| Severity | Location | Finding | Recommendation |
|---|---|---|---|
| Medium | `MainView.swift:13-269` | The view combines state derivation, start/stop commands, shortcut registration, action-form layout, network dashboard, stats, and footer. | Extract focused private subviews while preserving the existing observable-object architecture. |
| Medium | `MainView.swift:58-66,268` | Global shortcut handlers are registered on every `onAppear`. Depending on library replacement semantics, repeated appearances may replace handlers or capture additional view instances. | Register once at app/service level or explicitly verify replacement behavior. |
| Medium | `NetworkTimeDashboard.swift:24-76,145-183` | Dashboard/footer duplicate status, time-source, and formatting logic. | Share a small presentation helper. |
| Low | `NetworkTimeDashboard.swift:141` | `NetworkTimeFooter` shares a file with the dashboard despite being a distinct reusable view and being referenced conceptually as its own component. | Moving it to `NetworkTimeFooter.swift` would improve discoverability; optional, not functionally necessary. |
| Medium | `DynamicWidthTextField.swift:15-47` | Old global-geometry measurement introduces asynchronous state mutation during layout. | Replace with a modern local measurement approach. |
| Medium | `MenuBarView.swift:10-24` | The view contains placeholder “Button 1” behavior and appears to be dead/demo code. | Confirm it is unreferenced, then remove it or implement the intended popover UI. |
| Low | Multiple UI files | Magic numbers are widespread: font sizes, widths, heights, padding, corner radii, and the 1.3 window multiplier. | Introduce a small private design-token namespace where values express purpose. |
| Low | `ActionStageLine.swift`, `StatBox.swift` | Commented-out preview blocks are dead code; existing previews do not cover current UI states/locales. | Replace with active previews for Delay, Target Time, long countdown, failed/synchronized SNTP, and supported locales. |
| Medium | `MainView.swift:215,225` | Default shortcuts are force-unwrapped. A future missing default shortcut would crash UI construction. | Use safe optional rendering for shortcut hints. |
| Medium | `MenuBarService.swift:177,183-198` | Multiple force unwraps remain in menu-bar code. | Use guarded access to images, status items, and popovers. |
| Low | `Bundle+AppInfo.swift:10-22` | All properties are declared `public` although they are used inside the app target. | Reduce access control to internal unless external-module use is intended. |

## 9. Release Readiness

| Category | Status | Notes |
|---|---|---|
| Main Window | Needs minor work | Functional at default size; sentence rows and a non-scrollable root remain fragile under long localization/accessibility sizing. |
| Buttons | Needs minor work | START width is adaptive; custom styles need pressed/focus feedback and theme contrast validation. |
| Countdown | Ready | Monospaced, intrinsic width, no font shrinking, and adequate default-window space. |
| Target Time | Needs minor work | UI is functional; field needs accessibility labeling and validation feedback. |
| Delay Mode | Ready | No UI regression found in this review. |
| Network Time | Needs minor work | Complete data coverage and good status symbols; grid/footer compression and duplicated presentation logic remain. |
| Footer | Needs minor work | Original branding is gone and runtime data is present, but text can become too small/truncated. |
| Branding | Ready | No user-visible original branding remains; only protected history/internal/dependency references remain. |
| Localization | Not ready | One missing key in every locale produces raw menu text; six locale parity gaps remain in German/Spanish. |
| Accessibility | Not ready | Core numeric/target-time fields lack explicit labels; focus, contrast, and rapidly changing countdown behavior need validation. |
| Window | Needs minor work | Default sizing fits; restrictive maximum and lack of scroll fallback reduce resilience. |
| Overall UI | Conditionally ready | Suitable for internal testing, but localization and accessibility issues should be addressed before a public release. |

## 10. Overall Score

| Area | Score |
|---|---:|
| UI | 7.5/10 |
| Code Quality | 7.0/10 |
| Maintainability | 7.0/10 |
| Branding | 9.5/10 |
| Localization | 6.0/10 |
| Accessibility | 5.0/10 |
| Release Readiness | 6.5/10 |

### Critical Issues

No crash-level or countdown-clipping blocker was found in the reviewed START-button layout.

The release-significant issues are:

1. `menu_bar_item_hide_show_suffix` is missing from every localization file and can be shown verbatim in the application menu.
2. German and Spanish omit active mouse-movement localization keys.
3. Core editable fields do not have sufficient explicit VoiceOver labels.

### Recommended Fixes

1. Add/fix all missing localization keys and correct English wording errors.
2. Add accessibility labels and hints to target time and all dynamic number fields.
3. Remove whole-footer font scaling; make footer/dashboard layouts adaptive.
4. Add pressed and keyboard-focus states to custom button styles.
5. Add responsive fallbacks for wide action rows and loosen the window maximum-size restriction.
6. Add preview or UI regression coverage for the longest countdown, every supported locale, minimum window size, and larger text settings.

### Nice-to-have Improvements

- Extract shared Network Time presentation/formatting helpers.
- Split `NetworkTimeFooter` into its own source file.
- Replace the older global geometry text-field measurement.
- Consolidate UI magic numbers into named layout constants.
- Remove dead placeholder and commented preview code after confirming it is unused.
- Use monospaced digits in stat timestamps.

### Ready for Commit?

**Yes, with caveats.** The current UI changes themselves are coherent, the START countdown fix is sound, and branding cleanup is complete. The known localization/accessibility findings should be tracked explicitly if they are not included in the same commit.

### Ready for Release?

**No.** Resolve the missing localization keys and provide baseline accessibility labels before a public release. After those changes, validate all supported locales at the 600×590 minimum window size and test VoiceOver/full keyboard access.
