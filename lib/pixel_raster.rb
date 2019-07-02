#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

begin
  require 'rmagick'
rescue LoadError => e
  warn <<EOM

Could not load “rmagick”.

Please install the RMagick gem or use “xpm2tikz” with xpm files as imput.

EOM
  exit 1
end

module PixelRaster
  class MagickConverter

    # The converter is initialized with the constraints like size
    # and number of colors for the images to be processed.
    #
    # Any image must have a color index (palette), this is enforced.
    # It is not that useful to have more than 10 colors or more than 30x30
    # pixels, but this is only enforced if the corresponding parameters
    # are given.
    # @see #read_image
    #
    # @param nr_of_colors      maximum number of colors for the color index
    # @param resize [String]   resize string (see ImageMagick resize option)
    # @param light2dark [Boolean] if true 0 is the lightest color
    def initialize(nr_of_colors: nil, resize: nil, light2dark: true)
      @nr_of_colors = nr_of_colors
      @resize = resize
      @light2dark = light2dark
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

    
    def image2tikz(img, prefix="n")
      
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

    def image2svg(img, outfile: nil, mode: :empty)
      
      colormap = compute_colormap(img)

      # ToDo: make these flexible:
      xw = 20
      yh = 20
      xwt = 10
      yht = 15

      # We create the SVG directly by string
      svg = %Q{<svg xmlns="http://www.w3.org/2000/svg">
   <style>
     .pixel {
       stroke : black;
       stroke-width : 1;
     }
}
      colormap.each do |k,v|
        color = k.to_color(Magick::AllCompliance,false, 8, true)
        textcolor = k.to_hsla[2] > 50 ? 'black' : 'white'
        svg << %Q{    .p#{v} { fill: #{color}; }\n}
        
        svg << %Q{    .t#{v} { fill: #{textcolor}; }\n}
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
    def compute_colormap(img)
      # we create a colormap sorted from dark to light
      colormap= {};
      colors = img.color_histogram.map(&:first).sort
      # at least for a black and white image having 0 as white and
      # 1 as black is more intuitive as you paint the pixels in black
      # which are set. This is different from the common internal
      # representation of images!
      colors.reverse! if @light2dark
      colors.each_with_index do |p,i|
        colormap[p]=i
      end
      return colormap
    end

    # replace the extension of +filename+ with +.svg+
    def svg_ext(filename)
      File.basename(filename,'.*') + '.svg'
    end
  end
end


  
