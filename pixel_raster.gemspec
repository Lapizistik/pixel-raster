Gem::Specification.new do |s|
  s.name        = 'pixel_raster'
  s.version     = File.read('VERSION')
  s.date        = '2019-08-05'
  s.summary     = "Pixel image raster visualization"
  s.description = "Create a pixel raster representation of an image (for educational purposes)."
  s.authors     = ["Klaus Stein"]
  s.email       = 'ruby@istik.de'
  s.files       = Dir['lib/*.rb'] +
                  ['README.md', 'Beispiel.svg', 'LICENSE', 'VERSION']
  s.executables << 'img2pixel'
  s.homepage    = 'https://github.com/Lapizistik/pixel_raster'
  s.license     = 'GPL-3.0'

  s.add_runtime_dependency "rmagick", '~> 4'
  s.add_development_dependency "mititest-rg"
end
