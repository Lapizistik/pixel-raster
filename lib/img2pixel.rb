#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pixel_raster'
require 'optparse'

# Base module
module PixelRaster

  class MagickConverter

    # Parse command line arguments (+ARGV+) and execute accordingly
    #
    # See +img2pixel -h+ for a list of options.
    def self.command_line
      outfiles = []
      params = {
                type: 'svg'
               }
      
      OptionParser.new do |parser|
        parser.banner = "
Convert image(s) to a pixel representation.

Usage: $0 [options] INFILE [INFILE…]"

        parser.on("-h", "--help", "Show this help message") do
          puts parser
          exit
        end

        parser.on("-V", "--version", "Show version information and exit") do
          puts File.read(File.join(File.dirname(__FILE__),'..','VERSION'))
          exit
        end
        
        parser.on('-O', '--output FILENAME',
                  'write output to FILENAME (“-” for STDOUT).',
                  'May be given several times',
                  '(once for each input file)') do |filename|
          outfiles << filename
        end

        parser.on("-#", "--nr-of-colors N",
                  "number of colors for the final image") do |n|
          params[:nr_of_colors] = n
        end

        parser.on('-t', '--type TYPE',
                  'the output type (svg or tikz)') do |type|
          type.downcase!
          type =~ /^(?:svg|tikz)$/ or raise "unknown output type #{type}"
          params[:type] = type
        end
      end.parse!

      converter = MagickConverter.new(**params)
            
      ARGV.zip(outfiles).each do |infile, outfile|
        # if no outfile is given we generate the filename from the infile
        outfile ||= infile.sub(/\.[^.\/]*$/,'') + '.' + params[:type]
        File.open(outfile,"w") do |out|
          out << converter.convert(infile, mode: :empty)
          # TODO!! mode: :full, STDOUT, onefile-mode …
        end
      end
    end
  end
end
