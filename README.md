# MutGMP

Mutable GMP bindings for Crystal with in-place operations for better performance in algorithms like spigot algorithms for computing pi digits.

## Overview

Crystal's standard library `BigInt`, `BigFloat`, and `BigRational` are immutable - each operation creates a new object. This is fine for most use cases, but for algorithms that perform many operations on the same values (like spigot algorithms), this creates unnecessary allocations and copies.

`MutGMP` provides mutable wrappers (`MpZ`, `MpF`, `MpQ`) that use GMP's in-place operations, mutating the receiver instead of creating new objects.

## Performance

Based on benchmarks:

* **Simple arithmetic operations**: 1.3-1.4x faster
* **Factorial computation (10000!)**: 3.5x faster
* **Floating point operations**: 6-8x faster

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  mut_gmp:
    github: your-username/mut_gmp
```

## Usage

### MpZ (Mutable BigInt)

```crystal
require "mut_gmp"

a = MutGMP::MpZ.new(42)
b = MutGMP::MpZ.new(10)

a.add!(b)  # a is now 52, mutated in-place
a.mul!(2)  # a is now 104

# Operations can be chained
c = MutGMP::MpZ.new(5)
c.add!(10).mul!(2).sub!(5)  # c is now 25
```

### MpF (Mutable BigFloat)

```crystal
a = MutGMP::MpF.new(3.14)
b = MutGMP::MpF.new(2.0)

a.add!(b)   # a is now 5.14
a.mul!(2)   # a is now 10.28

# Set precision (in bits)
MutGMP::MpF.default_precision = 512
high_precision = MutGMP::MpF.new(1.0, precision: 1024)
```

### MpQ (Mutable BigRational)

```crystal
a = MutGMP::MpQ.new(1, 3)  # 1/3
b = MutGMP::MpQ.new(1, 6)  # 1/6

a.add!(b)   # a is now 1/2
a.mul!(2)   # a is now 1
```

## Available Operations

All types support in-place mutations with `!` suffix:

- Arithmetic: `add!`, `sub!`, `mul!`, `div!`, `mod!`
- Unary: `neg!`, `abs!`
- Bitwise (MpZ): `and!`, `or!`, `xor!`, `complement!`, `shl!`, `shr!`
- Other: `set!`, `pow!`, `gcd!`, `lcm!`, `sqrt!`

## Interoperability

Convert to/from standard library types:

```crystal
# From standard library
big_int = BigInt.new("12345678901234567890")
mpz = big_int.to_mpz

# To standard library
mpz = MutGMP::MpZ.new(42)
big_int = mpz.to_big_i
```

## Example: Spigot Algorithm

```crystal
require "mut_gmp"

# More efficient than using BigInt
def spigot_like_algorithm
  a = MutGMP::MpZ.new(1)
  b = MutGMP::MpZ.new(1)

  1000.times do
    a.add!(b)
    b.mul!(2)
    # ... more operations
  end

  a.to_big_i
end
```

## License

MIT
