require "big"

# A mutable wrapper around GMP's MPF (arbitrary precision floating point).
#
# Unlike `BigFloat`, operations on `MutGMP::MpF` mutate the receiver in-place,
# which is more efficient for algorithms that perform many operations on the
# same value.
#
# ```
# require "mut_gmp"
#
# a = MutGMP::MpF.new(3.14)
# b = MutGMP::MpF.new(2.0)
#
# a.add!(b) # a is now 5.14
# a.mul!(2) # a is now 10.28
# ```
struct MutGMP::MpF
  include Comparable(MpF)

  # The underlying GMP MPF structure
  @mpf : LibGMP::MPF

  # Default precision in bits
  @@default_precision : Int64 = 256

  def self.default_precision : Int64
    @@default_precision
  end

  # Sets the default precision for newly created MpF values
  def self.default_precision=(prec : Int)
    @@default_precision = prec.to_i64
    LibGMP.mpf_set_default_prec(prec.to_u64)
  end

  # Creates a new `MpF` with value 0.0
  def initialize
    LibGMP.mpf_init(out @mpf)
  end

  # Creates a new `MpF` with the specified precision (in bits) and value 0.0
  def initialize(precision : Int)
    LibGMP.mpf_init2(out @mpf, precision.to_u64)
  end

  # Creates a new `MpF` from a string
  def initialize(str : String)
    str = str.lchop('+')
    str = str.delete('_')
    if LibGMP.mpf_init_set_str(out @mpf, str, 10) == -1
      raise ArgumentError.new("Invalid MpF: #{str}")
    end
  end

  # Creates a new `MpF` from an Int
  def initialize(num : Int::Primitive, precision : Int = @@default_precision)
    if num >= 0
      LibGMP.mpf_init_set_ui(out @mpf, num.to_u64)
    else
      LibGMP.mpf_init_set_si(out @mpf, num.to_i64)
    end
  end

  # Creates a new `MpF` from a BigInt
  def initialize(num : BigInt)
    LibGMP.mpf_init(out @mpf)
    LibGMP.mpf_set_z(mpf, num)
  end

  # Creates a new `MpF` from a BigFloat
  def initialize(num : BigFloat)
    LibGMP.mpf_init(out @mpf)
    LibGMP.mpf_set(mpf, num)
  end

  # Creates a new `MpF` from a Float with specified precision
  def initialize(num : Float::Primitive, precision : Int = @@default_precision)
    raise ArgumentError.new "Can only construct from a finite number" unless num.finite?
    LibGMP.mpf_init2(out @mpf, precision.to_u64)
    LibGMP.mpf_set_d(mpf, num)
  end

  # Creates a new `MpF` from a raw MPF struct (internal use)
  protected def initialize(@mpf : LibGMP::MPF)
  end

  # Returns the precision of this value in bits
  def precision : Int64
    LibGMP.mpf_get_prec(mpf).to_i64
  end

  # Sets the precision of this value (may cause reallocation)
  def precision=(prec : Int)
    LibGMP.mpf_set_prec(mpf, prec.to_u64)
  end

  # Creates a copy of this `MpF`
  def clone : MpF
    MpF.new { |new_mpf| LibGMP.mpf_set(new_mpf, self) }
  end

  # Sets the value of this `MpF` to another value (mutates self)
  def set!(value : Float::Primitive) : self
    raise ArgumentError.new "Can only construct from a finite number" unless value.finite?
    LibGMP.mpf_set_d(mpf, value)
    self
  end

  def set!(value : Int::Primitive) : self
    if value >= 0
      LibGMP.mpf_set_ui(mpf, value.to_u64)
    else
      LibGMP.mpf_set_si(mpf, value.to_i64)
    end
    self
  end

  def set!(value : BigInt) : self
    LibGMP.mpf_set_z(mpf, value)
    self
  end

  def set!(value : BigFloat) : self
    LibGMP.mpf_set(mpf, value)
    self
  end

  def set!(value : MpF) : self
    LibGMP.mpf_set(mpf, value)
    self
  end

  # Adds another value to this one in-place
  def add!(other : Int::Primitive) : self
    if other >= 0
      LibGMP.mpf_add_ui(mpf, self, other.to_u64)
    else
      LibGMP.mpf_sub_ui(mpf, self, other.abs.to_u64)
    end
    self
  end

  def add!(other : BigInt) : self
    temp = MpF.new(other)
    LibGMP.mpf_add(mpf, self, temp)
    self
  end

  def add!(other : BigFloat) : self
    temp = MpF.new(other)
    LibGMP.mpf_add(mpf, self, temp)
    self
  end

  def add!(other : MpF) : self
    LibGMP.mpf_add(mpf, self, other)
    self
  end

  # Subtracts another value from this one in-place
  def sub!(other : Int::Primitive) : self
    if other >= 0
      LibGMP.mpf_sub_ui(mpf, self, other.to_u64)
    else
      LibGMP.mpf_add_ui(mpf, self, other.abs.to_u64)
    end
    self
  end

  def sub!(other : BigInt) : self
    temp = MpF.new(other)
    LibGMP.mpf_sub(mpf, self, temp)
    self
  end

  def sub!(other : BigFloat) : self
    temp = MpF.new(other)
    LibGMP.mpf_sub(mpf, self, temp)
    self
  end

  def sub!(other : MpF) : self
    LibGMP.mpf_sub(mpf, self, other)
    self
  end

  # Multiplies this value by another in-place
  def mul!(other : Int::Primitive) : self
    if other >= 0
      LibGMP.mpf_mul_ui(mpf, self, other.to_u64)
    else
      LibGMP.mpf_mul_ui(mpf, self, other.abs.to_u64)
      LibGMP.mpf_neg(mpf, mpf)
    end
    self
  end

  def mul!(other : BigInt) : self
    temp = MpF.new(other)
    LibGMP.mpf_mul(mpf, self, temp)
    self
  end

  def mul!(other : BigFloat) : self
    temp = MpF.new(other)
    LibGMP.mpf_mul(mpf, self, temp)
    self
  end

  def mul!(other : MpF) : self
    LibGMP.mpf_mul(mpf, self, other)
    self
  end

  # Divides this value by another in-place
  def div!(other : Int) : self
    raise DivisionByZeroError.new if other == 0
    if other >= 0
      LibGMP.mpf_div_ui(mpf, self, other.to_u64)
    else
      LibGMP.mpf_div_ui(mpf, self, other.abs.to_u64)
      LibGMP.mpf_neg(mpf, mpf)
    end
    self
  end

  def div!(other : BigInt) : self
    raise DivisionByZeroError.new if other == 0
    temp = MpF.new(other)
    LibGMP.mpf_div(mpf, self, temp)
    self
  end

  def div!(other : BigFloat) : self
    raise DivisionByZeroError.new if other == 0
    temp = MpF.new(other)
    LibGMP.mpf_div(mpf, self, temp)
    self
  end

  def div!(other : MpF) : self
    LibGMP.mpf_div(mpf, self, other)
    self
  end

  # Power operation in-place
  def pow!(exponent : Int) : self
    if zero? && exponent < 0
      raise ArgumentError.new "Cannot raise 0 to a negative power"
    end

    if exponent >= 0
      LibGMP.mpf_pow_ui(mpf, self, exponent.to_u64)
    else
      LibGMP.mpf_pow_ui(mpf, self, exponent.abs.to_u64)
      LibGMP.mpf_ui_div(mpf, 1, mpf)
    end
    self
  end

  # Negates this value in-place
  def neg! : self
    LibGMP.mpf_neg(mpf, self)
    self
  end

  # Absolute value in-place
  def abs! : self
    LibGMP.mpf_abs(mpf, self)
    self
  end

  # Square root in-place
  def sqrt! : self
    LibGMP.mpf_sqrt(mpf, self)
    self
  end

  # Floor in-place
  def floor! : self
    LibGMP.mpf_floor(mpf, self)
    self
  end

  # Ceil in-place
  def ceil! : self
    LibGMP.mpf_ceil(mpf, self)
    self
  end

  # Trunc in-place
  def trunc! : self
    LibGMP.mpf_trunc(mpf, self)
    self
  end

  # Multiply by 2^exp in-place
  def mul_2exp!(exp : Int) : self
    LibGMP.mpf_mul_2exp(mpf, self, exp.to_u64)
    self
  end

  # Divide by 2^exp in-place
  def div_2exp!(exp : Int) : self
    LibGMP.mpf_div_2exp(mpf, self, exp.abs.to_u64)
    self
  end

  # Comparison
  def <=>(other : MpF)
    LibGMP.mpf_cmp(mpf, other)
  end

  def <=>(other : BigFloat)
    LibGMP.mpf_cmp(mpf, other)
  end

  def <=>(other : Float::Primitive) : Int32?
    LibGMP.mpf_cmp_d(mpf, other) unless other.nan?
  end

  def <=>(other : Int::Primitive) : Int32
    if other >= 0
      LibGMP.mpf_cmp_ui(mpf, other.to_u64)
    else
      LibGMP.mpf_cmp_si(mpf, other.to_i64)
    end
  end

  # Returns true if this value is an integer
  def integer? : Bool
    !LibGMP.mpf_integer_p(mpf).zero?
  end

  # Returns true if this value is zero
  def zero? : Bool
    LibGMP.mpf_cmp_ui(mpf, 0) == 0
  end

  # Conversions
  def to_big_f : BigFloat
    BigFloat.new { |new_mpf| LibGMP.mpf_set(new_mpf, self) }
  end

  def to_f : Float64
    to_f64
  end

  def to_f! : Float64
    to_f64!
  end

  def to_f32 : Float32
    LibGMP.mpf_get_d(mpf).to_f32
  end

  def to_f64 : Float64
    LibGMP.mpf_get_d(mpf)
  end

  def to_f32! : Float32
    LibGMP.mpf_get_d(mpf).to_f32!
  end

  def to_f64! : Float64
    LibGMP.mpf_get_d(mpf)
  end

  def to_big_i : BigInt
    BigInt.new { |mpz| LibGMP.set_f(mpz, mpf) }
  end

  def to_i : Int32
    to_i32
  end

  def to_i! : Int32
    to_i32!
  end

  def to_i32 : Int32
    raise OverflowError.new unless LibGMP::Long::MIN <= self <= LibGMP::Long::MAX
    LibGMP.mpf_get_si(mpf).to_i32
  end

  def to_i64 : Int64
    raise OverflowError.new unless LibGMP::Long::MIN <= self <= LibGMP::Long::MAX
    LibGMP.mpf_get_si(mpf).to_i64
  end

  def to_i32! : Int32
    LibGMP.mpf_get_si(mpf).to_i32!
  end

  def to_i64! : Int64
    LibGMP.mpf_get_si(mpf).to_i64!
  end

  def to_u32 : UInt32
    raise OverflowError.new unless 0 <= self <= LibGMP::ULong::MAX
    LibGMP.mpf_get_ui(mpf).to_u32
  end

  def to_u64 : UInt64
    raise OverflowError.new unless 0 <= self <= LibGMP::ULong::MAX
    LibGMP.mpf_get_ui(mpf).to_u64
  end

  def to_u32! : UInt32
    LibGMP.mpf_get_ui(mpf).to_u32!
  end

  def to_u64! : UInt64
    LibGMP.mpf_get_ui(mpf).to_u64!
  end

  def to_s(io : IO) : Nil
    to_s_impl(io, point_range: -3..15, int_trailing_zeros: true)
  end

  protected def to_s_impl(*, point_range : Range, int_trailing_zeros : Bool) : String
    String.build { |io| to_s_impl(io, point_range: point_range, int_trailing_zeros: int_trailing_zeros) }
  end

  protected def to_s_impl(io : IO, *, point_range : Range, int_trailing_zeros : Bool) : Nil
    cstr = LibGMP.mpf_get_str(nil, out orig_decimal_exponent, 10, 0, mpf)
    buffer = Slice.new(cstr, LibC.strlen(cstr))

    if buffer[0]? == 45 # '-'
      io << '-'
      buffer = buffer[1..]
    end

    decimal_exponent = orig_decimal_exponent - buffer.size
    if int_trailing_zeros
      fraction = ::Float::Printer::FractionMode::WriteAll
    else
      fraction = ::Float::Printer::FractionMode::RemoveIfZero
    end

    ::Float::Printer.decimal(io, buffer, decimal_exponent, point_range, fraction)
  end

  def to_unsafe : Pointer(LibGMP::MPF)
    mpf
  end

  def hash(hasher)
    # Hash based on string representation for floating point
    hasher.hash(to_s)
  end

  private def mpf
    pointerof(@mpf)
  end

  # Yield the raw mpf pointer for initialization
  def self.new(&)
    LibGMP.mpf_init(out mpf)
    yield pointerof(mpf)
    new(mpf)
  end

  # Convenience methods for creating common values
  def self.zero : MpF
    new(0)
  end

  def self.one : MpF
    new(1)
  end

  def self.two : MpF
    new(2)
  end

  def self.ten : MpF
    new(10)
  end

  # Create with specified precision
  def self.with_precision(prec : Int, & : self ->)
    mpf = new(prec)
    yield mpf
  end
end

# Extending standard types for convenience
struct Int
  def to_mpf(precision : Int = MutGMP::MpF.default_precision) : MutGMP::MpF
    MutGMP::MpF.new(self, precision)
  end
end

struct Float
  def to_mpf(precision : Int = MutGMP::MpF.default_precision) : MutGMP::MpF
    MutGMP::MpF.new(self, precision)
  end
end

struct BigInt
  def to_mpf(precision : Int = MutGMP::MpF.default_precision) : MutGMP::MpF
    MutGMP::MpF.new(self)
  end
end

struct BigFloat
  def to_mpf : MutGMP::MpF
    MutGMP::MpF.new(self)
  end
end

class String
  def to_mpf : MutGMP::MpF
    MutGMP::MpF.new(self)
  end
end
