require "pathname"
require "fileutils"


desc "Copy the necessary files to a deployment directory"
task :deploy, [:dir] do |_, args|
  args.with_defaults dir: "#{Rake.application.original_dir}_Deploy"
  copy_to_dir args.dir, []
end

#############################################################################

def copy_to_dir(target_dir, additional_excludes=[])
  ##############################
  # Setup the target director

  target_dir = Pathname.new(target_dir)
  target_dir.mkpath

  ##############################
  # Run the RSync command, which will copy all relevant files to the target
  # directory.

  command = ([
    "rsync",
    "--progress --delete --delete-excluded --recursive --checksum --inplace",

    "--filter=\"- .DS_Store\"",
    "--filter=\"- **/.DS_Store\"",
    "--filter=\"- node_modules/\"",
    "--filter=\"- rakelib/\"",
    "--filter=\"- package.json/\"",
    "--filter=\"- yarn.lock/\""
  ] +
  additional_excludes.collect { |e| "--filter=\"- #{e}\"" } +
  [
    "*",

    "\"#{target_dir}\""
  ]).join(" ")

  sh command.to_s do |ok, _|
    ok or raise
  end

  ##############################
  # Regenerate ".gitignore" file

  puts "Regenerating .gitignore file..."

  target_gitignore_file = target_dir.join(".gitignore")

  # rm -f <git ignore file>
  target_gitignore_file.delete if target_gitignore_file.exist?

  # touch <git ignore file>
  FileUtils.touch target_gitignore_file

  [
    ".DS_Store",
    ".bundle/",
    "log/*",
    "!log/.keep",
    "tmp/*",
    "!tmp/.keep",
  ].each do |line|
    output = `echo "#{line}" >> "#{target_gitignore_file}"`
    raise output unless output.empty?
  end

  puts "Done."
end
