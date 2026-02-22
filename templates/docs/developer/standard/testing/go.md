# Testing in Go

## Framework: testing + testify

```go
go get github.com/stretchr/testify/assert
go get github.com/stretchr/testify/require
```

## AAA Template

```go
func TestService_Something(t *testing.T) {
    // Arrange
    subject := NewService(mockDep)
    input := Input{Value: 42}
    expected := Output{Result: 84}

    // Act
    actual := subject.Method(input)

    // Assert
    assert.Equal(t, expected, actual)
}
```

## Assertions (testify)

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// Equality
assert.Equal(t, expected, actual)
assert.ObjectsAreEqualValues(expected, actual) // deep equality

// Boolean
assert.True(t, result)
assert.False(t, result)

// Nil
assert.Nil(t, value)
assert.NotNil(t, value)

// Contains
assert.Contains(t, text, "substring")
assert.ElementsMatch(t, expected, actual)

// Error handling
assert.NoError(t, err)
require.NoError(t, err)  // fails test immediately

// Numbers
assert.Greater(t, actual, 0)
assert.InDelta(t, expected, actual, 0.001)
```

## Spies

```go
// Manual spy
type SpyLogger struct {
    logs []string
}

func (s *SpyLogger) Log(message string) {
    s.logs = append(s.logs, message)
}

// Use
spy := &SpyLogger{}
service := NewService(spy)
service.DoSomething()
assert.Equal(t, []string{"expected message"}, spy.logs)
```

## Parameterized Tests (Table-Driven)

```go
func TestStatusFormatter_Format(t *testing.T) {
    cases := []struct {
        name     string
        input    string
        expected string
    }{
        {"pending to Pending", "pending", "Pending"},
        {"running to Running", "running", "Running"},
        {"completed to Completed", "completed", "Completed"},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            // Arrange
            subject := NewStatusFormatter()

            // Act
            actual := subject.Format(tc.input)

            // Assert
            assert.Equal(t, tc.expected, actual)
        })
    }
}
```

## Run Tests

```bash
go test ./...
go test -v ./...
go test -run TestService_Something ./...
```
