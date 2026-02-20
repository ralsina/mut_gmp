require "../src/mut_gmp"

# A simple demonstration of the efficiency difference between
# mutable and immutable GMP operations for a spigot-like algorithm.
#
# This is a simplified spigot algorithm for computing digits of pi
# (based on the Gibbons spigot algorithm).
#
# The key insight is that spigot algorithms repeatedly update
# the same large integers, making mutable operations much more
# efficient.

# Standard library BigInt version (creates many allocations)
def pi_digits_immutable(count : Int) : String
  # Simplified Bailey-Borwein-Plouffe formula digits
  # This is not a real spigot but demonstrates the allocation pattern
  result = [] of Int32
  a = BigInt.new(1)
  b = BigInt.new(1)
  c = BigInt.new(1)

  count.times do |i|
    # Each operation creates a new BigInt
    a = a + b
    b = b + c
    c = c + a
    result << (a % 10).to_i32
  end

  result.map(&.to_s).join
end

# Mutable MpZ version (reuses allocations)
def pi_digits_mutable(count : Int) : String
  result = [] of Int32
  a = MutGMP::MpZ.new(1)
  b = MutGMP::MpZ.new(1)
  c = MutGMP::MpZ.new(1)

  count.times do |i|
    # Operations mutate in-place
    a.add!(b)
    b.add!(c)
    c.add!(a)
    result << a.to_i32!
  end

  result.map(&.to_s).join
end

# Benchmark both versions
puts "Testing mutable GMP bindings for spigot-style algorithms"
puts "=" * 60

count = 1000

# Warm up
pi_digits_immutable(10)
pi_digits_mutable(10)

# Benchmark immutable version
GC.collect
t1 = Time.instant
result_immutable = pi_digits_immutable(count)
t_immutable = Time.instant - t1

# Benchmark mutable version
GC.collect
t2 = Time.instant
result_mutable = pi_digits_mutable(count)
t_mutable = Time.instant - t2

puts "Computed #{count} iterations"
puts
puts "Immutable (BigInt):     #{t_immutable.total_milliseconds.round(2)} ms"
puts "Mutable (MpZ):          #{t_mutable.total_milliseconds.round(2)} ms"
puts
puts "Speedup: #{(t_immutable / t_mutable).round(2)}x faster"
puts

# Demonstrate a more realistic use case with larger numbers
puts "Testing with larger numbers (factorial calculation)"
puts "=" * 60

def factorial_immutable(n : Int) : BigInt
  (1..n).reduce(BigInt.new(1)) { |acc, i| acc * i }
end

def factorial_mutable(n : Int) : MutGMP::MpZ
  result = MutGMP::MpZ.new(1)
  (2..n).each do |i|
    result.mul!(i)
  end
  result
end

n = 10000

GC.collect
t1 = Time.instant
fact_immutable = factorial_immutable(n)
t_immutable_fact = Time.instant - t1

GC.collect
t2 = Time.instant
fact_mutable = factorial_mutable(n)
t_mutable_fact = Time.instant - t2

puts "#{n}! computation:"
puts "Immutable (BigInt):     #{t_immutable_fact.total_milliseconds.round(2)} ms"
puts "Mutable (MpZ):          #{t_mutable_fact.total_milliseconds.round(2)} ms"
puts
puts "Speedup: #{(t_immutable_fact / t_mutable_fact).round(2)}x faster"
puts
puts "Both results equal: #{fact_immutable == fact_mutable.to_big_i}"
puts

# Demonstrate floating point operations
puts "Testing MpF (floating point) operations"
puts "=" * 60

def compute_sum_immutable(n : Int) : BigFloat
  sum = BigFloat.new(0.0)
  n.times do |i|
    sum = sum + (i + 1).to_big_f
  end
  sum
end

def compute_sum_mutable(n : Int) : MutGMP::MpF
  sum = MutGMP::MpF.new(0.0)
  n.times do |i|
    sum.add!(i + 1)
  end
  sum
end

n = 10000

GC.collect
t1 = Time.instant
sum_immutable = compute_sum_immutable(n)
t_immutable_sum = Time.instant - t1

GC.collect
t2 = Time.instant
sum_mutable = compute_sum_mutable(n)
t_mutable_sum = Time.instant - t2

puts "Summing #{n} integers:"
puts "Immutable (BigFloat):   #{t_immutable_sum.total_milliseconds.round(2)} ms"
puts "Mutable (MpF):          #{t_mutable_sum.total_milliseconds.round(2)} ms"
puts
puts "Speedup: #{(t_immutable_sum / t_mutable_sum).round(2)}x faster"
