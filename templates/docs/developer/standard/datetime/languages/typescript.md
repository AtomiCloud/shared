# Date/Time in TypeScript/Bun

## Library: `@js-temporal/polyfill`

The Temporal API is the future of date/time in JavaScript. Use the polyfill until native support is widespread.

```bash
bun add @js-temporal/polyfill
```

```typescript
import { Temporal } from '@js-temporal/polyfill';
```

## Types

### Instant

A specific point in time (UTC).

```typescript
// Current time
const now = Temporal.Now.instant();

// From ISO string
const instant = Temporal.Instant.from('2024-03-15T14:30:00Z');

// From epoch milliseconds
const instant = Temporal.Instant.fromEpochMilliseconds(1710510600000);

// Convert to string
instant.toString(); // '2024-03-15T14:30:00Z'

// Add duration
const later = instant.add({ hours: 2 });

// Compare
instant.equals(otherInstant);
Temporal.Instant.compare(instant1, instant2); // -1, 0, or 1
```

### PlainDate

A calendar date without time or timezone.

```typescript
// Create
const date = Temporal.PlainDate.from('2024-03-15');
const date = new Temporal.PlainDate(2024, 3, 15);

// Components
date.year; // 2024
date.month; // 3
date.day; // 15
date.dayOfWeek; // 5 (Friday)

// Operations
const tomorrow = date.add({ days: 1 });
const lastMonth = date.subtract({ months: 1 });

// Difference
const other = Temporal.PlainDate.from('2024-04-20');
const diff = date.until(other); // Duration
```

### PlainTime

A time of day without date or timezone.

```typescript
// Create
const time = Temporal.PlainTime.from('14:30:00');
const time = new Temporal.PlainTime(14, 30, 0);

// Components
time.hour; // 14
time.minute; // 30
time.second; // 0

// Operations
const later = time.add({ hours: 2 });
const rounded = time.round({ smallestUnit: 'minute', roundingMode: 'floor' });
```

### PlainDateTime

Date + time without timezone.

```typescript
const dt = Temporal.PlainDateTime.from('2024-03-15T14:30:00');

// Access components
dt.year;
dt.hour;

// Combine date and time
const date = Temporal.PlainDate.from('2024-03-15');
const time = Temporal.PlainTime.from('14:30:00');
const combined = date.toPlainDateTime(time);
```

### ZonedDateTime

Date + time + timezone.

```typescript
// From current time in timezone
const now = Temporal.Now.zonedDateTimeISO('America/New_York');

// Convert timezone
const utc = now.withTimeZone('UTC');
const tokyo = now.withTimeZone('Asia/Tokyo');

// To instant (strip timezone)
const instant = now.toInstant();

// From instant with timezone
const instant = Temporal.Instant.from('2024-03-15T14:30:00Z');
const zoned = instant.toZonedDateTimeISO('America/New_York');
```

### Duration

An amount of time.

```typescript
// Create
const duration = Temporal.Duration.from({ hours: 2, minutes: 30 });
const duration = Temporal.Duration.from('PT2H30M');

// Components
duration.hours; // 2
duration.minutes; // 30

// Operations
const doubled = duration.add(duration);
const negated = duration.negated();

// Add to instant
const instant = Temporal.Now.instant();
const later = instant.add(duration);

// Difference between instants
const start = Temporal.Instant.from('2024-03-15T10:00:00Z');
const end = Temporal.Instant.from('2024-03-15T14:30:00Z');
const elapsed = start.until(end); // Duration
```

## Best Practices

### Use Temporal Over Date Object

```typescript
// WRONG - Native Date has broken behavior
const date = new Date(2024, 2, 15); // Month is 0-indexed!

// RIGHT - Temporal is explicit and correct
const date = new Temporal.PlainDate(2024, 3, 15);
```

### Store Instants, Display Zoned

```typescript
// Store as instant (UTC)
const createdAt = Temporal.Now.instant();
await saveToDatabase({ createdAt: createdAt.toString() });

// Display in user's timezone
const userTimezone = 'America/New_York';
const displayTime = createdAt.toZonedDateTimeISO(userTimezone);
console.log(displayTime.toString());
```

### Use PlainDate for Birthdays

```typescript
// Birthday doesn't have a time component
const birthday = Temporal.PlainDate.from('1990-03-15');

// Calculate age
const today = Temporal.Now.plainDateISO();
const age = birthday.until(today).years;
```

### Duration for Timeouts

```typescript
// Define timeout as duration
const timeout = Temporal.Duration.from({ seconds: 30 });

// Calculate deadline
const deadline = Temporal.Now.instant().add(timeout);
```

## JSON Serialization

```typescript
// Instant -> string
const instant = Temporal.Now.instant();
const json = JSON.stringify({ timestamp: instant.toString() });

// String -> Instant
const parsed = JSON.parse(json);
const instant = Temporal.Instant.from(parsed.timestamp);
```

## Formatting

```typescript
const instant = Temporal.Now.instant();
const tz = 'America/New_York';

// Using Intl.DateTimeFormat
const formatter = new Intl.DateTimeFormat('en-US', {
  timeZone: tz,
  dateStyle: 'full',
  timeStyle: 'long',
});
formatter.format(instant); // 'Friday, March 15, 2024 at 10:30:00 AM EDT'
```
