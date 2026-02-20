require "big"
require "./mp_z"

# A mutable wrapper around GMP's MPQ (arbitrary precision rational).
#
# Unlike `BigRational`, operations on `MutGMP::MpQ` mutate the receiver in-place,
# which is more efficient for algorithms that perform many operations on the
# same value.
#
# ```
# require "mut_gmp"
#
# a = MutGMP::MpQ.new(1, 3) # 1/3
# b = MutGMP::MpQ.new(1, 6) # 1/6
#
# a.add!(b) # a is now 1/2
# a.mul!(2) # a is now 1
# ```
struct MutGMP::MpQ
  include Comparable(MpQ)

  # The underlying GMP MPQ structure
  @mpq : LibGMP::MPQ

  # Creates a new `MpQ` with value 0/1
  def initialize
    LibGMP.mpq_init(out @mpq)
  end

  # Creates a new `MpQ` from a numerator and denominator
  def initialize(numerator : Int::Primitive, denominator : Int::Primitive = 1)
    raise ArgumentError.new("Denominator cannot be zero") if denominator == 0

    LibGMP.mpq_init(out @mpq)
    num = MpZ.new(numerator)
    den = MpZ.new(denominator)
    LibGMP.mpq_set_num(mpq, num)
    LibGMP.mpq_set_den(mpq, den)
    LibGMP.mpq_canonicalize(mpq)
  end

  # Creates a new `MpQ` from an integer (denominator = 1)
  def initialize(value : BigInt)
    LibGMP.mpq_init(out @mpq)
    LibGMP.mpq_set_z(mpq, value)
  end

  # Creates a new `MpQ` from a BigRational
  def initialize(value : BigRational)
    LibGMP.mpq_init(out @mpq)
    LibGMP.set(mpq, value)
  end

  # Creates a new `MpQ` from a Float
  def initialize(value : Float::Primitive)
    raise ArgumentError.new "Can only construct from a finite number" unless value.finite?
    LibGMP.mpq_init(out @mpq)
    LibGMP.mpq_set_d(mpq, value)
  end

  # Creates a new `MpQ` from a raw MPQ struct (internal use)
  protected def initialize(@mpq : LibGMP::MPQ)
  end

  # Creates a copy of this `MpQ`
  def clone : MpQ
    MpQ.new { |new_mpq| LibGMP.set(new_mpq, self) }
  end

  # Sets the numerator and denominator from MpZ values
  protected def set_z!(num : MpZ, den : MpZ) : self
    LibGMP.mpq_set_num(mpq, num)
    LibGMP.mpq_set_den(mpq, den)
    LibGMP.mpq_canonicalize(mpq)
    self
  end

  # Sets the value of this `MpQ` to another value (mutates self)
  def set!(value : Int::Primitive) : self
    num = MpZ.new(value)
    den = MpZ.new(1)
    set_z!(num, den)
  end

  def set!(value : BigInt) : self
    LibGMP.mpq_set_z(mpq, value)
    self
  end

  def set!(value : BigRational) : self
    LibGMP.set(mpq, value)
    self
  end

  def set!(value : MpQ) : self
    LibGMP.set(mpq, value)
    self
  end

  def set!(numerator : Int::Primitive, denominator : Int::Primitive) : self
    raise ArgumentError.new("Denominator cannot be zero") if denominator == 0
    num = MpZ.new(numerator)
    den = MpZ.new(denominator)
    set_z!(num, den)
  end

  # Returns the numerator as a new MpZ
  def numerator : MpZ
    MpZ.new { |mpz| LibGMP.mpq_get_num(mpz, mpq) }
  end

  # Returns the denominator as a new MpZ
  def denominator : MpZ
    MpZ.new { |mpz| LibGMP.mpq_get_den(mpz, mpq) }
  end

  # Canonicalizes the rational (ensures numerator and denominator are coprime)
  def canonicalize! : self
    LibGMP.mpq_canonicalize(mpq)
    self
  end

  # Adds another value to this one in-place
  def add!(other : Int::Primitive) : self
    temp = MpQ.new(other, 1)
    LibGMP.mpq_add(mpq, self, temp)
    self
  end

  def add!(other : BigInt) : self
    temp = MpQ.new(other)
    LibGMP.mpq_add(mpq, self, temp)
    self
  end

  def add!(other : BigRational) : self
    temp = MpQ.new(other)
    LibGMP.mpq_add(mpq, self, temp)
    self
  end

  def add!(other : MpQ) : self
    LibGMP.mpq_add(mpq, self, other)
    self
  end

  # Subtracts another value from this one in-place
  def sub!(other : Int::Primitive) : self
    temp = MpQ.new(other, 1)
    LibGMP.mpq_sub(mpq, self, temp)
    self
  end

  def sub!(other : BigInt) : self
    temp = MpQ.new(other)
    LibGMP.mpq_sub(mpq, self, temp)
    self
  end

  def sub!(other : BigRational) : self
    temp = MpQ.new(other)
    LibGMP.mpq_sub(mpq, self, temp)
    self
  end

  def sub!(other : MpQ) : self
    LibGMP.mpq_sub(mpq, self, other)
    self
  end

  # Multiplies this value by another in-place
  def mul!(other : Int::Primitive) : self
    temp = MpQ.new(other, 1)
    LibGMP.mpq_mul(mpq, self, temp)
    self
  end

  def mul!(other : BigInt) : self
    temp = MpQ.new(other)
    LibGMP.mpq_mul(mpq, self, temp)
    self
  end

  def mul!(other : BigRational) : self
    temp = MpQ.new(other)
    LibGMP.mpq_mul(mpq, self, temp)
    self
  end

  def mul!(other : MpQ) : self
    LibGMP.mpq_mul(mpq, self, other)
    self
  end

  # Divides this value by another in-place
  def div!(other : Int) : self
    raise DivisionByZeroError.new if other == 0
    temp = MpQ.new(other, 1)
    LibGMP.mpq_div(mpq, self, temp)
    self
  end

  def div!(other : BigInt) : self
    raise DivisionByZeroError.new if other == 0
    temp = MpQ.new(other)
    LibGMP.mpq_div(mpq, self, temp)
    self
  end

  def div!(other : BigRational) : self
    raise DivisionByZeroError.new if other == 0
    temp = MpQ.new(other)
    LibGMP.mpq_div(mpq, self, temp)
    self
  end

  def div!(other : MpQ) : self
    LibGMP.mpq_div(mpq, self, other)
    self
  end

  # Negates this value in-place
  def neg! : self
    LibGMP.mpq_neg(mpq, self)
    self
  end

  # Absolute value in-place
  def abs! : self
    LibGMP.mpq_abs(mpq, self)
    self
  end

  # Inverts this value in-place (1/self)
  def inv! : self
    LibGMP.mpq_inv(mpq, self)
    self
  end

  # Multiply by 2^n in-place
  def mul_2exp!(n : Int) : self
    LibGMP.mpq_mul_2exp(mpq, self, n.to_u64)
    self
  end

  # Divide by 2^n in-place
  def div_2exp!(n : Int) : self
    LibGMP.mpq_div_2exp(mpq, self, n.to_u64)
    self
  end

  # Comparison
  def <=>(other : MpQ)
    LibGMP.mpq_cmp(mpq, other)
  end

  def <=>(other : BigRational)
    LibGMP.mpq_cmp(mpq, other)
  end

  def <=>(other : BigInt) : Int32
    LibGMP.mpq_cmp_z(mpq, other)
  end

  def <=>(other : Int::Primitive) : Int32
    if other >= 0
      LibGMP.mpq_cmp_ui(mpq, other.to_u64, 1)
    else
      LibGMP.mpq_cmp_si(mpq, other.to_i64, 1)
    end
  end

  # Returns true if this value is zero
  def zero? : Bool
    LibGMP.mpq_cmp_ui(mpq, 0, 1) == 0
  end

  # Returns true if this value is an integer (denominator == 1)
  def integer? : Bool
    denominator == 1
  end

  # Conversions
  def to_big_r : BigRational
    BigRational.new { |b_mpq| LibGMP.set(b_mpq, self) }
  end

  def to_big_i : BigInt
    BigInt.new { |_| LibGMP.set(mpq, self) }
  end

  def to_f : Float64
    to_f64
  end

  def to_f! : Float64
    to_f64!
  end

  def to_f32 : Float32
    LibGMP.mpq_get_d(mpq).to_f32
  end

  def to_f64 : Float64
    LibGMP.mpq_get_d(mpq)
  end

  def to_f32! : Float32
    LibGMP.mpq_get_d(mpq).to_f32!
  end

  def to_f64! : Float64
    LibGMP.mpq_get_d(mpq)
  end

  def to_s(io : IO, base : Int = 10) : Nil
    raise ArgumentError.new("Invalid base #{base}") unless 2 <= base <= 62

    cstr = LibGMP.mpq_get_str(nil, base, mpq)
    buffer = Slice.new(cstr, LibC.strlen(cstr))
    io.write_string(buffer)
  end

  def to_s(base : Int = 10) : String
    String.build { |io| to_s(io, base) }
  end

  def to_unsafe : Pointer(LibGMP::MPQ)
    mpq
  end

  def hash(hasher)
    hasher.hash(to_big_r)
  end

  private def mpq
    pointerof(@mpq)
  end

  # Yield the raw mpq pointer for initialization
  def self.new(&)
    LibGMP.mpq_init(out mpq)
    yield pointerof(mpq)
    new(mpq)
  end

  # Convenience methods for creating common values
  def self.zero : MpQ
    new(0, 1)
  end

  def self.one : MpQ
    new(1, 1)
  end

  def self.two : MpQ
    new(2, 1)
  end
end

# LibGMP bindings for MPQ operations
lib LibGMP
  fun set = __gmpq_set(rop : MPQ*, op : MPQ*)
end

# Extending standard types for convenience
struct Int
  def to_mpq(denominator : Int = 1) : MutGMP::MpQ
    MutGMP::MpQ.new(self, denominator)
  end
end

struct BigInt
  def to_mpq(denominator : Int = 1) : MutGMP::MpQ
    MutGMP::MpQ.new(self)
  end
end

struct BigRational
  def to_mpq : MutGMP::MpQ
    MutGMP::MpQ.new(self)
  end
end
