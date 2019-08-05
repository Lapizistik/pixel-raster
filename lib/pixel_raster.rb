#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rmagick'

module PixelRaster
  class MagickConverter

    attr_reader :nr_of_colors, :bg_color, :resize, :light2dark, :type

    # The converter is initialized with the constraints
    # for the images to be processed.
    #
    # Any image must have a color index (palette), this is enforced.
    # It is not that useful to have more than 10 colors or more than 30x30
    # pixels, but this is only enforced if the corresponding parameters
    # are given.
    # @see #read_image
    #
    # @param nr_of_colors      maximum number of colors for the color index
    # @param bg_color          background color for empty pixel image (svg)
    # @param resize [String]   resize string (see ImageMagick resize option)
    # @param light2dark [Boolean] if true 0 is the lightest color
    # @param type [:svg|:tikz] 
    def initialize(nr_of_colors: nil, bg_color: 'white',
                   resize: nil, light2dark: nil,
                   type: :svg)
      @nr_of_colors = nr_of_colors
      @bg_color = bg_color
      @resize = resize
      @light2dark = light2dark
      @type = type
      yield(self) if block_given?
    end
    
    # Reads an image using RMagick and adjusts size and palette.
    # As we need an indexed image we check and create one if neccessary.
    #
    # @see #initialize
    # @param filename          read this file
    # @return [Magick::Image] the (processed) image 
    def read_image(filename)
      # We assume each file includes exactly one image
      image = Magick::Image.read(filename).first
      
      # on demand we resize the image
      # the API is kinda complicated here:
      # change_geometry computes the cols and rows from the given resize string
      # and yields the given block with these values
      if @resize
        image.change_geometry(@resize) do |cols, rows, i|
          image = i.resize!(cols, rows)
        end
      end
      
      # on demand we reduce the number of colors
      if @nr_of_colors
        image = image.quantize(@nr_of_colors)
      else
        # If the image does not have a palette/color index (and no number of
        # columns was given) we create one with 2 colors. 
        unless image.palette?
          image = image.quantize(2)
        end
      end
      # finally we remove duplicate colors.
      image.compress_colormap!

      return image
    end

    # Wrapper for the converter methods.
    #
    # @param mode [:empty|:filled] the output mode
    # @param type [:svg|:tikz] the output type
    # @see #image2tikz
    # @see #image2svg
    def convert(filename, mode:, type: @type)
      img = read_image(filename)
      case type
      when :tikz
        image2tikz(img, prefix: mode==:empty ? 'n' : 'y')
      when :svg
        image2svg(img, mode: mode)
      else
        raise "unknown output type #{type}"
      end
    end
    
    
    # create a tikz pixel representation of an image.
    #
    # @param img [Magick::Image] the image
    # @param prefix [String] node class prefix (to distinguish empty and filled mode)
    def image2tikz(img, prefix: "n")
      
      colormap = compute_colormap(img)
    
      tikz = "  \\begin{tikzpicture}[yscale=-1]
    \\draw[step=1,help lines] (0,0) grid (#{img.columns},#{img.rows});
"
      img.each_pixel do |p, c, r|
        cc = colormap[p]
        tikz << "    \\node[#{prefix}#{cc}] at (#{c+0.5},#{r+0.5}) {#{cc}};\n"
      end
      tikz << "
  \\end{tikzpicture}

"
      tikz
    end

    # create a svg pixel representation of an image.
    #
    # @param img [Magick::Image] the image
    # @param mode [:empty|:filled] fill mode
    def image2svg(img, mode: :empty)
      
      colormap = compute_colormap(img)

      # ToDo: make these flexible:
      xw = 20
      yh = 20
      xwt = 10
      yht = 15

      # We create the SVG directly by string
      svg = %Q'<svg xmlns="http://www.w3.org/2000/svg">
   <style>
     .pixel {
       stroke : black;
       stroke-width : 1;
'
      if mode == :empty
        svg << "      
       fill: #{@bg_color};
"
      end
      svg << '
     }
'
      if mode == :filled
        colormap.each do |k,v|
          color = k.to_color(Magick::AllCompliance,false, 8, true)
          textcolor = k.to_hsla[2] > 50 ? 'black' : 'white'
          svg << %Q{    .p#{v} { fill: #{color}; }\n}
        
          svg << %Q{    .t#{v} { fill: #{textcolor}; }\n}
        end
      end
      svg << %Q{    </style>\n}
      img.each_pixel do |p, c, r|
        cc = colormap[p]
        svg << %Q{  <rect x="#{c*xw}" y="#{r*yh}" width="#{xw}" height="#{yh}" class="pixel p#{cc}" />\n}
        svg << %Q{  <text x="#{c*xw+xwt}" y="#{r*yh+yht}" text-anchor="middle" class="t#{cc}">#{cc}</text>\n}
      end
      svg << "</svg>\n"
      svg
    end

    # compute an ordered colormap for the image
    # @param img [Magick::Image] the image
    # @param light2dark [Boolean] whether to invert the color map
    def compute_colormap(img, light2dark: @light2dark)
      # we create a colormap sorted from dark to light
      colormap= {};
      colors = img.color_histogram.map(&:first).sort_by(&:intensity)
      # at least for a black and white image having 0 as white and
      # 1 as black is more intuitive as you paint the pixels in black
      # which are set. This is different from the common internal
      # representation of images!
      # We therefore assume light2dark _unless_ it's a 2-color image
      # if it is not explicitely set:
      light2dark = colors.length == 2 if light2dark.nil?
      colors.reverse! if light2dark
      colors.each_with_index do |p,i|
        colormap[p]=i
      end
      return colormap
    end
  end
end


  
