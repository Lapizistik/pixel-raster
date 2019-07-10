#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pixel_raster_xpm'
require 'optparse'

module PixelRaster

  module XPM2TIKZ

    # Parse command line arguments (+ARGV+) and process accordingly
    #
    # See +xpm2tikz -h+ for a list of options.
    def command_line
      out = $stdout
      
      OptionParser.new do |parser|
        parser.banner = "\nConvert xpm image(s) to tikz. \n\nUsage: $0 [-O OUTFILE] INFILE [INFILE…]"
        
        parser.on("-h", "--help", "Show this help message") do
          puts parser
          exit
        end
        
        parser.on('-O', '--output FILENAME',
                  'write output to FILENAME (default: stdout)') do |filename|
          begin
            # We open the outfile here without ensuring it will be closed.
            # This is ok as we need it throughout the whole script runtime
            # and it will be closed on exit automatically.
            out = File.open(filename, 'w')
            
            # We could be more specific about catching errors, but we
            # exit the script anyway, and this may be different on different OSes.
          rescue StandardError => e
            warn "Could not open “#{filename}” for writing."
            warn e
            exit e.errno
          end
        end
      end.parse!
      
      ARGV.each do |filename|
        out << xpm2tikz(filename)
        out << "\n\\vfill\n\n"
        out << xpm2tikz(filename,'y')
        out << "\n\\vfill\n\n"
      end
    end
  end
end
