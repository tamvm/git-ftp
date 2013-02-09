require 'debugger'
require 'yaml'

require "#{File.expand_path(File.dirname(__FILE__))}/s3_uploader.rb"

config = YAML.load_file "#{File.expand_path(Dir.pwd)}/ftp_config.yml"
s3_config = config["s3"]
if s3_config.empty?
  abort "Add credentials to ftp_config.yml file"
end

key = s3_config["key"]
secret = s3_config["secret"]
bucket = s3_config["bucket"]
include_dirs = s3_config["include_dirs"]
region = s3_config["region"]
exclude_exts = s3_config["exclude_exts"]
puts region

sha_from = ARGV[0]
sha_to = ARGV[1]

if !sha_from || !sha_to
  abort "Invalid params"
end

result = `git show --pretty='format:' --name-only #{sha_from}..#{sha_to}`

s3_instance = S3Uploader.instance(key, secret, bucket, region)
files = result.strip.split("\n").reject { |file| file.empty? }
files.each do |file|
  next if !exclude_exts.empty? && exclude_exts.include?(File.extname(file).gsub(".", ""))

  if File.exists? file
    s3_instance.upload(file, file)
    puts "- Uploading #{file}"
  else
    s3_instance.destroy(file)
    puts "- Deleting #{file}"
  end
end

`say "Upload S3 Done"`

