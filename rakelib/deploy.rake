require 'pathname'
require 'fileutils'


desc 'Copy the necessary files to a deployment directory'
task :deploy, [:dir] do |t, args|
  args.with_defaults dir: (Rake.application.original_dir + '_Deploy')
  copy_to_dir args.dir, []
end

#############################################################################

def copy_to_dir(target_dir, additional_excludes=[])
  copy_generic(target_dir, additional_excludes)

  ##############################
  # Regenerate ".gitignore" file

  puts 'Regenerating .gitignore file...'

  @target_gitignore_file = @target_dir + '.gitignore'

  # rm -f <git ignore file>
  @target_gitignore_file.delete if @target_gitignore_file.exist?

  # touch <git ignore file>
  FileUtils.touch @target_gitignore_file

  [
    '.DS_Store',
    '.bundle/',
    'log/*',
    '!log/.keep',
    'tmp/*',
    '!tmp/.keep',
  ].each do |line|
    output = %x[echo "#{line}" >> "#{@target_gitignore_file}"]
    fail output if !output.empty?
  end

  puts 'Done.'
end

def copy_generic(target_dir, additional_excludes=[])
  ##############################
  # Setup the target directory

  @target_dir = Pathname.new(target_dir)
  @target_dir.mkpath

  ##############################
  # Run the RSync command, which will copy all relevant files to the target
  # directory.

  @command = ([
    'rsync',
    '--progress --delete --delete-excluded --recursive --checksum --inplace',

    '--filter="- .DS_Store"',
    '--filter="- **/.DS_Store"',
    '--filter="- rakelib/"',
  ] +
  additional_excludes.collect { |e| "--filter=\"- #{e}\"" } +
  [
    '*',

    "\"#{@target_dir}\""
  ]).join(' ')

  sh %{#{@command}} do |ok, res|
    ok or fail
  end
end
