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
    def self.command_line(argv=ARGV, stdout=$stdout, stderr=$stderr)
      outfile = nil
      outdir = nil
      outmode = :both
      empty_suffix = '-empty'
      filled_suffix = '-filled'
      params = {
                type:     :svg,
                bg_color: 'white'
               }

      if argv.length == 0 # no argument given
        argv << '-h'      # give the help text
      end
      
      begin
        OptionParser.new do |p|
          p.accept(Symbol) { |s| s.downcase.to_sym }
          
          p.banner = "Convert image(s) to a pixel representation."
          
          p.separator ""
          p.separator "Usage: #{$0} [options] INFILE [INFILE…]"
          p.separator ""
          p.separator "For each INFILE two output files are written for the empty and filled version"
          p.separator "(but see --mode)."
          p.separator ""
          p.separator "With “-O OUTFILE” all images are output to OUTFILE."
          p.separator "Caveat: having several <svg>-elements concatenated in one file"
          p.separator "may not be supported by your viewer."
          p.separator ""
          p.separator "Options:"
          p.on_tail("-h", "--help", "Show this help message and exit.") do
            stdout.puts p
            exit
          end
          
          p.on("-V", "--version", "Show version information and exit.") do
            stdout.puts File.read(File.join(File.dirname(__FILE__),'..','VERSION'))
            exit
          end
          
          p.on('-O', '--output FILENAME',
               'Write output to FILENAME (“-” for STDOUT).',
               'If this option is given, all images',
               'are written to the same file.',
               'If this is given, “-d” is ignored.') do |filename|
            outfile = filename
          end
          
          p.on("-#", "--nr-of-colors N", Numeric,
               "Number of colors for the final image.") do |n|
            params[:nr_of_colors] = n
          end

          p.on('-c', '--bg-color COLOR',
               "Background-color for empty version.",
               "SVG color name. May be “none”.",
               "Ignored for --type tikz.",
               "Default: #{params[:bg_color]}") do |color|
            params[:bg_color] = color
          end
          
          p.on('-t', '--type TYPE', Symbol,
               'The output type (svg or tikz).',
               "Default: #{params[:type]}") do |type|
            [:svg,:tikz].include?(type) or
              p.abort("unknown output type #{type}")
            params[:type] = type
          end
          
          p.on('-m', '--mode MODE', Symbol,
               'Output mode (both, empty, filled).',
               "Default: #{outmode}") do |mode|
            [:both,:empty,:filled].include?(mode) or
              p.abort("unknown mode #{mode}")
            outmode = mode
          end

          p.on('-r', '--resize [SPEC]',
               'Resize image to given dimensions.',
               'See ImageMagick resize specification.') do |spec|
            params[:resize] = spec
          end
          
          p.on('-l','--light2dark',
               'Color numbering direction.',
               'Default: dark2light (unless 2 color imgs)') do
            params[:light2dark] = true
          end

          p.on('-L','--dark2light',
               'Color numbering direction.',
               'Default: dark2light, (unless 2 color imgs)') do
            params[:light2dark] = false
          end

          p.on('-d', '--dir DIR',
               'Directory for output files.',
               'Must exist and be writeable.',
               "Default: same as INFILE") do |dir|
            outdir = dir
          end
        end.parse!(argv)
      rescue OptionParser::ParseError => pe
        stderr.puts pe
        exit 22   # Errno::EINVAL::Errno (but may not exist on all platforms)
      end


      MagickConverter.new(**params) do |c|
        if outfile == '-' # Write everything to standard out
          argv.each do |infile|
            stdout << c.convert(infile, mode: :empty)  unless outmode==:filled
            stdout << c.convert(infile, mode: :filled) unless outmode==:empty
          end
        elsif outfile # an outfile is given, so write everything in this file
          File.open(outfile, 'w') do |out|
            argv.each do |infile|
              out << c.convert(infile, mode: :empty)
              out << c.convert(infile, mode: :filled)
            end
          end
        else
          argv.each do |infile|
            # if no outfile is given we generate the filename from the infile
            base_out = File.join(outdir || File.dirname(infile),
                                 File.basename(infile, '.*'))

            empty_out = base_out + empty_suffix + '.' + params[:type].to_s
            filled_out = base_out + filled_suffix + '.' + params[:type].to_s
            unless outmode==:filled
              File.open(empty_out,"w") do |out|
                out << c.convert(infile, mode: :empty)
              end
            end
            unless outmode==:empty
              File.open(filled_out,"w") do |out|
                out << c.convert(infile, mode: :filled)
              end
            end
          end
        end
      end
    end
  end
end
