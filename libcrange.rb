#!/usr/bin/ruby

require 'rubygems'
require 'ffi'

## http://www.dzone.com/snippets/getting-array-strings-char-ffi
class FFI::Pointer
  def read_array_of_string
    elements = []
    loc = self
    until ((element = loc.read_pointer).null?)
      elements << element.read_string
      loc += FFI::Type::POINTER.size
    end
    return elements
  end
end

class LibCRange
  extend FFI::Library
  ffi_lib "libcrange.so"
  attach_function 'range_easy_create', [:string], :pointer
  attach_function 'range_easy_expand', [:pointer, :string], :pointer
  attach_function 'range_easy_eval', [:pointer, :string], :string
  attach_function 'range_easy_compress', [:pointer, :string], :string
  attach_function 'range_easy_destroy', [:pointer], :int
  
  def initialize(conf=nil)
    @elr = LibCRange.range_easy_create(nil)
  end

  def expand(range_exp)
    return LibCRange.range_easy_expand(@elr, range_exp).read_array_of_string
  end
  def eval(range_exp)
    return LibCRange.range_easy_eval(@elr, range_exp)
  end
  def compress(nodes)
    # FIXME
  end
  def destroy
    return LibCRange.range_easy_destroy(@elr)
  end
end


if __FILE__ == $0

  elr = LibCRange.range_easy_create(nil)
  #elr = LibCRange.range_easy_create("/etc/range.conf")
  
  puts LibCRange.range_easy_eval(elr, "foo10..11,foo12")
  ret =  LibCRange.range_easy_expand(elr, "foo10..11,foo12")
  puts ret.read_array_of_string.inspect

  puts "and now, loop forever"

  loop do
    # this doesn't leak
    ret =  LibCRange.range_easy_expand(elr, "foo10..11,foo12")
    puts ret.read_array_of_string.inspect
    ret = LibCRange.range_easy_eval(elr, "foo10..11,foo12")
    puts ret.inspect


    # this currently leaks
    r = LibCRange.new()
    puts r.expand("bar100..200")
    puts r.eval("bar100..200")
    r.destroy
    GC.start
  end
end

