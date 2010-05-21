require 'rake'
require 'rake/clean'

namespace(:dependencies) do
  namespace(:tcl) do
    # zlib needs mingw and downloads
    package = RubyInstaller::Tcl
    directory package.target
    CLEAN.include(package.target)
    
    # Put files for the :download task
    package.files.each do |f|
      file_source = "#{package.url}/#{f}"
      file_target = "downloads/#{f}"
      download file_target => file_source
      
      # depend on downloads directory
      file file_target => "downloads"
      
      # download task need these files as pre-requisites
      task :download => file_target
    end

    # Prepare the :sandbox, it requires the :download task
    task :extract => [:extract_utils, :download, package.target] do
      # grab the files from the download task
      files = Rake::Task['dependencies:tcl:download'].prerequisites

      files.each { |f|
        extract(File.join(RubyInstaller::ROOT, f), package.target)
      }
    end
    
    task :configure_install => [package.target] do
      cd File.join(RubyInstaller::ROOT, package.target) do
        package.files.sort.each{|file| 
          file =~ /(.*)-src/
          Dir.chdir $1 do
            # may want to install it into ruby18_mingw
            # install both into our local mingw install
            msys_sh "win/configure --prefix=/mingw --with-tcl=/mingw/lib"
            msys_sh "make"
            msys_sh "make install"            
          end
        }
      end
    end
    
  end
end

task :tcl => [
  'dependencies:tcl:download',
  'dependencies:tcl:extract',
  'dependencies:tcl:configure_install'  
]

task :dependencies => :tcl