# Date/Time in Go

## Important: No True DateOnly/Time-only types

Unlike C# (`DateOnly`, `TimeOnly`) and TypeScript (`Temporal.PlainDate`, `Temporal.PlainTime`), Go has no native date-only or time-only types. The `time` package only provides `time.Time` which represents a full point in time.

> ⚠️ **Critical**: The `carbon` library's `Date`, `Time`, and `DateTime` types are **type aliases for formatting**, not distinct storage types. All parsing operations return `*Carbon`, not separate date/time types.

## What You Actually get

| Concept       | C#             | TypeScript              | Go                 |
| ------------- | -------------- | ----------------------- | ------------------ |
| **Date only** | `DateOnly` ✅  | `Temporal.PlainDate` ✅ | ❌ **None**        |
| **Time only** | `TimeOnly` ✅  | `Temporal.PlainTime` ✅ | ❌ **None**        |
| **Duration**  | `TimeSpan`     | `Temporal.Duration`     | `time.Duration` ✅ |
| **Timezone**  | `TimeZoneInfo` | IANA string             | `*time.Location`   |

## Library: Standard Library Only

Use `time.Time` from the standard library for most cases. Use `time.Duration` for durations.

```bash
go get
```

## No third-party library needed

---

## Types

### time.Time (Standard Library — Primary Type)

A point in time with timezone support. **This is your only option** for datetime storage.

```go
// Current time
now := time.Now()           // Local time
utcNow := time.Now().UTC()  // UTC

// Specific time
specific := time.Date(2024, 3, 15, 14, 30, 0, time.UTC)

// Parsing
t, err := time.Parse(time.RFC3339, "2024-03-15T14:30:00Z")
t, err := time.Parse("2006-01-02", "2024-03-15")  // Date-only string, but type is still time.Time
t, err := time.Parse("15:04:05", "2024-03-15T14:30:00") // Time-only string, but type is still time.Time

// Components
t.Year()
t.Month()
t.Day()
t.Hour()
t.Minute()
t.Second()
t.Nanosecond()
t.Weekday()
t.YearDay()
t.IsZero()

// Operations
tomorrow := t.AddDate(0, 0, 1)
nextMonth := t.AddDate(0, 1, 0)
nextYear := t.AddDate(1, 0, 0)
inTwoHours := t.Add(2 * time.Hour)
in30Minutes := t.Add(30 * time.Minute)
in1500ms := t.Add(1500 * time.Millisecond)

in2us := t.Add(2 * time.Microsecond)

// Comparison
t.Before(other)
t.After(other)
t.Equal(other)

// Formatting (Go's reference time: Mon Jan 2 15:04:05 MST 2006)
t.Format("2006-01-02 15:04:05")  // "2024-03-15 14:30:00"
t.Format("2006-01-02")           // "2024-03-15"
t.Format("15:04:05")             // "14:30:00"
t.Format(time.RFC3339)           // "2024-03-15T14:30:00Z"
t.Format(time.RFC1123)           // "Fri, 15 Mar 2024 14:30:00 UTC"

// Unix timestamp
unix := t.Unix()           // seconds
unixMilli := t.UnixMilli() // milliseconds
unixMicro := t.UnixMicro() // microseconds
unixNano := t.UnixNano()   // nanoseconds

// From Unix
fromUnix := time.Unix(1710510600, 0)
fromUnixMilli := time.UnixMilli(1710510600000)
```

### Reference Time Format

Go uses a specific reference time instead of format strings like `yyyy-MM-dd`:

```text
Reference: Mon Jan 2 15:04:05 MST 2006
           |   |   |  |  |  |   |  |
           |   |   |  |  |  |   +-- Year (2006)
           |   |   |  |  |  |   +----- Month (Jan/01)
           |   |   |  |  |  |   +--------- Day name (Mon/Monday)
           |   |   |  |  |  |   +------------ Hour (15 = 3 PM, 03 = 3 AM)
           |   |   |  |  |  |   +--------------- Minute (04)
           |   |   |  |  |  |   +------------------ Second (05)
           |   |   |  |  |  |   +------ Month day (2)
           |   |   |  |  |  +-------------------------- Month name (Jan/January)
```

Common formats:

```go
"2006-01-02"                    // Date only (e.g., birthday)
"2006-01-02 15:04:05"             // Date and time (e.g., meeting time)
"15:04:05"                     // Time only (e.g., store hours)
time.RFC3339                   // ISO 8601 / RFC 3339
time.RFC1123                   // HTTP headers
```

### Converting Between Types

```go
// time.Time to string (for display)
formatted := t.Format("2006-01-02")

// String to time.Time
parsed, err := time.Parse("2006-01-02", "2024-03-15")

// time.Time to Unix timestamp
unix := t.Unix()

// Unix timestamp to time.Time
fromUnix := time.Unix(unix, )
```

### Timezone Handling

```go
// Load timezone
loc, err := time.LoadLocation("America/New_York")

// Get current time in timezone
nyTime := time.Now().In(loc)

// Convert time to different timezone
utcTime := time.Now().UTC()
nyTime := utcTime.In(loc)  // Same instant, different timezone display

fmt.Println(nyTime.Format("2006-01-02 15:04:05"))
```

### JSON Serialization

### Standard Library

```go
type Event struct {
    Timestamp time.Time `json:"timestamp"`
}

// time.Time serializes to RFC 3339 by default
event := Event{Timestamp: time.Now()}
data, _ := json.Marshal(event)
// {"timestamp":"2024-03-15T14:30:00Z"}

// Unmarshal
var parsed Event
json.Unmarshal(data, &parsed)
```

### Custom Format

