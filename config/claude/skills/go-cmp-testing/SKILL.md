---
name: go-cmp-testing
description: Go cmp testing conventions. Use AllowUnexported for structs with unexported fields, IgnoreFields only for auto-generated fields.
---

# go-cmp Testing Conventions

## Comparing structs with unexported fields

Use `cmp.AllowUnexported()` to compare structs that have unexported fields (like First-Class Collections).

```go
// Good: Use AllowUnexported for structs with unexported fields
if diff := cmp.Diff(want, got, cmp.AllowUnexported(MyCollection{})); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## Ignoring specific fields

Use `cmpopts.IgnoreFields()` only for fields that should be ignored (e.g., auto-generated IDs).

```go
// Good: Ignore only ID field, use AllowUnexported for unexported fields
if diff := cmp.Diff(want, got,
    cmpopts.IgnoreFields(MyStruct{}, "ID"),
    cmp.AllowUnexported(MyCollection{}),
); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## Do NOT use IgnoreFields for unexported field access

```go
// Bad: Don't use IgnoreFields just to avoid AllowUnexported
if diff := cmp.Diff(want, got, cmpopts.IgnoreFields(MyStruct{}, "ID", "MyCollection")); diff != "" {
    // This skips comparing the collection entirely
}
```

## Example with First-Class Collection

```go
func TestCreateSomething(t *testing.T) {
    want := &MyAggregate{
        Name:       "test",
        Collection: NewMyCollection([]*Item{}),
    }

    got := CreateMyAggregate("test")

    if diff := cmp.Diff(want, got,
        cmpopts.IgnoreFields(MyAggregate{}, "ID"),
        cmp.AllowUnexported(MyCollection{}),
    ); diff != "" {
        t.Errorf("mismatch (-want +got):\n%s", diff)
    }
}
```
