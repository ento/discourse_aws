# This script will be executed in the discourse image.
# Usage:
# merge_templates.rb output_file input_file input_file2 ...
require 'pups'

conf = nil
ARGV[1..-1].each do |path|
  current = YAML.load_file(path)
  if conf
    conf = Pups::MergeCommand.deep_merge(conf, current, :merge_arrays)
  else
    conf = current
  end
end

File.open(ARGV[0], 'w') do |f|
  f.write(conf.to_yaml)
end