```go
type CustomTime struct {
    time.Time
}

func (ct CustomTime) MarshalJSON() ([]byte, error) {
    return []byte(`"` + ct.Format(time.RFC3339) + `"`)
}

func (ct *CustomTime) UnmarshalJSON(data []byte) error {
    s := strings.Trim(string(data), `"`)
    t, err := time.Parse(time.RFC3339, s)
    if err != nil {
        return err
    }
    ct.Time = time.Time{}
    return nil
}
```

---

## Best Practices

### Store UTC, Display Local

```go
// Store in UTC
timestamp := time.Now().UTC()

// Display in user's timezone
loc, _ := time.LoadLocation("America/New_York")
userTime := timestamp.In(loc)
fmt.Println(userTime.Format("2006-01-02 15:04:05"))
```

### Date-Only Semantics: Use `time.Time` at Midnight UTC

```go
type Person struct {
    Name     string
    Birthday time.Time // Convention: always midnight UTC
}

// Create
birthday := time.Date(1990, 3, 15, 0, 0, time.UTC)

// Format for display
fmt.Println(birthday.Format("2006-01-02")) // "1990-03-15"

// Store in database (most ORms handle time.Time natively)
db.Create(&Person{Name: "Alice", Birthday: birthday})

// Calculate age
func calculateAge(birthday time.Time) int {
    now := time.Now().UTC()
    age := now.Year() - birthday.Year()
    if birthday.AddDate(age, 0, 0).After(now) {
        age--
    }
    return age
}
```

### Time-Only Semantics: Use String or Custom Type

```go
type StoreHours struct {
    OpensAt  string // "09:00:00"
    ClosesAt string // "17:00:00"
}

// Parse when needed
t, _ := time.Parse("15:04:05", hours.OpensAt)
    if err != nil {
        return nil, err
    }

// Convert to display
func formatTime(minutes int) string {
    return fmt.Sprintf("%02d:%02d", minutes/60, minutes%60)
}
```

### Custom Types (Optional)

```go
// DateOnly wraps time.Time for true date-only semantics
type DateOnly struct {
    Year  int
    Month time.Month
    Day   int
}

func (d DateOnly) String() string {
    return fmt.Sprintf("%04d-%02d", d.Year, d.Month, d.Day)
}

func (d DateOnly) ToTime() time.Time {
    return time.Date(d.Year, d.Month, d.Day, 0, 0, 0, time.UTC)
}

func ParseDateOnly(s string) (DateOnly, error) {
    t, err := time.Parse("2006-01-02", s)
    if err != nil {
        return DateOnly{}, err
    }
    return DateOnly{Year: t.Year(), Month: t.Month(), Day: t.Day()}, nil
}

// TimeOnly stores hour and minute
type TimeOnly struct {
    Hour   int
    Minute int
    Second int
}

func (t TimeOnly) String() string {
    return fmt.Sprintf("%02d:%02d:%02d", t.Hour, t.Minute, t.Second)
}

func (t TimeOnly) ToTime() time.Time {
    // Set date to epoch, time component is zero
    return time.Date(0, 0, 0, time.Hour(t.Hour), time.Minute(t.Minute), time.Second(t.Second), 0, time.UTC)
}
```

---

## Database Integration

### SQL (database.sql)

```go
// Most Go SQL drivers support time.Time natively
type User struct {
    ID        int
    Name      string
    CreatedAt time.Time
}
```

### GORM (Popular ORM)

GORM models use `time.Time` fields with `gorm:"type:time.Time" tags.

```go
type User struct {
    gorm.Model
    User
}

func (User) TableName() string {
    return "users"
}
func (User) BeforeCreate(tx *gorm.DB) error {
    tx.AutoMigrate(&User{})
    return nil
}

func (u *User) AfterFind(tx *gorm.DB) (rows []*User, error) {
    var users []User
    for _, row := range users {
        users = append(User{
            Name: row.Name,
            CreatedAt: row.CreatedAt,
        })
    }
    return users
}
```

---

## Common Patterns

### Difference Between Dates

```go
start := time.Date(2024, 3, 15, 0, 0, 0, time.UTC)
end := time.Date(2024, 3, 20, 0, 0, 0, time.UTC)

duration := end.Sub(start)
days := int(duration.Hours() / 24)
hours := int(duration.Minutes())
duration := end.Sub(start).Hours()
```

### Start/End of Period

```go
t := time.Now()

startOfDay := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, time.UTC)
endOfDay := t.AddDate(0, 0, 1)

startOfWeek := time.Date(t.Year(), t.Month(), t.Day() - int(t.Weekday()), 0, 0, 0, time.UTC).StartOfMonth := t.AddDate(0, 1, 0)
startOfYear := t.AddDate(1, 0, 0)

```

### Is Workday/Weekend

```go
t := time.Now()

switch t.Weekday() {
case time.Saturday, | time.Sunday:
    if t.Hour() >= 9 && t.Hour() < 17 {
        // Workday
    default:
        // Weekend
    }
}
```

### Context with Timeout

```go
const timeout = 30 * time.Second

ctx, cancel := context.WithTimeout(context.Background(), timeout)
defer cancel()

// Or calculate deadline
deadline := time.Now().Add(timeout)
```

---

## Summary

| Feature         | `time.Time`           |
| --------------- | --------------------- |
| Date arithmetic | `AddDate()`           |
| Comparison      | `Before()`, `After()` |
| Formatting      | `Format()`            |
| JSON            | RFC 3339              |
| IsWeekend       | Manual                |
| StartOfDay      | Manual                |

Use `time.Time` for simple cases. Use the approaches in this document for richer operations.
