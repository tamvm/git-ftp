require 'debugger'
require 'yaml'

require "#{File.expand_path(File.dirname(__FILE__))}/better_ftp.rb"

module FTPExt
  def chdirc(dir)
    chdir dir
  rescue Net::FTPPermError
    mkdir_p dir
    chdir dir
  end

  def try_rm(path)
    rm path
  rescue Net::FTPPermError
    puts "#{path} not exists"
  end
end

def connect_ftp(ftp_host, ftp_username, ftp_password)
  begin
    ftp = BetterFTP.new(ftp_host, ftp_username, ftp_password)
  rescue Net::FTPPermError => e
    puts e.message
    puts e.backtrace.join("\n")
    abort
  end
  ftp.extend(FTPExt)
  ftp.passive = true
  ftp
end

config = YAML.load_file "#{File.expand_path(Dir.pwd)}/ftp_config.yml"
debug = config["debug"]
ftp_host = config["ftp_host"]
ftp_username = config["ftp_username"]
ftp_password = config["ftp_password"]
ftp_public_html = config["ftp_public_html"]

ftp = connect_ftp(ftp_host, ftp_username, ftp_password)
sha_from = ARGV[0]
sha_to = ARGV[1]

if !sha_from || !sha_to
  abort "Invalid params"
end

result = `git show --pretty='format:' --name-only #{sha_from}..#{sha_to}`

files = result.strip.split("\n").reject { |file| file.empty? }
num_try = 0
files.each do |file|
  begin
    remote_path = ftp_public_html + File.dirname(file)
    if File.exists? file
      puts "- Uploading #{file}" if debug
      ftp.chdirc(remote_path)
      ftp.putbinaryfile(file, File.basename(File.basename(file)))
    else
      puts "- Deleting #{file}" if debug
      ftp.try_rm remote_path
    end
    puts ftp.last_response if debug
  rescue Errno::ETIMEDOUT => e
    num_try += 1
    puts e.message
    puts e.backtrace.join("\n")
    puts "TRY AGAIN: #{num_try}"

    if num_try > 2
      `say "Fail Fail Fail"`
    else
      ftp.try(:quit)
      ftp = connect_ftp(ftp_host, ftp_username, ftp_password)
    end
  end
end

`say "Upload FTP Done"`

