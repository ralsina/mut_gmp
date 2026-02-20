require "../src/mut_gmp/mp_z"
require "../src/mut_gmp/mp_q"
require "../src/mut_gmp/mp_f"

# Test that MutGMP doesn't break standard library BigInt operations
# This was broken before due to lib LibGMP shadowing

puts "Testing BigInt interoperability..."

# Test standard BigInt operations still work
a = BigInt.new(100)
b = BigInt.new(200)
c = a + b
puts "BigInt + BigInt works: #{c.to_s} == 300"

# Test MpZ with BigInt
mpz = MutGMP::MpZ.new(50)
mpz.add!(BigInt.new(25))
puts "MpZ.add!(BigInt) works: #{mpz.to_s} == 75"

# Test BigInt operations after using MutGMP
d = BigInt.new(1000)
e = BigInt.new(2000)
f = d * e
puts "BigInt * BigInt still works: #{f.to_s} == 2000000"

# Test MpQ interoperability
mpq1 = MutGMP::MpQ.new(1, 3)
mpq2 = MutGMP::MpQ.new(1, 6)
mpq1.add!(mpq2)
puts "MpQ.add!(MpQ) works: #{mpq1.to_s} == 1/2"

# Test BigRational still works
br1 = BigRational.new(1, 4)
br2 = BigRational.new(1, 4)
br3 = br1 + br2
puts "BigRational + BigRational works: #{br3.to_s} == 1/2"

# Test MpF interoperability
mpf1 = MutGMP::MpF.new(1.5)
mpf2 = MutGMP::MpF.new(2.5)
mpf1.add!(mpf2)
puts "MpF.add!(MpF) works: #{mpf1.to_s} == 4.0"

# Test BigFloat still works
bf1 = BigFloat.new(1.5)
bf2 = BigFloat.new(2.5)
bf3 = bf1 + bf2
puts "BigFloat + BigFloat works: #{bf3.to_s} == 4.0"

puts "\nAll interoperability tests passed!"
puts "MutGMP does NOT shadow standard library functions."
