# -*- coding: utf-8 -*-
require "minitest/autorun"
require "minitest/spec"
require 'minitest/rg'
require 'img2pixel'
require 'stringio'

require_relative('helper')

include PixelRaster


describe MagickConverter do
  
  it 'should convert an image to svg' do
    imgfiles('9colors.png', copy: true) do |files, tmpdir|
      MagickConverter.command_line(files)
      emptyfile  = File.join(tmpdir, '9colors-empty.svg')
      filledfile = File.join(tmpdir, '9colors-filled.svg')
      assert File.exist?(emptyfile), "Expected “#{emptyfile}” to exist"
      assert File.exist?(filledfile), "Expected “#{filledfile}” to exist"
      
      emptycontent  = File.read(emptyfile)
      filledcontent = File.read(filledfile)
      
      assert_match(/\<svg/,emptycontent)
      assert_match(/\<svg/,filledcontent)
      
      assert_match(/pixel \{[^{]*fill: *white;/, emptycontent)
      refute_match(/pixel \{[^{]*fill: *white;/, filledcontent)
    end
  end

  it 'should respect the destination directory' do
    imgfiles('9colors.png') do |files, tmpdir|
      MagickConverter.command_line([*files, '-d', tmpdir])
      emptyfile  = File.join(tmpdir, '9colors-empty.svg')
      filledfile = File.join(tmpdir, '9colors-filled.svg')
      assert File.exist?(emptyfile), "Expected “#{emptyfile}” to exist"
      assert File.exist?(filledfile), "Expected “#{filledfile}” to exist"
    end
  end

  it 'should convert a bunch of images to svg' do
    imgfiles = ['herz.xpm', 'brief.png']
    imgfiles(*imgfiles) do |files, tmpdir|
      MagickConverter.command_line([*files, '-d', tmpdir])
      ['herz','brief'].each do |base|
        emptyfile  = File.join(tmpdir, "#{base}-empty.svg")
        filledfile = File.join(tmpdir, "#{base}-filled.svg")
        assert File.exist?(emptyfile), "Expected “#{emptyfile}” to exist"
        assert File.exist?(filledfile), "Expected “#{filledfile}” to exist"

        emptycontent  = File.read(emptyfile)
        filledcontent = File.read(filledfile)
        
        assert_match(/\<svg/,emptycontent)
        assert_match(/\<svg/,filledcontent)
        
        assert_match(/pixel \{[^{]*fill: *white;/, emptycontent)
        refute_match(/pixel \{[^{]*fill: *white;/, filledcontent)
      end
    end
  end

  it 'should write to the given output file' do
    imgfiles('9colors.png') do |files, tmpdir|    
      MagickConverter.command_line([*files, '-O', File.join(tmpdir, 'out.svg')])
      outfile  = File.join(tmpdir, 'out.svg')
      assert File.exist?(outfile), "Expected “#{outfile}” to exist"
    end
  end
  
  it 'should write to stdout' do
    o = StringIO.new("",'w')
    MagickConverter.command_line([art_path('brief.xpm'), '-O', '-'], o)
    assert_match(/\<svg/, o.string)
  end

  it 'should write all files to stdout' do
    o = StringIO.new("",'w')
    MagickConverter.command_line([art_path('brief.xpm'),
                                  art_path('herz.xpm'), '-O', '-'], o)
    assert_match(/\<svg.*\<svg/m, o.string)
  end

  it 'should only write the empty version' do
    imgfiles('9colors.png') do |files, tmpdir|
      MagickConverter.command_line([*files, '-d', tmpdir, '-m', 'empty'])
      emptyfile  = File.join(tmpdir, '9colors-empty.svg')
      filledfile = File.join(tmpdir, '9colors-filled.svg')
      assert File.exist?(emptyfile), "Expected “#{emptyfile}” to exist"
      refute File.exist?(filledfile), "Expected “#{filledfile}” to not exist"
    end
  end

  it 'should only write the filled version' do
    imgfiles('9colors.png') do |files, tmpdir|
      MagickConverter.command_line([*files, '-d', tmpdir, '-m', 'filled'])
      emptyfile  = File.join(tmpdir, '9colors-empty.svg')
      filledfile = File.join(tmpdir, '9colors-filled.svg')
      refute File.exist?(emptyfile), "Expected “#{emptyfile}” to not exist"
      assert File.exist?(filledfile), "Expected “#{filledfile}” to exist"
    end
  end

  it 'should convert an image to tikz' do
    imgfiles('brief.png') do |files, tmpdir|
      MagickConverter.command_line([*files, '-d', tmpdir, '-t', 'tikz'])
      emptyfile  = File.join(tmpdir, "brief-empty.tikz")
      filledfile = File.join(tmpdir, "brief-filled.tikz")
      assert File.exist?(emptyfile), "Expected “#{emptyfile}” to exist"
      assert File.exist?(filledfile), "Expected “#{filledfile}” to exist"
      
      emptycontent  = File.read(emptyfile)
      filledcontent = File.read(filledfile)
      
      assert_match(/tikzpicture/,emptycontent)
      assert_match(/tikzpicture/,filledcontent)
      
      assert_match(/\\node\[n[01]\]/, emptycontent)
      assert_match(/\\node\[y[01]\]/, filledcontent)
    end
  end

  
  it 'should give help and exit when called without parameters' do
    o = StringIO.new("",'w')
    code = assert_raises(SystemExit) { MagickConverter.command_line([], o) }
    assert_equal 0, code.status
    assert_match(/Usage/, o.string)
  end

  it 'should raise an error and exit if called with wrong parameters' do
    o = StringIO.new("",'w')
    code = assert_raises(SystemExit) { MagickConverter.command_line(['--err'],o,o) }
    assert_equal 22, code.status
    assert_match(/invalid option: --err/, o.string)    
  end
end
