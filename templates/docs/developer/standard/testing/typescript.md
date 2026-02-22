# Testing in TypeScript/Bun

## Framework: Mocha + Should

```bash
bun add mocha should @types/mocha
```

## AAA Template

```typescript
import should from 'should';
import describe from 'mocha';

describe('Service', () => {
  it('should do something', () => {
    // Arrange
    const subject = new Service(mockDep);
    const input = { value: 42 };
    const expected = { result: 84 };

    // Act
    const actual = subject.method(input);

    // Assert
    actual.should.eql(expected);
  });
});
```

## Assertions (Should)

```typescript
// Equality
actual.should.equal(expected); // strict equality
actual.should.eql(expected); // deep equality

// Boolean
result.should.be.true();
result.should.be.false();

// Null/undefined
value.should.be.null();
should(value).be.undefined();

// Contains
text.should.containEql('substring');

// Negation
result.should.not.equal(expected);
```

## Spies

```typescript
// Collect calls
const logs: string[] = [];
const spyLogger: ILogger = {
  log: (msg: string) => logs.push(msg),
};

// Assert
logs.should.eql(['msg1', 'msg2']);

// Capture arguments
let captured: any = null;
const mockSender: ISender = {
  send: (payload: any) => {
    captured = payload;
  },
};

// Assert
captured.should.have.property('id', '123');

// Count calls
let count = 0;
const mockDep: IDep = {
  doThing: () => {
    count++;
  },
};

// Assert
count.should.equal(3);
```

## Parameterized Tests

```typescript
describe('StatusFormatter', () => {
  const cases = [
    { input: 'pending', expected: 'Pending' },
    { input: 'running', expected: 'Running' },
    { input: 'completed', expected: 'Completed' },
  ];

  cases.forEach((tc, i) => {
    it(`should format status (${i + 1})`, () => {
      const subject = new StatusFormatter();
      const actual = subject.format(tc.input);
      actual.should.equal(tc.expected);
    });
  });
});
```

## Run Tests

```bash
bun test
bun mocha src/**/*.test.ts
```
