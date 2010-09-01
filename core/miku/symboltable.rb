require 'error'

module MIKU
  class SymbolTable < Hash

    # :caller-file "呼び出し元ファイル名"
    # :caller-line 行
    # :caller-function :関数名
    def initialize(parent = nil, default = {})
      if parent
        @parent = parent
      else
        @parent = SymbolTable.defaults
        def self.ancestor
          self end end
      merge(default)
      super(){ |this, key| @parent[key.to_sym] } end

    def ancestor
      @parent.ancestor end

    def []=(key, val)
      if not(key.is_a?(Symbol)) then
        raise ExceptionDelegator.new("#{key.inspect} に値を代入しようとしました", TypeError) end
      super(key, val) end

    def bind(key, val, setfunc)
      cons = self[key]
      if cons
        cons.method(setfunc).call(val)
      else
        self[key] = nil.method(setfunc).call(val) end end

    def set(key, val)
      if not(key.is_a?(Symbol)) then
        raise ExceptionDelegator.new("#{key.inspect} に値を代入しようとしました", TypeError) end
      bind(key.to_sym, val, :setcar) end

    def defun(key, val)
      if not(key.is_a?(Symbol)) then
        raise ExceptionDelegator.new("#{key.inspect} に値を代入しようとしました", TypeError) end
      bind(key.to_sym, val, :setcdr) end

    def miracle_binding(keys, values)
      result = SymbolTable.new(self)
      count = 0
      values.each{ |val|
        if keys[count].is_a? List
          if keys[count][0] == :optional
            result[keys[count][1]] = Cons.new(values[count, values.size])
            return result end
        else
          result[keys[count]] = Cons.new(val) end
        keys[count] }
      result end

    def self.defsform(fn=nil, *other)
      return [] if fn == nil
      [fn , Cons.new(nil, Primitive.new(fn))] + defsform(*other) end

    def self.defun(fn=nil, *other)
      return [] if fn == nil
      [fn , Cons.new(nil, fn)] + defun(*other) end

    def self.consts
      Module.constants.map{ |c| [c.to_sym, Cons.new(eval(c))] }.inject([]){ |a, b| a + b } end

    def self.defaults
      Hash[*(defsform(:cons, :eq, :listp, :set, :function, :value, :quote, :eval, :list,
                      :if, :backquote, :macro) +
             [:lambda , Cons.new(nil, Primitive.new(:negi))] +
             [:def , Cons.new(nil, Primitive.new(:defun))] + consts)] end
  end
end