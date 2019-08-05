require "minitest/autorun"
require "minitest/spec"
require 'minitest/rg'
require 'pixel_raster'

require_relative('helper')

include PixelRaster


describe MagickConverter do
  let(:img_stein) { converter.read_image(art_path('stein.png')) }
  let(:img_9colors) { converter.read_image(art_path('9colors.png')) }


  describe 'default constructor' do
    let(:converter) { MagickConverter.new }

    describe "unindexed png stein.png" do
      
      it "should read image file" do
        assert_instance_of Magick::Image, img_stein 
      end

      it 'should convert it to two colors' do
        assert_equal 2, img_stein.colors
      end

      it 'should create a 2 color colormap sorted by intensity (light to dark)' do
        cm = converter.compute_colormap(img_stein)
        assert_equal 2, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :>=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end

      it 'should create the demanded output format: tikz' do
        tikz = converter.convert(art_path('stein.png'), type: :tikz, mode: :empty)
        assert_equal converter.image2tikz(img_stein), tikz
        assert_match(/tikzpicture/, tikz)

        tikz = converter.convert(art_path('stein.png'), type: :tikz, mode: :filled)
        assert_equal converter.image2tikz(img_stein, prefix: 'y'), tikz
      end

      it 'should create the demanded output format: svg' do
        svg = converter.convert(art_path('stein.png'), type: :svg, mode: :empty)
        svg_implicit = converter.convert(art_path('stein.png'), mode: :empty)

        assert_equal svg, svg_implicit
        assert_equal converter.image2svg(img_stein), svg
        assert_match(/\<svg/, svg)
        
        svg = converter.convert(art_path('stein.png'), type: :svg, mode: :filled)
        assert_equal converter.image2svg(img_stein, mode: :filled), svg
      end
    end

    describe "indexed png 9colors.png" do
      it "should read image file" do
        assert_instance_of Magick::Image, img_9colors
      end

      it 'should not convert the color table' do
        assert_equal 9, img_9colors.colors
      end
      
      it 'should create a 9 color colormap sorted by intensity (dark to light)' do
        cm = converter.compute_colormap(img_9colors)
        assert_equal 9, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :<=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end

      it 'should create the expected output as tikz' do
        tikz = converter.image2tikz(img_9colors)
        assert_equal '  \begin{tikzpicture}[yscale=-1]
    \draw[step=1,help lines] (0,0) grid (3,3);
    \node[n0] at (0.5,0.5) {0};
    \node[n8] at (1.5,0.5) {8};
    \node[n4] at (2.5,0.5) {4};
    \node[n5] at (0.5,1.5) {5};
    \node[n2] at (1.5,1.5) {2};
    \node[n6] at (2.5,1.5) {6};
    \node[n1] at (0.5,2.5) {1};
    \node[n3] at (1.5,2.5) {3};
    \node[n7] at (2.5,2.5) {7};

  \end{tikzpicture}

', tikz
      end

      it 'should create the expected output as svg' do
        svg = converter.image2svg(img_9colors)
        assert_equal '<svg xmlns="http://www.w3.org/2000/svg">
   <style>
     .pixel {
       stroke : black;
       stroke-width : 1;
      
       fill: white;

     }
    </style>
  <rect x="0" y="0" width="20" height="20" class="pixel p0" />
  <text x="10" y="15" text-anchor="middle" class="t0">0</text>
  <rect x="20" y="0" width="20" height="20" class="pixel p8" />
  <text x="30" y="15" text-anchor="middle" class="t8">8</text>
  <rect x="40" y="0" width="20" height="20" class="pixel p4" />
  <text x="50" y="15" text-anchor="middle" class="t4">4</text>
  <rect x="0" y="20" width="20" height="20" class="pixel p5" />
  <text x="10" y="35" text-anchor="middle" class="t5">5</text>
  <rect x="20" y="20" width="20" height="20" class="pixel p2" />
  <text x="30" y="35" text-anchor="middle" class="t2">2</text>
  <rect x="40" y="20" width="20" height="20" class="pixel p6" />
  <text x="50" y="35" text-anchor="middle" class="t6">6</text>
  <rect x="0" y="40" width="20" height="20" class="pixel p1" />
  <text x="10" y="55" text-anchor="middle" class="t1">1</text>
  <rect x="20" y="40" width="20" height="20" class="pixel p3" />
  <text x="30" y="55" text-anchor="middle" class="t3">3</text>
  <rect x="40" y="40" width="20" height="20" class="pixel p7" />
  <text x="50" y="55" text-anchor="middle" class="t7">7</text>
