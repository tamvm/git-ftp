require "fog"

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

  def upload(file_name)
    puts "Upload #{file_name} to s3"
    file = directory.files.create(
      :key => processed_path(file_name),
      :body => File.open(file_name),
      :public => true
    )
  end

  def self.instance(key=nil, secret=nil, bucket=nil)
    @instance ||= S3Uploader.new({
      :key => key,
      :secret => secret,
      :bucket => bucket
    }, "")
  end
end
