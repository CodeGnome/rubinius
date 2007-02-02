class String
  alias_method :to_str, :to_s

  def to_sexp_full(name, line, newlines)
    Ruby.primitive :string_to_sexp
  end

  def to_sexp(name="(eval)",line=1,newlines=true)
    out = to_sexp_full(name, line, newlines)
    if out.kind_of? Tuple
      exc = SyntaxError.new out.at(0)
      exc.import_position out.at(1), out.at(2)
      raise exc
    end
    return out
  end

  def *(num)
    str = []
    num.times { str << self }
    return str.join("")
  end

  def reverse
    str = ""
    i = @bytes - 1
    while i >= 0
      str << self[i,1]
      i -= 1
    end
    return str
  end

  def reverse!
    sd = self.reverse
    @data = sd.data
    @bytes = sd.size
    return self
  end

  def strip
    r = /\s*([^\s](.*[^\s])?)\s*/m
    m = r.match(self)
    return '' unless m
    return m.captures[0]
  end
  
  def strip!
    sd = self.strip
    @data = sd.data
    @bytes = sd.size
    return self
  end

  def =~(pattern)
    m = pattern.match(self)
    m ? m.full.at(0) : nil 
  end
  
  def include?(arg)
    if arg.is_a? Fixnum
      @data.each { |b|  return true if b == arg }
      return false
    elsif arg.is_a? String
      return (self.index(arg) != nil) 
    else
      raise ArgumentError.new("String#include? cannot accept #{arg.class} objects")
    end
  end

  def index(arg, offset = nil )
    if arg.is_a? Fixnum
      i = 0
      @data.each { |b| return i if b == arg; i += 1 }
    elsif arg.is_a? String
      idx = 0
      if offset
        if offset >= 0
          return nil if offset >= self.size
          idx = offset
        else
          return nil if (1-offset) >= self.size
          idx = self.size + offset
        end
      end
      argsize = arg.size
      max = self.size - argsize
      if max >= 0 and argsize > 0
        idx.upto(max) do |i|
          if @data.get_byte(i) == arg.data.get_byte(0)
            return i if substring(i,argsize) == arg
          end
        end
      end
    elsif arg.is_a? Regexp
      idx = offset ? offset : 0
      mstr = self[idx..-1]
      offset = self.size - mstr.size
      m = arg.match(mstr)
      if m
        return offset + m.begin(0)
      end
      return nil
    else
      raise ArgumentError.new("String#index cannot accept #{arg.class} objects")
    end
    return nil 
  end

  def [](arg, len = nil)
    if len
      len = len.to_i
      return nil if len < 0
    end

    if arg.is_a? String
      unless len.nil?
        raise ArgumentError.new("String#[] got incorrect arguments.") # TODO: Make this helpful.
      end
      return (self.include?(arg) ? arg.dup : nil)
    elsif arg.respond_to? :match
      m = arg.match(self)
      return m[len.to_i] if m && len
      return m[0] if m
      return nil
    elsif arg.respond_to?(:first) and arg.respond_to?(:last)
      from = arg.first
      to = arg.last
      to = to - 1 if arg.respond_to?(:exclude_end?) && arg.exclude_end?
      size = self.size
      from = from + size if from < 0
      to = to + size if to < 0
      len = to - from + 1
      self[from, len]
      
    elsif arg and arg.respond_to?(:to_i)
      arg = arg.to_i
      size = self.size
      arg = arg + size if arg < 0
      if 0 <= arg && arg < size
        if len
          len = size - arg if arg + len >= size
          substring(arg, len)
        else
          @data.get_byte(arg)
        end
      else # invalid start index
        len ? "" : nil
      end
    else
      raise ArgumentError.new("String#[] cannot accept #{arg.class} objects")
    end
  end

  alias_method :slice, :[]
  
  def to_f
    Ruby.primitive :string_to_f
  end
  
  def match(pattern)
    pattern = Regexp.new(pattern) unless Regexp === pattern
    pattern.match(self)
  end
end
