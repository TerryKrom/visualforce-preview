# VisualforcePreview LWC

`VisualforcePreview` is a Lightning Web Component that displays an interactive timeline of activities grouped by month, with support for viewing HTML or plain-text email content. It is designed to work inside Salesforce, including use within Lightning Pages or Visualforce via wrappers or extensions.

## Features

- Activity grouping by month with collapsible sections (accordion).
- Special "Upcoming & Overdue" section.
- Expandable email previews with details like sender, recipient, and message body (HTML or text).
- Interactive icons to expand/collapse emails and sections.
- Per-item action menu with `Edit` and `Delete` options.
- Global "Send Email" button displayed above the timeline sections.
- Confirmation modal for delete actions.

## Usage

### 1. Import the component

Include `VisualforcePreview` in a Lightning Page or embed it within a Visualforce page using `lightning:container` or Lightning Out.

```html
<c-visualforce-preview></c-visualforce-preview>