</svg>
', svg
      end
      
    end
  end

  describe 'constructor with given nr of colors' do
    let(:converter) { MagickConverter.new(nr_of_colors: 6) }

    describe "unindexed png stein.png" do
      
      it "should read image file" do
        assert_instance_of Magick::Image, img_stein 
      end

      it 'should convert it to two colors' do
        assert_equal 6, img_stein.colors
      end

      # we now have more than 2 colors: light to dark
      it 'should create a 6 color colormap sorted by intensity (dark to light)' do
        cm = converter.compute_colormap(img_stein)
        assert_equal 6, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :<=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end
    end

    describe "indexed png 9colors.png" do
      it "should read image file" do
        assert_instance_of Magick::Image, img_9colors
      end

      it 'should convert the color table' do
        assert_equal 6, img_9colors.colors
      end
      
      it 'should create a 9 color colormap sorted by intensity (dark to light)' do
        cm = converter.compute_colormap(img_9colors)
        assert_equal 6, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :<=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end
    end    
  end

  describe 'constructor with given background color' do
    let(:converter) { MagickConverter.new(bg_color: 'blue') }

      it 'should set the empty cell svg background color' do
        svg = converter.image2svg(img_9colors, mode: :empty)
        assert_match(/fill: blue/, svg)
      end
  end

  describe 'constructor with given resizing' do
    let(:converter) { MagickConverter.new(resize: '3x3') }

    it 'should create a 3x3 image' do
      assert_equal 3, img_stein.columns
      assert_equal 3, img_stein.rows
    end
  end

  describe 'constructor with explicit light2dark setting' do
    describe 'with light2dark: true' do
      let(:converter) { MagickConverter.new(light2dark: true) }

       it 'should create a 2 color colormap sorted by intensity (light to dark)' do
        cm = converter.compute_colormap(img_stein)

        assert_equal 2, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :>=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
       end
       
      it 'should create a 9 color colormap sorted by intensity (light to dark)' do
        cm = converter.compute_colormap(img_9colors)

        assert_equal 9, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :>=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end
    end

    describe 'with light2dark: false' do
      let(:converter) { MagickConverter.new(light2dark: false) }
      
      it 'should create a 2 color colormap sorted by intensity (dark to light)' do
        cm = converter.compute_colormap(img_stein)
        
        assert_equal 2, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :<=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
       end
       
      it 'should create a 9 color colormap sorted by intensity (dark to light)' do
        cm = converter.compute_colormap(img_9colors)

        assert_equal 9, cm.length
        cm.inject do |(a,i),(b,j)|
          a.intensity.must_be :<=, b.intensity 
          i.must_be :<=, j
          [b,j]
        end 
      end
    end
  end
  
  describe 'constructor with explicit type setting' do
    describe 'with type: :svg' do
      let(:converter) { MagickConverter.new(type: :svg) }
      
      it 'should create the demanded output format: svg' do
        svg = converter.image2svg(img_9colors)
        assert_match(/\<svg/, svg)
      end
    end

    describe 'with type: :tikz' do
      let(:converter) { MagickConverter.new(type: :tikz) }
      
      it 'should create the demanded output format: tikz' do
        tikz = converter.image2tikz(img_9colors)
        assert_match(/tikzpicture/, tikz)
      end
    end
  end
end
