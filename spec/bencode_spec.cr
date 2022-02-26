require "./spec_helper"

describe Bencode do
  # Encoder
  it "encodes spam" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode("spam")
    io.to_s.should eq("4:spam")
  end

  it "encodes empty string" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode("")
    io.to_s.should eq("0:")
  end

  it "encodes string with punctuation" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(%q[So she called softly after it, "Mouse dear! Do come back again])
    io.to_s.should eq(%q[62:So she called softly after it, "Mouse dear! Do come back again])
  end

  it "encodes string with newline" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(%Q[So she called softly after it, "Mouse dear! Do come back again, and we\nwon't talk about cats or dogs either, if you don't like them!"])
    io.to_s.should eq(%Q[133:So she called softly after it, "Mouse dear! Do come back again, and we\nwon't talk about cats or dogs either, if you don't like them!"])
  end

  it "encodes a unicode string of 1 codepoint" do
    s = Bencode.encode("你")
    s.to_s.should eq("3:你")
  end

  it "encodes an emoji" do
    s = Bencode.encode("🕴️")
    s.to_s.should eq("7:🕴️")
  end

  it "encodes string using Bencode.encode" do
    s = Bencode.encode("spam")
    s.to_s.should eq("4:spam")
  end

  it "encodes an integer" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(2)
    io.to_s.should eq("i2e")
  end

  it "encodes a zero" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(0)
    io.to_s.should eq("i0e")
  end

  it "encodes a 32-bit integer" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(123456)
    io.to_s.should eq("i123456e")
  end

  it "encodes a 64-bit integer" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(123456789000)
    io.to_s.should eq("i123456789000e")
  end

  it "encodes a negative integer" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(-4501)
    io.to_s.should eq("i-4501e")
  end

  it "encodes an integer using Bencode.encode" do
    s = Bencode.encode(3)
    s.to_s.should eq("i3e")
  end

  it "encodes a negative integer using Bencode.encode" do
    s = Bencode.encode(-3)
    s.to_s.should eq("i-3e")
  end

  it "encodes a list of strings" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(%w[spam eggs])
    io.to_s.should eq("l4:spam4:eggse")
  end

  it "encodes an empty list" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(Array(String).new)
    io.to_s.should eq("le")
  end

  it "encodes a list of integers" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode([1, 2, 3, 4])
    io.to_s.should eq("li1ei2ei3ei4ee")
  end

  it "encodes a list of integers and strings" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(["1", 2, "3", 4, "foo"])
    io.to_s.should eq("l1:1i2e1:3i4e3:fooe")
  end

  it "encodes a list of lists of integers" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode([[1, 2, 3, 4], [9, 8, 7, 6]])
    io.to_s.should eq("lli1ei2ei3ei4eeli9ei8ei7ei6eee")
  end

  it "encodes a list using bencode.encode" do
    s = Bencode.encode([1, 2, 3])
    s.to_s.should eq("li1ei2ei3ee")
  end

  it "encodes an empty dictionary" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(Hash(String, String).new)
    io.to_s.should eq("de")
  end

  it "encodes a dictionary" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode({"spam" => "eggs", "cow" => "moo"})
    io.to_s.should eq("d3:cow3:moo4:spam4:eggse")
  end

  it "encodes a dictionary with list as value" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode({"spam" => ["a", "b"]})
    io.to_s.should eq("d4:spaml1:a1:bee")
  end

  it "encodes a dictionary from the spec" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode({"publisher" => "bob", "publisher-webpage" => "www.example.com", "publisher.location" => "home"})
    io.to_s.should eq("d9:publisher3:bob17:publisher-webpage15:www.example.com18:publisher.location4:homee")
  end

  it "encodes a dictionary using bencode.encode" do
    s = Bencode.encode({"spam" => "eggs", "cow" => "moo"})
    s.to_s.should eq("d3:cow3:moo4:spam4:eggse")
  end

  # Decoder

  it "raises when decoding empty string" do
    expect_raises IO::EOFError do
      input = IO::Memory.new("")
      decoder = Bencode::Decoder.new(input)
      decoder.read
    end
  end

  it "what happen" do
    input = IO::Memory.new("\x8F3e")
    decoder = Bencode::Decoder.new(input)
    expect_raises IO::Error, "Expecting 'i' when reading integer. Got '\u{8f}' (\\u{8f})" do
      i = decoder.read_integer
    end
  end

  it "raise when decoding an integer but first character isn't i" do
    input = IO::Memory.new("3e")
    decoder = Bencode::Decoder.new(input)
    expect_raises Bencode::Error do
      i = decoder.read_integer
    end
  end

  it "decodes an integer" do
    input = IO::Memory.new("i3e")
    decoder = Bencode::Decoder.new(input)
    i = decoder.read_integer
    i.should eq(3)
  end

  it "decodes a negative integer" do
    input = IO::Memory.new("i-3e")
    decoder = Bencode::Decoder.new(input)
    i = decoder.read_integer
    i.should eq(-3)
  end

  it "decoding negative zero is not allowed" do
    input = IO::Memory.new("i-0e")
    decoder = Bencode::Decoder.new(input)
    expect_raises Bencode::Error do
      i = decoder.read_integer
    end
  end

  it "decoding integer that starts with zero is not allowed" do
    input = IO::Memory.new("i03e")
    decoder = Bencode::Decoder.new(input)
    expect_raises Bencode::Error do
      i = decoder.read_integer
    end
  end

  it "decoding integer, reach eof" do
    input = IO::Memory.new("i12")
    decoder = Bencode::Decoder.new(input)
    expect_raises IO::EOFError do
      i = decoder.read_integer
    end
  end

  it "decodes a string, reach eof: no colon" do
    input = IO::Memory.new("12")
    decoder = Bencode::Decoder.new(input)
    expect_raises IO::EOFError do
      decoder.read_string
    end
  end

  it "decodes a string, reach eof: not enough bytes" do
    input = IO::Memory.new("12:spam")
    decoder = Bencode::Decoder.new(input)
    expect_raises IO::EOFError, "EOF while reading string of length #{12}" do
      decoder.read_string
    end

    input = IO::Memory.new("9:spam")
    decoder = Bencode::Decoder.new(input)
    expect_raises IO::EOFError, "EOF while reading string of length #{9}" do
      decoder.read_string
    end
  end

  it "decodes the empty string" do
    input = IO::Memory.new("0:")
    decoder = Bencode::Decoder.new(input)
    s = decoder.read_string
    s.should eq("")
  end

  it "decodes a spam string" do
    input = IO::Memory.new("4:spam")
    decoder = Bencode::Decoder.new(input)
    s = decoder.read_string
    s.should eq("spam")
  end

  it "decodes an empty list" do
    input = IO::Memory.new("le")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq([] of Bencode::Type)
  end

  it "decodes a list of one integer" do
    input = IO::Memory.new("li3ee")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq([3])
  end

  it "decodes a list of multiple integers" do
    input = IO::Memory.new("li3ei4ei-2ei100ee")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq([3, 4, -2, 100])
  end

  it "decodes a list of one string" do
    input = IO::Memory.new("l4:spame")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq(["spam"])
  end

  it "decodes a list of multiple strings" do
    input = IO::Memory.new("l4:spam4:eggs16:with space charse")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq(["spam", "eggs", "with space chars"])
  end

  it "decodes a list of integers and strings" do
    input = IO::Memory.new("li5e4:spame")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq([5, "spam"])
  end

  it "decodes a list of lists of integers" do
    input = IO::Memory.new("lli3ei5eeli10ei-200eee")
    decoder = Bencode::Decoder.new(input)
    lst = decoder.read_list
    lst.should eq([[3, 5], [10, -200]])
  end

  it "decodes an empty dictionary" do
    input = IO::Memory.new("de")
    decoder = Bencode::Decoder.new(input)
    dict = decoder.read_dictionary
    dict.should eq({} of String => Bencode::Type)
  end

  it "decodes a dictionary" do
    input = IO::Memory.new("d3:bar4:spam3:fooi42ee")
    decoder = Bencode::Decoder.new(input)
    dict = decoder.read_dictionary
    dict.should eq({"foo" => 42, "bar" => "spam"})
  end

  it "decodes a complicated dictionary" do
    input = IO::Memory.new("d9:publisher3:bob17:publisher-webpage15:www.example.com18:publisher.location4:homee")
    decoder = Bencode::Decoder.new(input)
    dict = decoder.read_dictionary
    dict.should eq({"publisher" => "bob", "publisher-webpage" => "www.example.com", "publisher.location" => "home"})
  end
end
