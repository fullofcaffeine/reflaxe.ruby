# Modern RubyHx And RailsHx Temporal APIs

RubyHx follows modern Ruby and Rails temporal ownership instead of treating
every date-and-time concept as Ruby's legacy `DateTime` class.

| Need | Canonical typed surface | Native result |
| --- | --- | --- |
| An instant or ordinary Ruby date-and-time value | `ruby.Time` | Ruby `Time` |
| Strict ISO 8601 or explicit-format parsing | `ruby.TimeParsing` | Ruby `Time` |
| A civil date without a time of day | `ruby.Date` | Ruby `Date` |
| The current Rails application time | `RailsTime.current()` | `ActiveSupport::TimeWithZone` |
| Construction or parsing in a named Rails zone | `RailsTime.findZoneRequired(...)` and `TimeZone` | `ActiveSupport::TimeWithZone` |
| Historical calendar-reform behavior or a legacy API that specifically returns `DateTime` | No canonical facade yet | Use a separate checked interop contract if a real dependency requires it |

Ruby's own documentation marks `DateTime` as deprecated and recommends
`Time`. `DateTime` still has specialized historical-calendar behavior, but it
does not track daylight-saving rules and is not the modern default for
application timestamps. See the official
[Ruby DateTime documentation](https://docs.ruby-lang.org/en/3.4/DateTime.html).

## Plain RubyHx

Core `ruby.Time` stays require-free and owns normal construction, components,
offsets, epoch conversion, formatting, and seconds arithmetic. Parsing lives in
a separate type so programs that do not parse strings do not load Ruby's
`time` default gem:

```haxe
import ruby.Date as RubyDate;
import ruby.Time as RubyTime;
import ruby.TimeParsing;

var scheduledAt = TimeParsing.parseIso8601("2026-07-17T12:30:00-06:00");
var billingDay = RubyDate.parseIso8601("2026-07-17");
var expiresAt = scheduledAt.addSeconds(3600);

ruby.Kernel.puts(expiresAt.strftime("%Y-%m-%d %H:%M:%S %z"));
ruby.Kernel.puts(billingDay.toIso8601());
```

`TimeParsing.parseIso8601(...)` maps directly to `Time.iso8601(...)`.
`TimeParsing.parseWithFormat(...)` maps directly to `Time.strptime(...)`.
Heuristic `Time.parse` is intentionally omitted because it guesses missing
components and format. Callers that control a non-ISO format should provide it
explicitly.

## RailsHx Application Time

Rails applications should use their configured application zone rather than
the host process zone. `RailsTime.current()` maps to `Time.current`, while
`RailsTime.zone()` maps to the zone configured by `config.time_zone`. The
explicit lookup form is useful when a service or user selects a known zone:

```haxe
import rails.active_support.RailsTime;

var now = RailsTime.current();
var mexicoCity = RailsTime.findZoneRequired("America/Mexico_City");
var meeting = mexicoCity.local(2026, 7, 17, 12, 30, 0);
var imported = mexicoCity.parseRfc3339("2026-07-17T18:30:00Z");

ruby.Kernel.puts(now.timeZone().name());
ruby.Kernel.puts(meeting.toIso8601());
ruby.Kernel.puts(imported.toUtc().strftime("%Y-%m-%d %H:%M:%S %z"));
```

`TimeZone.local`, `at`, `parseIso8601`, `parseRfc3339`, and `now` create
`TimeWithZone` values. Callers do not construct `TimeWithZone` directly; that
matches Rails' public guidance. `parseRfc3339` requires date, time, and offset
components. `parseIso8601` accepts Rails' documented ISO subset, including a
date-only value whose time fields default to zero. The permissive
`TimeZone#parse`, mutable `Time.zone=`, and block-scoped `Time.use_zone` are not
part of this bounded surface.

`RailsTime.current()` and `RailsTime.zone()` rely on the normal booted Rails
application invariant that `config.time_zone` initializes a default zone
(Rails defaults it to UTC). Code using ActiveSupport without a Rails
application can use `findZone(...)` or `findZoneRequired(...)` explicitly.

## A Rails `datetime` Column Is Not Ruby `DateTime`

`datetime` in a Rails migration or schema is a database column type. It does
not select Ruby's `DateTime` class. With Rails' default time-zone-aware Active
Record configuration, `datetime` and `time` attributes are stored in UTC and
converted to the current `Time.zone` when read. See
[ActiveRecord::Timestamp](https://api.rubyonrails.org/classes/ActiveRecord/Timestamp.html)
and the Rails [`config.time_zone` guide](https://guides.rubyonrails.org/configuring.html#config-time-zone).

This distinction is why RailsHx migration operations may legitimately be named
`DateTimeColumn` while application values use the modern `Time`/
`ActiveSupport::TimeWithZone` contracts.

## Load Ownership And Boundaries

- `ruby.Time` maps to core `Time` and adds no require.
- `ruby.TimeParsing` emits one deduplicated `require "time"`.
- `ruby.Date` emits one deduplicated `require "date"`.
- Rails temporal facades emit deduplicated `require "active_support"` and
  `require "active_support/time"`; the base require initializes configuration
  used by `TimeWithZone` conversions when ActiveSupport is loaded outside a
  fully booted Rails application.
- The facades contain no `Dynamic`, `Any`, `cast`, `untyped`, raw Ruby, or
  wrapper runtime.

The Ruby parsing contract was reviewed against `ruby/rbs` `v4.0.3`
`stdlib/time/0/time.rbs` and the supported Ruby `lib/time.rb` sources recorded
in the packaged
[`stdlib_coverage.json`](../lib/hxruby/stdlib_coverage.json). The Rails contract
was reviewed against `rails/rails` `v8.1.3`:

| Source | SHA-256 |
| --- | --- |
| `activesupport/lib/active_support/values/time_zone.rb` | `c20a9fb54a413919aa8944649d7424e6dbc1e4b5c95cd02a1b169682bfbb0285` |
| `activesupport/lib/active_support/time_with_zone.rb` | `d8f04f1e38e12dbe8025d4468a30ad19cb0af985d81e7a2936fa8b736b5d1e3d` |
| `activesupport/lib/active_support/core_ext/time/calculations.rb` | `58d12f04b697a08bd161e68c86cc4e3b670883c87ae821e31ac0895161704830` |
| `activesupport/lib/active_support/core_ext/time/zones.rb` | `729ae3dde55a298bc0ac32324c4007a6314e03155877ad51bb9747037c83a663` |

Focused evidence is owned by `npm run test:time-date-facade` and
`npm run test:active-support-facades`; the mandatory Rails component runtime
repeats the latter against the exact supported Rails version.
