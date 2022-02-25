# `Bencode` module provides utilities to encode and decode bencoded values
module Bencode
  VERSION = "0.1.0"

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
          @out << s.size
          @out << ':'
          s.to_s @out
      end

      def encode(h : Hash(String, _))
          @out << 'd'
          h.keys.sort.each do |k|
              encode k
              encode h[k]
          end
          @out << 'e'
      end
  end
end
