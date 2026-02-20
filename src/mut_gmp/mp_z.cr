require "big"

# A mutable wrapper around GMP's MPZ (arbitrary precision integer).
#
# Unlike `BigInt`, operations on `MutGMP::MpZ` mutate the receiver in-place,
# which is more efficient for algorithms that perform many operations on the
# same value (like spigot algorithms for computing pi digits).
#
# ```
# require "mut_gmp"
#
# a = MutGMP::MpZ.new(42)
# b = MutGMP::MpZ.new(10)
#
# a.add!(b) # a is now 52, mutated in-place
# a.mul!(2) # a is now 104
# ```
struct MutGMP::MpZ
  include Comparable(MpZ)

  # The underlying GMP MPZ structure
  @mpz : LibGMP::MPZ

  # Creates a new `MpZ` with value 0
  def initialize
    LibGMP.init(out @mpz)
  end

  # Creates a new `MpZ` from a string in the given base
  def initialize(str : String, base : Int32 = 10)
    str = str.lchop('+')
    str = str.delete('_')
    if LibGMP.init_set_str(out @mpz, str, base) == -1
      raise ArgumentError.new("Invalid MpZ: #{str}")
    end
  end

  # Creates a new `MpZ` from an Int
  def initialize(num : Int::Primitive)
    if num >= 0
      LibGMP.init_set_ui(out @mpz, num.to_u64)
    else
      LibGMP.init_set_si(out @mpz, num.to_i64)
    end
  end

  # Creates a new `MpZ` from a BigInt
  def initialize(num : BigInt)
    LibGMP.init(out @mpz)
    # Direct copy using the internal mpz pointer
    LibGMP.set(mpz, num.to_unsafe)
  end

  # Creates a new `MpZ` from a Float
  def initialize(num : Float::Primitive)
    raise ArgumentError.new "Can only construct from a finite number" unless num.finite?
    LibGMP.init_set_d(out @mpz, num)
  end

  # Creates a new `MpZ` from a raw MPZ struct (internal use)
  protected def initialize(@mpz : LibGMP::MPZ)
  end

  # Creates a copy of this `MpZ`
  def clone : MpZ
    MpZ.new { |new_mpz| LibGMP.set(new_mpz, mpz) }
  end

  # Sets the value of this `MpZ` to another value (mutates self)
  def set!(value : Int::Primitive) : self
    if value >= 0
      LibGMP.set_ui(mpz, value.to_u64)
    else
      LibGMP.set_si(mpz, value.to_i64)
    end
    self
  end

  def set!(value : BigInt) : self
    LibGMP.set(mpz, value.to_unsafe)
    self
  end

  def set!(value : MpZ) : self
    LibGMP.set(mpz, value.to_unsafe)
    self
  end

  # Adds another value to this one in-place
  def add!(other : Int::Primitive) : self
    if other >= 0
      LibGMP.add_ui(mpz, self, other.to_u64)
    else
      LibGMP.sub_ui(mpz, self, other.abs.to_u64)
    end
    self
  end

  def add!(other : BigInt) : self
    LibGMP.add(mpz, self, other.to_unsafe)
    self
  end

  def add!(other : MpZ) : self
    LibGMP.add(mpz, self, other.to_unsafe)
    self
  end

  # Subtracts another value from this one in-place
  def sub!(other : Int::Primitive) : self
    if other >= 0
      LibGMP.sub_ui(mpz, self, other.to_u64)
    else
      LibGMP.add_ui(mpz, self, other.abs.to_u64)
    end
    self
  end

  def sub!(other : BigInt) : self
    LibGMP.sub(mpz, self, other.to_unsafe)
    self
  end

  def sub!(other : MpZ) : self
    LibGMP.sub(mpz, self, other.to_unsafe)
    self
  end

  # Multiplies this value by another in-place
  def mul!(other : Int::Primitive) : self
    {% if LibGMP::SI == LibC::Long %}
      LibGMP.mul_si(mpz, self, other)
    {% else %}
      if other >= 0
        LibGMP.mul_ui(mpz, self, other.to_u64)
      else
        LibGMP.mul_si(mpz, self, other.to_i64)
      end
    {% end %}
    self
  end

  def mul!(other : BigInt) : self
    LibGMP.mul(mpz, self, other.to_unsafe)
    self
  end

  def mul!(other : MpZ) : self
    LibGMP.mul(mpz, self, other.to_unsafe)
    self
  end

  # Divides this value by another (floored division) in-place
  def div!(other : Int) : self
    check_division_by_zero other
    LibGMP.fdiv_q_ui(mpz, self, other.abs.to_u64)
    if other < 0
      neg!
    end
    self
  end

  def div!(other : BigInt) : self
    check_division_by_zero other
    LibGMP.fdiv_q(mpz, self, other.to_unsafe)
    self
  end

  def div!(other : MpZ) : self
    LibGMP.fdiv_q(mpz, self, other.to_unsafe)
    self
  end

  # Modulo operation in-place (floored)
  def mod!(other : Int) : self
    check_division_by_zero other
    LibGMP.fdiv_r_ui(mpz, self, other.abs.to_u64)
    if other < 0
      neg!
    end
    self
  end

  def mod!(other : BigInt) : self
    check_division_by_zero other
    LibGMP.fdiv_r(mpz, self, other.to_unsafe)
    self
  end

  def mod!(other : MpZ) : self
    LibGMP.fdiv_r(mpz, self, other.to_unsafe)
    self
  end

  # Negates this value in-place
  def neg! : self
    LibGMP.neg(mpz, self)
    self
  end

  # Absolute value in-place
  def abs! : self
    LibGMP.abs(mpz, self)
    self
  end

  # Left shift in-place
  def shl!(count : Int) : self
    LibGMP.mul_2exp(mpz, self, count.to_u64)
    self
  end

  # Right shift in-place
  def shr!(count : Int) : self
    LibGMP.fdiv_q_2exp(mpz, self, count.to_u64)
    self
  end

  # Bitwise AND in-place
  def and!(other : BigInt) : self
    LibGMP.and(mpz, self, other.to_unsafe)
    self
  end

  def and!(other : MpZ) : self
    LibGMP.and(mpz, self, other.to_unsafe)
    self
  end

  # Bitwise OR in-place
  def or!(other : BigInt) : self
    LibGMP.ior(mpz, self, other.to_unsafe)
    self
  end

  def or!(other : MpZ) : self
    LibGMP.ior(mpz, self, other.to_unsafe)
    self
  end

  # Bitwise XOR in-place
  def xor!(other : BigInt) : self
    LibGMP.xor(mpz, self, other.to_unsafe)
    self
  end

  def xor!(other : MpZ) : self
    LibGMP.xor(mpz, self, other.to_unsafe)
    self
  end

  # Bitwise complement in-place
  def complement! : self
    LibGMP.com(mpz, self)
    self
  end

  # Add-multiply in-place: self += other * multiplier
  def add_mul!(other : BigInt, multiplier : Int::Primitive) : self
    if multiplier >= 0
      LibGMP.addmul_ui(mpz, other.to_unsafe, multiplier.to_u64)
    else
      LibGMP.addmul(mpz, other.to_unsafe, multiplier.to_big_i.to_unsafe)
    end
    self
  end

  def add_mul!(other : MpZ, multiplier : Int::Primitive) : self
    if multiplier >= 0
      LibGMP.addmul_ui(mpz, other.to_unsafe, multiplier.to_u64)
    else
      LibGMP.addmul(mpz, other.to_unsafe, multiplier.to_big_i.to_unsafe)
    end
    self
  end

  # Power operation in-place
  def pow!(exponent : Int) : self
    if exponent < 0
      raise ArgumentError.new("Negative exponent isn't supported")
    elsif exponent == 1
      return self
    end
    LibGMP.pow_ui(mpz, self, exponent.to_u64)
    self
  end

  # GCD in-place
  def gcd!(other : BigInt) : self
    LibGMP.gcd(mpz, self, other.to_unsafe)
    self
  end

  def gcd!(other : MpZ) : self
    LibGMP.gcd(mpz, self, other.to_unsafe)
    self
  end

  # LCM in-place
  def lcm!(other : BigInt) : self
    LibGMP.lcm(mpz, self, other.to_unsafe)
    self
  end

  def lcm!(other : MpZ) : self
    LibGMP.lcm(mpz, self, other.to_unsafe)
    self
  end

  # Integer square root in-place (self = isqrt(self))
  def sqrt! : self
    if LibGMP.cmp_si(mpz, 0) < 0
      raise ArgumentError.new("Square root not defined for negative values")
    end
    LibGMP.sqrt(mpz, self)
    self
  end

  # Comparison
  def <=>(other : MpZ)
    LibGMP.cmp(mpz, other.to_unsafe)
  end

  def <=>(other : BigInt)
    LibGMP.cmp(mpz, other.to_unsafe)
  end

  def <=>(other : Int::Primitive) : Int32
    if other >= 0
      LibGMP.cmp_ui(mpz, other.to_u64)
    else
      LibGMP.cmp_si(mpz, other.to_i64)
    end
  end

  def <=>(other : Float::Primitive) : Int32?
    LibGMP.cmp_d(mpz, other) unless other.nan?
  end

  # Bit operations
  def bit(bit : Int) : Int32
    return 0 if bit < 0
    return LibGMP.cmp_si(mpz, 0) < 0 ? 1 : 0 if bit > LibGMP::BitcntT::MAX
    LibGMP.tstbit(mpz, LibGMP::BitcntT.new!(bit))
  end

  def popcount : Int
    LibGMP.popcount(mpz)
  end

  def trailing_zeros_count : Int
    LibGMP.scan1(mpz, 0)
  end

  def bit_length : Int32
    LibGMP.sizeinbase(mpz, 2).to_i
  end

  # Conversions
  def to_big_i : BigInt
    # Efficient direct conversion using GMP's internal representation
    BigInt.new { |b_mpz| LibGMP.set(b_mpz, mpz) }
  end

  def to_i : Int32
    to_i32
  end

  def to_i! : Int32
    to_i32!
  end

  {% for n in [8, 16, 32, 64, 128] %}
    def to_i{{n}} : Int{{n}}
      to_big_i.to_i{{n}}
    end

    def to_u{{n}} : UInt{{n}}
      to_big_i.to_u{{n}}
    end

    def to_i{{n}}! : Int{{n}}
      LibGMP.get_si(mpz).to_i{{n}}!
    end

    def to_u{{n}}! : UInt{{n}}
      LibGMP.get_ui(mpz).to_u{{n}}!
    end
  {% end %}

  def to_f : Float64
    to_f64
  end

  def to_f! : Float64
    to_f64!
  end

  def to_f32 : Float32
    LibGMP.get_d(mpz).to_f32
  end

  def to_f64 : Float64
    LibGMP.get_d(mpz)
  end

  def to_f32! : Float32
    LibGMP.get_d(mpz).to_f32!
  end

  def to_f64! : Float64
    LibGMP.get_d(mpz)
  end

  def to_s(io : IO, base : Int = 10, *, precision : Int = 1, upcase : Bool = false) : Nil
    raise ArgumentError.new("Invalid base #{base}") unless 2 <= base <= 36 || base == 62
    raise ArgumentError.new("upcase must be false for base 62") if upcase && base == 62
    raise ArgumentError.new("Precision must be non-negative") unless precision >= 0

    case {self, precision}
    when {0, 0}
      # do nothing
    when {0, 1}
      io << '0'
    when {1, 1}
      io << '1'
    else
      count = LibGMP.sizeinbase(mpz, base).to_i
      ptr = LibGMP.get_str(nil, upcase ? -base : base, mpz)
      negative = LibGMP.cmp_si(mpz, 0) < 0

      count -= 1 if ptr[count + (negative ? 0 : -1)] == 0

      if precision <= count
        buffer = Slice.new(ptr, count + (negative ? 1 : 0))
      else
        if negative
          io << '-'
          ptr += 1
        end

        (precision - count).times { io << '0' }
        buffer = Slice.new(ptr, count)
      end

      io.write_string buffer
    end
  end

  def to_s(base : Int = 10, *, precision : Int = 1, upcase : Bool = false) : String
    String.build { |io| to_s(io, base, precision: precision, upcase: upcase) }
  end

  def to_unsafe : Pointer(LibGMP::MPZ)
    mpz
  end

  def hash(hasher)
    hasher.hash(self.to_big_i)
  end

  def zero? : Bool
    LibGMP.cmp_ui(mpz, 0) == 0
  end

  def odd? : Bool
    LibGMP.tstbit(mpz, 0) == 1
  end

  def even? : Bool
    LibGMP.tstbit(mpz, 0) == 0
  end

  private def mpz
    pointerof(@mpz)
  end

  private def check_division_by_zero(value)
    if value == 0
      raise DivisionByZeroError.new
    end
  end

  def self.new(&)
    LibGMP.init(out mpz)
    yield pointerof(mpz)
    new(mpz)
  end

  # Convenience methods for creating common values
  def self.zero : MpZ
    new(0)
  end

  def self.one : MpZ
    new(1)
  end

  def self.two : MpZ
    new(2)
  end

  def self.ten : MpZ
    new(10)
  end
end

# Extending Int for convenience
struct Int
  def to_mpz : MutGMP::MpZ
    MutGMP::MpZ.new(self)
  end

  def <=>(other : MutGMP::MpZ)
    -(other <=> self)
  end
end

struct BigInt
  def to_mpz : MutGMP::MpZ
    MutGMP::MpZ.new(self)
  end

  def <=>(other : MutGMP::MpZ)
    -(other <=> self)
  end
end

class String
  def to_mpz(base : Int32 = 10) : MutGMP::MpZ
    MutGMP::MpZ.new(self, base)
  end
end
