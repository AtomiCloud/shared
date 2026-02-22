# Testing in C#/.NET

## Framework: xUnit + FluentAssertions

```xml
<PackageReference Include="xUnit" Version="2.*" />
<PackageReference Include="FluentAssertions" Version="6.*" />
<PackageReference Include="Moq" Version="4.*" />
```

## AAA Template

```csharp
using FluentAssertions;
using Xunit;

public class ServiceTests
{
    [Fact]
    public void ShouldDoSomething()
    {
        // Arrange
        var subject = new Service(mockDep.Object);
        var input = new { Value = 42 };
        var expected = new { Result = 84 };

        // Act
        var actual = subject.Method(input);

        // Assert
        actual.Should().Be(expected);
    }
}
```

## Assertions (FluentAssertions)

```csharp
// Equality
actual.Should().Be(expected);           // value equality
actual.Should().BeEquivalentTo(expected); // deep equality

// Boolean
result.Should().BeTrue();
result.Should().BeFalse();

// Null
value.Should().BeNull();
value.Should().NotBeNull();

// Contains
text.Should().Contain("substring");
collection.Should().Contain(item);

// Numerical
number.Should().BeGreaterThan(0);
number.Should().BeInRange(0, 100);

// Strings
text.Should().StartWith("prefix");
text.Should().EndWith("suffix");
```

## Spies (Manual or Moq)

```csharp
// Manual spy
public class SpyLogger : ILogger
{
    private readonly List<string> _logs = new();

    public void Log(string message) => _logs.Add(message);

    public IReadOnlyList<string> Logs => _logs;
}

// Use
var spy = new SpyLogger();
var service = new Service(spy);
service.DoSomething();
spy.Logs.Should().Contain("expected message");

// Moq
var mock = new Mock<ILogger>();
mock.Setup(x => x.Log(It.IsAny<string>()));
mock.Verify(x => x.Log("expected"), Times.Once);
```

## Parameterized Tests (Theory)

```csharp
public class StatusFormatterTests
{
    [Theory]
    [InlineData("pending", "Pending")]
    [InlineData("running", "Running")]
    [InlineData("completed", "Completed")]
    public void ShouldFormatStatus(string input, string expected)
    {
        // Arrange
        var subject = new StatusFormatter();

        // Act
        var actual = subject.Format(input);

        // Assert
        actual.Should().Be(expected);
    }
}
```

## Run Tests

```bash
dotnet test
```
