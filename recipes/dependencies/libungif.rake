require 'rake'
require 'rake/clean'

namespace(:dependencies) do
  namespace(:libungif) do
    package = RubyInstaller::LibUnGif
    directory package.target
    CLEAN.include(package.target)

    # Put files for the :download task
    dt = checkpoint(:libungif, :download)
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
    et = checkpoint(:libungif, :extract) do
      dt.prerequisites.each { |f|
        extract(File.join(RubyInstaller::ROOT, f), package.target)
      }
      package.files.each {|f|
        extract(File.join(RubyInstaller::ROOT, "downloads", f), package.target)
      }
    end
    task :extract => [:extract_utils, :download, package.target, et]

    task :activate do
      puts "Activating libungif version #{package.version}"
      activate(package.target)
    end
  end
end

task :libungif => [
  'dependencies:libungif:download',
  'dependencies:libungif:extract',
  'dependencies:libungif:activate'
]