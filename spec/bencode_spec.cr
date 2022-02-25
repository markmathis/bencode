require "./spec_helper"

describe Bencode do
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
    encoder.encode(%q[So she called softly after it, “Mouse dear! Do come back again])
    io.to_s.should eq(%q[62:So she called softly after it, “Mouse dear! Do come back again])
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
    encoder.encode([1,2,3,4])
    io.to_s.should eq("li1ei2ei3ei4ee")
  end

  it "encodes a list of integers and strings" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode(["1",2,"3",4,"foo"])
    io.to_s.should eq("l1:1i2e1:3i4e3:fooe")
  end

  it "encodes a list of lists of integers" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode([[1,2,3,4],[9,8,7,6]])
    io.to_s.should eq("lli1ei2ei3ei4eeli9ei8ei7ei6eee")
  end

  it "encodes a list using bencode.encode" do
    s = Bencode.encode([1,2,3])
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
    encoder.encode({"spam"=>"eggs","cow"=>"moo"})
    io.to_s.should eq("d3:cow3:moo4:spam4:eggse")
  end

  it "encodes a dictionary with list as value" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode({"spam"=>["a", "b"]})
    io.to_s.should eq("d4:spaml1:a1:bee")
  end

  it "encodes a dictionary from the spec" do
    io = IO::Memory.new
    encoder = Bencode::Encoder.new io
    encoder.encode({ "publisher" => "bob", "publisher-webpage" => "www.example.com", "publisher.location" => "home" } )
    io.to_s.should eq("d9:publisher3:bob17:publisher-webpage15:www.example.com18:publisher.location4:homee")
  end

  it "encodes a dictionary using bencode.encode" do
    s = Bencode.encode({"spam"=>"eggs","cow"=>"moo"})
    s.to_s.should eq("d3:cow3:moo4:spam4:eggse")
  end
end
