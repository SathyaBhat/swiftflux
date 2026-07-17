# Changelog

All notable changes to SwiftFlux will be documented here.

## [Unreleased]

### Added
- Filter entries by author via a person icon menu in the entry list toolbar
- Author name and icon displayed on each entry row
- "Mark all as read" now respects the active author filter (only marks visible entries)
- "Mark All as Read" context menu item also respects the active author filter
- Author filter auto-clears when switching feed/filter or when the selected author is no longer present in the current entry list

## [0.4.0] - 2026-06-03

### Added
- Article title is now a clickable link that opens the article in the default browser
- Sidebar categories are collapsible

## [0.3.0] - 2026-05-03

### Added
- App icon

### Changed
- Unread filter moved from a bottom toggle to an inline segmented picker in the entry list toolbar
- Read entries remain visible in the list until the user switches feeds/articles

### Fixed
- Feeds are now grouped by category in the sidebar

## [0.1.0] - Initial release

### Added
- Basic RSS/Atom feed reader using the Miniflux API
- Entry list with unread indicator and starred indicator
- Search across title, content, and feed name
