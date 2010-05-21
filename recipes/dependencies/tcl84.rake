require 'rake'
require 'rake/clean'

namespace(:dependencies) do
  namespace(:tcl84) do
    # zlib needs mingw and downloads
    package = RubyInstaller::Tcl84
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
      files = Rake::Task['dependencies:tcl84:download'].prerequisites

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

task :tcl84 => [
  'dependencies:tcl84:download',
  'dependencies:tcl84:extract',
  'dependencies:tcl84:configure_install'  
]

file RubyInstaller::SANDBOX + "/mingw/bin/tcl84.dll" => :tcl84
file RubyInstaller::SANDBOX + "/mingw/bin/tk84.dll" => :tcl84

task :dependencies => [RubyInstaller::SANDBOX + "/mingw/bin/tcl84.dll", RubyInstaller::SANDBOX + "/mingw/bin/tk84.dll"]