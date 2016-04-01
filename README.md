# MultiError
--
    import "github.com/rShetty/multierror"


## Usage

#### type MultiError

```go
type MultiError struct {
}
```

MultiError implements error interface. An instance of MultiError has zero or
more errors.

#### func (*MultiError) Error

```go
func (m *MultiError) Error() string
```
Error implements error interface.

#### func (*MultiError) HasError

```go
func (m *MultiError) HasError() *MultiError
```
HasError checks if MultiError has any error.

#### func (*MultiError) Push

```go
func (m *MultiError) Push(errString string)
```
Push adds an error to MultiError.

## License
-------
This tool is released under the MIT license. Please refer to LICENSE for more details.
