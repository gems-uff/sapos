# Feature spec conventions: dealing with asynchronous UI

Feature specs drive a real browser (Capybara + Selenium + Chrome) against an
AJAX-heavy UI (ActiveScaffold + jQuery). The base problem behind every flaky
test we have had is the same: **the test runs synchronously, the UI updates
asynchronously**. We handle it with four complementary mechanisms, each at a
different layer. Use the lowest-numbered mechanism that can express what you
need.

## 1. Waiting matchers — the default for assertions

Capybara matchers and finders (`have_css`, `have_content`, `have_select`,
`find`, …) retry until the condition holds or the wait time expires. Always
prefer asserting on the *specific expected outcome*:

```ruby
expect(page).to have_css("tr td.name-column", count: 4)
expect(page).to have_select("widget_record_city_", options: ["Selecione a cidade", "Niteroi", "Rio"])
find(:select, "record_date_2i").find(:option, text: "Mar").select_option  # waits for the option
```

Avoid non-waiting reads as assertions on AJAX-rendered content: `page.all`,
`first`, `.value`, `all(...).map(&:text)` evaluate the DOM at that instant and
do not retry. They are only safe right after `visit` (server-rendered page) or
after a waiting matcher / `click_*_and_wait` has already established the
state. When a test using them flakes, convert to a waiting matcher (see the
city widget and month/year helpers for examples).

## 2. `click_button_and_wait` / `click_link_and_wait` — the default for clicks

Use them instead of `click_button` / `click_link` whenever the click triggers
AJAX (almost every ActiveScaffold action). They wait for `jQuery.active == 0`
after the click; since ActiveScaffold fires the XHR synchronously in the click
handler and updates the DOM in the success handler, the DOM is up to date when
they return.

They do **not** cover rendering deferred with `setTimeout` or animations —
follow the click with a waiting matcher for the content you expect.

## 3. Widget helpers — encapsulated JS-event timing

Some widgets have races that neither layer above can see: handlers attached
after the test interacts, dropdowns that only open on `focus`, keystrokes
ignored while a dropdown is closed. The helpers in `spec/support` deal with
those internally — always drive widgets through them instead of clicking and
typing manually:

- `fill_record_select` / `search_record_select` / `expect_to_have_record_select`
- `expect_to_have_city_widget`
- `select_month_year` / `select_month_year_i` / `expect_to_have_month_year_widget_i`

`sleep` is a last resort: never in spec files, only inside helpers when there
is no observable condition to wait for, and always with a comment.

## 4. Driver-level retries — already in place, don't duplicate

Chrome/Selenium defects are handled once, in `spec/support`:

- Chrome 116+ CDP stale-node errors: retried by the `synchronize` patch in
  `wait_for_ajax_helpers.rb`.
- Clicks intercepted by a stray record-select dropdown: retried inside
  `record_select_helpers.rb`.

Do not add ad-hoc `rescue`/retry blocks in individual specs; if a new driver
issue shows up, handle it in a support file so every spec benefits.

## Migration policy

New code follows the rules above. Old code that still uses non-waiting
assertions keeps working under layer 2's protection — convert it
opportunistically when you touch it or when it flakes, not in a big bang.
