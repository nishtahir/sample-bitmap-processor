# TODO: Write documentation for `Image`
module Image
  VERSION = "0.1.0"

  struct Bitmap
    property header, width, height, bit_depth, color_table, data
  
    def initialize(
        @header : Slice(UInt8), 
        @width : UInt32, 
        @height : UInt32, 
        @bit_depth : UInt8, 
        @color_table : Slice(UInt8), 
        @data : Slice(UInt8))
    end

    def initialize(path : String)
      abort "file is missing", 1 if !File.file? path
      image_file = File.new path, "r"

      @header = Bytes.new(54)
      image_file.read(@header)

      @width = @header[18, 2].to_unsafe().as(UInt32*).value
      @height = @header[22, 2].to_unsafe().as(UInt32*).value
      @bit_depth = @header[28]
      
      @color_table = Bytes.new(1024)
      image_file.read(@color_table)
      
      @data = Bytes.new(@width * @height)
      image_file.read_fully(@data)
    end

    def invert()
      @data.map!{|x| 255_u8 - x }
    end

    def brighten(factor : UInt8)
      @data.map!{|x| 
        temp = x.to_u32 + factor.to_u32
        if(temp >= 255) 255_u8 else temp.to_u8 end
      }
    end

    def darken(factor : UInt8)
      @data.map!{|x| 
        temp = x.to_i32 - factor.to_i32
        if(temp <= 0) 0_u8 else temp.to_u8 end
      }
    end

    def threshold(threshold : UInt8)
      @data.map!{|x| x > threshold ? 255_u8 : 0_u8 }
    end

    # Incomplete
    def rotate()
      out = Bytes.new(@width * @height)
      arr = @data.to_a.in_groups_of(@width).rotate(@height).flatten()
      arr.each_with_index { |v, i|
        out[i] = v.as?(UInt8) || 0_u8
      }
      @data = out
    end

    def flip()
      @data.reverse!()
    end

    def write(path : String)
      output = File.open path, "w"

      io = IO::Memory.new
      io.write @header
      io.write @color_table
      io.write @data

      File.write(path, io.to_s)
    end
  end

  path = "lena512.bmp"

  bitmap = Bitmap.new(path)
  bitmap.rotate()
  # bitmap.darken(100)
  # bitmap.threshold(25)
  # bitmap.invert()
  bitmap.write("output.bmp")  
end
