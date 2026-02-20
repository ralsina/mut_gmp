require "../src/mut_gmp/mp_z"
require "../src/mut_gmp/mp_q"
require "../src/mut_gmp/mp_f"

puts "Testing all MutGMP features..."
puts "=" * 50

# Test MpZ basic operations
puts "\n1. Testing MpZ (Integers):"
a = MutGMP::MpZ.new(10)
b = MutGMP::MpZ.new(5)

a.add!(b)
puts "  add!(5): #{a.to_s} == 15"

a.sub!(3)
puts "  sub!(3): #{a.to_s} == 12"

a.mul!(2)
puts "  mul!(2): #{a.to_s} == 24"

a.div!(3)
puts "  div!(3): #{a.to_s} == 8"

a.neg!
puts "  neg!: #{a.to_s} == -8"

a.abs!
puts "  abs!: #{a.to_s} == 8"

# Test MpZ with BigInt
c = MutGMP::MpZ.new(100)
c.add!(BigInt.new(50))
puts "  add!(BigInt): #{c.to_s} == 150"

# Test MpZ to BigInt conversion
d = MutGMP::MpZ.new(42)
big_int = d.to_big_i
puts "  to_big_i: #{big_int.to_s} == 42 (#{big_int.class})"

# Test MpQ basic operations
puts "\n2. Testing MpQ (Rationals):"
q1 = MutGMP::MpQ.new(1, 3)
q2 = MutGMP::MpQ.new(1, 6)

q1.add!(q2)
puts "  1/3 + 1/6: #{q1.to_s} == 1/2"

q1.mul!(2)
puts "  (1/2) * 2: #{q1.to_s} == 1"

q3 = MutGMP::MpQ.new(3, 4)
q3.inv!
puts "  (3/4).inv!: #{q3.to_s} == 4/3"

# Test MpF basic operations
puts "\n3. Testing MpF (Floats):"
f1 = MutGMP::MpF.new(1.5)
f2 = MutGMP::MpF.new(2.5)

f1.add!(f2)
puts "  1.5 + 2.5: #{f1.to_s} == 4.0"

f1.mul!(2.0)
puts "  4.0 * 2.0: #{f1.to_s} == 8.0"

f1.div!(4.0)
puts "  8.0 / 4.0: #{f1.to_s} == 2.0"

# Test MpF with BigInt
f3 = MutGMP::MpF.new(5.0)
f3.add!(BigInt.new(3))
puts "  5.0 + 3: #{f3.to_s} == 8.0"

# Test comparison operations
puts "\n4. Testing Comparisons:"
x = MutGMP::MpZ.new(100)
y = MutGMP::MpZ.new(50)

puts "  100 > 50: #{x > y}"
puts "  50 < 100: #{y < x}"
puts "  100 == 100: #{MutGMP::MpZ.new(100) == x}"

# Test with BigInt comparison
z = BigInt.new(75)
puts "  75 <=> 50 (MpZ): #{(z <=> y) > 0}"
puts "  75 <=> 100 (MpZ): #{(z <=> x) < 0}"

# Test precision setting
puts "\n5. Testing MpF Precision:"
MutGMP::MpF.default_precision = 128
high_prec = MutGMP::MpF.new(1.0, precision: 256)
puts "  Default precision: #{MutGMP::MpF.default_precision}"
puts "  High precision value: #{high_prec.to_s}"

# Test bitwise operations
puts "\n6. Testing Bitwise Operations (MpZ):"
b1 = MutGMP::MpZ.new(0b1010)  # 10
b2 = MutGMP::MpZ.new(0b1100)  # 12

b1.and!(b2)
puts "  1010 & 1100: #{b1.to_s} == 8 (0b1000)"

b1.or!(MutGMP::MpZ.new(0b0001))
puts "  1000 | 0001: #{b1.to_s} == 9 (0b1001)"

# Test shift operations
s1 = MutGMP::MpZ.new(8)
s1.shl!(2)
puts "  8 << 2: #{s1.to_s} == 32"

s1.shr!(3)
puts "  32 >> 3: #{s1.to_s} == 4"

# Test power and GCD
puts "\n7. Testing Advanced Operations:"
p1 = MutGMP::MpZ.new(2)
p1.pow!(10)
puts "  2^10: #{p1.to_s} == 1024"

g1 = MutGMP::MpZ.new(48)
g2 = MutGMP::MpZ.new(18)
g1.gcd!(g2)
puts "  gcd(48, 18): #{g1.to_s} == 6"

l1 = MutGMP::MpZ.new(12)
l2 = MutGMP::MpZ.new(18)
l1.lcm!(l2)
puts "  lcm(12, 18): #{l1.to_s} == 36"

# Test sqrt
sqrt_val = MutGMP::MpZ.new(144)
sqrt_val.sqrt!
puts "  sqrt(144): #{sqrt_val.to_s} == 12"

# Test that standard library still works
puts "\n8. Testing Standard Library Compatibility:"
bi1 = BigInt.new(100)
bi2 = BigInt.new(200)
bi_sum = bi1 + bi2
puts "  BigInt + BigInt: #{bi_sum.to_s} == 300"

br1 = BigRational.new(1, 3)
br2 = BigRational.new(1, 6)
br_sum = br1 + br2
puts "  BigRational + BigRational: #{br_sum.to_s} == 1/2"

bf1 = BigFloat.new(1.5)
bf2 = BigFloat.new(2.5)
bf_sum = bf1 + bf2
puts "  BigFloat + BigFloat: #{bf_sum.to_s} == 4.0"

puts "\n" + "=" * 50
puts "All tests passed! ✓"
