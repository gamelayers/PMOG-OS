# Patches from http://blog.pluron.com/2008/01/ruby-on-rails-i.html
module Benchmark
    def realtime
        r0 = Time.now
        yield
        r1 = Time.now
        r1.to_f - r0.to_f
    end
    module_function :realtime
end

class BigDecimal
    alias_method :eq_without_boolean_comparison, :==
    def eq_with_boolean_comparison(other)
        return false if [FalseClass, TrueClass].include? other.class
        eq_without_boolean_comparison(other)
    end
    alias_method :==, :eq_with_boolean_comparison
end