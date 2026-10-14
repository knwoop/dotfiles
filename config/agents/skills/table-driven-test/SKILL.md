---
name: table-driven-test
description: Go table-driven test conventions. Use inline map in for loop and modifyFunc pattern for test data.
---

# Table-Driven Test Conventions

## Inline map in for loop

Do not define `tests` variable separately. Expand the map directly in the `for` statement.

```go
// Good: Inline map
for name, tt := range map[string]struct {
    input string
    want  int
}{
    "case1": {input: "foo", want: 1},
    "case2": {input: "bar", want: 2},
} {
    t.Run(name, func(t *testing.T) {
        // ...
    })
}

// Bad: Separate variable
tests := map[string]struct {
    input string
    want  int
}{
    "case1": {input: "foo", want: 1},
    "case2": {input: "bar", want: 2},
}
for name, tt := range tests {
    // ...
}
```

## modifyFunc pattern for test data

Use `modifyFunc` pattern to make test case differences explicit. Define helper functions that create default values and allow modifications.

```go
func TestSomething(t *testing.T) {
    newTestBonus := func(modifyFunc func(*Bonus)) *Bonus {
        bonus := &Bonus{
            ID:        "default-id",
            CustomerID: "default-customer",
            StartTime:  time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
        }
        if modifyFunc != nil {
            modifyFunc(bonus)
        }
        return bonus
    }

    newTestDays := func(modifyFunc func([]*Day)) []*Day {
        days := []*Day{
            {Number: 1, Status: StatusNotAchieved},
            {Number: 2, Status: StatusNotAchieved},
            {Number: 3, Status: StatusNotAchieved},
        }
        if modifyFunc != nil {
            modifyFunc(days)
        }
        return days
    }

    for name, tt := range map[string]struct {
        bonus   *Bonus
        want    []*Day
        wantErr bool
    }{
        "default_case": {
            bonus: newTestBonus(nil),
            want: newTestDays(func(days []*Day) {
                days[0].Status = StatusReceivable
            }),
        },
        "modified_bonus": {
            bonus: newTestBonus(func(b *Bonus) {
                b.ID = "custom-id"
            }),
            want: newTestDays(func(days []*Day) {
                days[0].Status = StatusReceived
                days[1].Status = StatusReceivable
            }),
        },
        "error_case": {
            bonus: newTestBonus(func(b *Bonus) {
                b.ID = "invalid"
            }),
            wantErr: true,
        },
    } {
        t.Run(name, func(t *testing.T) {
            // ...
        })
    }
}
```

## When NOT to use modifyFunc pattern

If the test data value is essential to the test's intention (e.g., specific timestamps for time-based tests), define it directly instead of using modifyFunc.

```go
// Good: Time is the essence of the test, define directly
for name, tt := range map[string]struct {
    receiveTime time.Time
    now         time.Time
    want        bool
}{
    "received_today_returns_true": {
        receiveTime: time.Date(2026, 1, 27, 8, 0, 0, 0, jst),
        now:         time.Date(2026, 1, 27, 10, 0, 0, 0, jst),
        want:        true,
    },
    "received_yesterday_returns_false": {
        receiveTime: time.Date(2026, 1, 26, 15, 0, 0, 0, jst),
        now:         time.Date(2026, 1, 27, 10, 0, 0, 0, jst),
        want:        false,
    },
} {
    // ...
}
```
