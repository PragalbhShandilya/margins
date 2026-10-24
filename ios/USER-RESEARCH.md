# Public feedback → Margins additions

24 October 2026. Small qualitative review of publicly indexed reviews/discussions, not a representative survey. Promotional product descriptions were not counted as independent demand.

## Signals

- Migration and ownership: Quotemarks reviewers describe losing a discontinued quote app and value CSV migration. https://apps.apple.com/gb/app/quotemarks-quote-notebook/id1327090189?platform=iphone&see-all=reviews
- Explicit CSV request: Quotes reviews ask for CSV import from other apps and an obvious delete button. https://apps.apple.com/us/app/quotes-organize-and-recall/id6478060940
- Flexible attribution: QuoteMark review reports import requiring book title and author. Margins should continue accepting personal/unattributed quotes. https://apps.apple.com/us/app/quotemark-ai-scan-book-quotes/id6471570608
- Faster capture and portable formats: discussion mentions awkward capture flow and requests more export formats. https://www.reddit.com/r/macapps/comments/1o965ir/
- Personal quote widgets and sync also appear in discussion; they need separate extension/sync design and acceptance, not just a UI toggle. https://www.reddit.com/r/macapps/comments/1sfknjd/recommend_a_good_app_for_saving_and_organizing/

## Implemented in this pass

Native Settings gains CSV export, Markdown export and CSV import alongside JSON backup. CSV accepts text or quote headers and optional author/source/kind; handles commas, escaped quotes, multiline text, Unicode, CRLF and BOM headers. Missing attribution is accepted. Imports use existing merge and safe persistence, reject malformed columns/quoting/categories before mutation and leave reminders paused. Markdown provides a readable copy for notes apps. JSON remains the full backup including photos/settings; CSV/Markdown export quote content only.

## Remaining candidates

Tags/collections, a native share extension for capture, Home/Lock Screen widgets and optional private sync. These have not been implemented or claimed complete. Prioritize after the migration flows pass runtime acceptance.

## Verification

Regression added for CSV roundtrip, multiline/quoted Unicode content, optional attribution, duplicate merge, malformed rows, invalid kind/missing text header and Markdown line preservation. All 18 portable tests pass; unsigned iPhone build succeeds. Focused compiled CSV roundtrip/duplicate check also passes. Native file-picker/export acceptance pending. New migration formats provisionally 6/10.

CSV integrity follow-up, 24 October: reject invalid UTF-8 instead of silently replacing bytes, preserve original CRLF/CR inside quoted text, and accept a BOM before a quoted header. Regression tests pass; unsigned iPhone build succeeds. Native file-picker acceptance remains pending.
