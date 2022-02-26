# `Bencode` module provides utilities to encode and decode bencoded values
module Bencode
  VERSION = "0.1.0"

  alias Type = Bytes|String|Int64|Array(Type)|Hash(String, Type)

  class Error < IO::Error
  end

  def self.encode(value)
    io = IO::Memory.new
    Encoder.new(io).encode(value)
    io.to_s
  end

  struct Encoder
    def initialize(@out : IO)
    end

    def encode(i : Int)
      @out << 'i'
      i.to_s @out
      @out << 'e'
    end

    def encode(items : Array)
      @out << 'l'
      items.each { |i| encode(i) }
      @out << 'e'
    end

    def encode(s : String)
      encode s.to_slice
    end

    def encode(s : Bytes)
      @out << s.size
      @out << ':'
      @out.write s
    end

    def encode(h : Hash(String, Type))
      @out << 'd'
      h.keys.sort.each do |k|
        encode k
        encode h[k]
      end
      @out << 'e'
    end
  end

  struct Decoder
    @buffer : UInt8?

    def initialize(@in : IO)
    end

    private def read_byte : UInt8
      if @buffer
        tmp = @buffer.not_nil!
        @buffer = nil
        return tmp
      end
      byte = @in.read_byte
      raise IO::EOFError.new unless byte
      byte
    end

    private def push_back(byte)
      @buffer = byte
    end

    private def read_until(byte)
      String.build do |st|
        until byte === (c = read_byte)
          st << c.chr
        end
      end
    end

    def read_integer
      c = read_byte
      unless 'i' === c
        hex = "\\u{#{c.to_s(16)}}"
          raise Error.new("Expecting 'i' when reading integer. Got '#{c.chr}' (#{hex})")
      end

      s = read_until('e')

      raise Error.new("negative zero not allowed: #{s}") if s.starts_with?("-0")
      raise Error.new("integer cannot start with 0: #{s}") if s.starts_with?("0") && s.size > 1

      i = s.to_i64

    end

    def read_list
      c = read_byte
      unless 'l' === c
        hex = "\\u{#{c.to_s(16)}}"
          raise Error.new("Expecting 'l' when reading list. Got '#{c.chr}' (#{hex})")
      end

      result = Array(Type).new
      until 'e' === (c = read_byte)
        push_back c
        item = read
        result << item
      end
      result
    end

    def read_dictionary
      c = read_byte
      unless 'd' === c
        hex = "\\u{#{c.to_s(16)}}"
          raise Error.new("Expecting 'd' when reading dictionary. Got '#{c.chr}' (#{hex})")
      end

      result = Hash(String, Type).new
      until 'e' === (c = read_byte)
        push_back c
        key = read_string
        value = read
        result[key] = value
      end
      result
    end

    def read_string
      lenstr = read_until(':')

      raise Error.new("string length cannot be negative: #{lenstr}") if lenstr.starts_with?("-")
      raise Error.new("string length cannot start with 0: #{lenstr}") if lenstr.starts_with?("0") && lenstr.size > 1

      len = lenstr.to_i
      return "" if len.zero?

      buf = IO::Memory.new len
      nread = IO.copy @in, buf, len

      raise IO::EOFError.new("EOF while reading string of length #{len}") if nread < len

      buf.to_s
    end

    def read
      c = read_byte
      push_back c

      case c
      when 'i'
        read_integer
      when 'd'
        read_dictionary
      when 'l'
        read_list
      else
        read_string
      end
    end


  end
end
