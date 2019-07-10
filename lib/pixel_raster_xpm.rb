#! /usr/bin/env ruby

module PixelRaster

  # This module holds the (old) code used for +xpm2tikz+.
  # The implementation is very hands-on, only gives a black and white raster
  # representation as tikz and may not work on more complex xpm files.
  # The only advantage compared to +img2pixel+ is that it works without
  # the +RMagick+ gem (which may be somehow complicated to install on some
  # systems).
  module XPM2TIKZ
    # Read an xpm file.
    #
    # This is not very robust but assumes a straight forward file format
    # without color/grayscale etc being mixed.
    #
    # @param filename [String] the file to read
    # @return [Array<Array<String>>] two dimensional array with color codes
    def read_xpm(filename)
      lines = File.readlines(filename)
      lines.shift # get rid of  /* XPM */
      lines.shift # get rid of  static char * ...[] = {
      meta = lines.shift.scan(/[0-9]+/)
      n_x = meta[0].to_i
      n_y = meta[1].to_i
      n_of_colors = meta[2].to_i
      n_of_chars = meta[3].to_i
      
      colors = {}
      
      n_of_colors.times do
        lines.shift =~ /"(.{#{n_of_chars}})\s+([cgms]4?)\s+(.*?)"/
        colors[$1] = $3
      end
      
      (1..n_y).collect do
        lines.shift[1..n_x].scan(/.{#{n_of_chars}}/).collect { |c| colors[c] }
      end
    end

    # Create a tikzpicture from a xpm file (see #read_xpm for restrictions).
    #
    # @param filename [String] the file to read
    # @param prefix [String] the prefix of the tikz node style name
    # @return [String] the tikzpicture code
    # @see #read_xpm
    def xpm2tikz(filename, prefix="n")
      xpm = read_xpm(filename)
      "\\begin{tikzpicture}[yscale=-1]
  \\draw[step=1,help lines] (0,0) grid (#{xpm.first.length},#{xpm.length});
    " + xpm.each_with_index.collect { |row,r|
      row.each_with_index.collect { |color,c|
        cc = color=='#FFFFFF' ? '0' : '1'
        "\\node[#{prefix+cc}] at (#{c+0.5},#{r+0.5}) {#{cc}};"
      }.join("\n")
    }.join("\n") + "
\\end{tikzpicture}
  "
    end
  end
end

  
