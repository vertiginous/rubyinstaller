require 'rake'
require 'rake/clean'

namespace(:dependencies) do
  namespace(:port_audio) do
    package = RubyInstaller::PortAudio
    extracted_files_target = File.join package.target, 'portaudio'

    directory package.target
    CLEAN.include(package.target)

    # Put files for the :download task
    dt = checkpoint(:port_audio, :download)
    package.files.each do |f|
      file_source = "#{package.url}/#{f}"
      file_target = "downloads/#{f}"
      download file_target => file_source

      # depend on downloads directory
      file file_target => "downloads"

      # download task need these files as pre-requisites
      dt.enhance [file_target]
    end
    task :download => dt

    # Prepare the :sandbox, it requires the :download task
    et = checkpoint(:port_audio, :extract) do
      dt.prerequisites.each { |f|
        extract(File.join(RubyInstaller::ROOT, f), package.target)
      }
      package.files.each {|f|
        extract(File.join(RubyInstaller::ROOT, "downloads", f), package.target)
      }
    end
    task :extract => [:extract_utils, :download, package.target, et]

    makefile = File.join(extracted_files_target, 'Makefile')
    configurescript = File.join(extracted_files_target, 'configure')

    task :configure => [:compiler] do
      cd File.expand_path extracted_files_target do 
        sh "sh ./configure --prefix=#{File.join(RubyInstaller::ROOT, package.install_target)}"
      end
    end
    
    task :compile => [:compiler, makefile] do
      cd File.expand_path extracted_files_target do 
        sh "make"
      end
    end

    task :install => [:compiler, package.install_target] do
      cd File.expand_path extracted_files_target do 
        sh "make install"
      end
    end

    task :activate do
      puts "Activating portaudio version #{package.version}"
      activate(package.target)
    end
  end
end

task :port_audio => [
  'dependencies:port_audio:download',
  'dependencies:port_audio:extract',
  'dependencies:port_audio:configure',
  'dependencies:port_audio:compile',
  'dependencies:port_audio:install',
  'dependencies:port_audio:activate'
]
