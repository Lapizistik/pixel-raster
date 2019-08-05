# test helper methods

# 
def art_path(filename)
  File.realpath(File.join(__dir__,'../artwork',filename))
end

def imgfiles(*files, copy: false)
  Dir::mktmpdir('Test-pixel_raster') do |tmpdir|
    if copy
      yield(files.map { |file|
              FileUtils.cp(art_path(file), tmpdir) 
              File.join(tmpdir,file) }, tmpdir)
    else
      yield(files.map { |file| art_path(file) }, tmpdir)
    end
  end
end
