---
name: testing
description: Testing conventions for unit and integration tests. Use when writing tests, reviewing test code, or working with mocks/spies.
invocation:
  - test
  - testing
  - tests
---

# Testing Conventions

## Quick Reference

- **AAA Pattern**: Arrange (setup), Act (call method), Assert (verify)
- **Standard Variables**: `subject`, `input`, `expected`, `actual`
- **Parameterized Tests**: Use triangulation - test multiple values per behavior
- **Spies/Mocks**: For side effects - verify without real IO

## Core Principles

1. **Arrange-Act-Assert** - Three distinct sections with comments
2. **Standard Variable Names** - `subject`, `input`, `expected`, `actual`
3. **Triangulation** - Multiple test cases prove correctness
4. **Spies for Side Effects** - Collect calls, verify arguments, count calls
5. **Deterministic & Fast** - No random, no sleep, no real IO

## Language Support

| Language       | Framework         | Assertion Style                     | Parameterization            |
| -------------- | ----------------- | ----------------------------------- | --------------------------- |
| TypeScript/Bun | Mocha + Should    | `actual.should.eql(expected)`       | `forEach` with cases        |
| C#/.NET        | xUnit             | `actual.Should().Be(expected)`      | `[Theory]` + `[InlineData]` |
| Go             | testing + testify | `assert.Equal(t, expected, actual)` | Table-driven tests          |
| Rust           | built-in          | `assert_eq!(expected, actual)`      | Separate test functions     |

## Spy Patterns

| Pattern          | Use Case                    | Implementation                |
| ---------------- | --------------------------- | ----------------------------- |
| Collect calls    | Verify what was logged/sent | `calls.push(arg)` then assert |
| Capture argument | Verify payload structure    | `captured = arg` then assert  |
| Count calls      | Verify retry/loop behavior  | `count++` then assert         |
| Return value     | Stub dependency response    | `return mockValue`            |

## See Also

📖 **Full Documentation**: [testing/](../../../docs/developer/standard/testing/)

Related skills:

- [`/stateless-oop-di`](../stateless-oop-di/) - For testable code design
- [`/three-layer-architecture`](../three-layer-architecture/) - For testing pure domain logic
