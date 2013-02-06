require 'debugger'
require 'yaml'

require "#{File.expand_path(File.dirname(__FILE__))}/s3_uploader.rb"

config = YAML.load_file "#{File.expand_path(Dir.pwd)}/ftp_config.yml"
s3_config = config["s3"]
key = s3_config["key"]
secret = s3_config["secret"]
bucket = s3_config["bucket"]

sha_from = ARGV[0]
sha_to = ARGV[1]

if !sha_from || !sha_to
  abort "Invalid params"
end

result = `git show --pretty='format:' --name-only #{sha_from}..#{sha_to}`

s3_instance = S3Uploader.instance(key, secret, bucket)
files = result.strip.split("\n").reject { |file| file.empty? }
files.each do |file|
  if File.exists? file
    s3_instance.upload(file)
    puts "- Uploading #{file}"
  else
    s3_instance.destroy(file)
    puts "- Deleting #{file}"
  end
end

`say "Upload S3 Done"`

