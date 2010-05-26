require 'list'

class Array
  include HatsuneLisp::List

  def car
    self.first
  end

  def cdr
    self[1..self.size]
  end

  def setcar(val)
    result = val.clone
    result[0] = val
    result.freeze
  end

  def setcdr(val)
    Cons.new(self.car, val)
  end

  def unparse(start=true)
    result = ''
    result = '(' if start
    result + self.map{ |n| HatsuneLisp.unparse(n) }.join(' ') + ')'
  end

end