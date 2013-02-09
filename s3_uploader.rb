require "fog"
require "active_support/core_ext"

class S3Uploader
  attr_accessor :path
  attr_accessor :authorization

  def initialize(authorization, path)
    self.authorization = authorization
    self.path = path
  end

  def processed_path(file_name)
    "#{path}/#{File.basename(file_name)}"
  end

  def storage
    @storage ||= Fog::Storage.new(
      :provider => 'AWS',
      :aws_access_key_id => authorization[:key],
      :aws_secret_access_key => authorization[:secret],
      :region => authorization[:region],
      :persistent => false
    )
  end

  def directory
    @directory ||= (
      storage.directories.get(authorization[:bucket]) ||
      storage.directories.create(
        :key => authorization[:bucket]
      )
    )
  end

  def destroy(file_path)
    directory.files.get(file_path).try(:destroy)
  end

  def upload(file_name, path=nil)
    if File.directory? file_name
      upload_dir(file_name, path)
    else
      file = directory.files.create(
        :key => path || processed_path(file_name),
        :body => File.open(file_name),
        :public => true
      )
    end
  end

  def upload_dir(dir, path=nil)
    Dir["#{dir}/**/*"].each do |inner_file|
      upload(inner_file, (path == nil) ? inner_file : "#{path}/#{inner_file}")
    end
  end

  def self.instance(key=nil, secret=nil, bucket=nil, region=nil)
    @instance ||= S3Uploader.new({
      :key => key,
      :secret => secret,
      :bucket => bucket,
      :region => region
    }, "")
  end
end
