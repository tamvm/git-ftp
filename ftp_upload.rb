require "#{File.expand_path(File.dirname(__FILE__))}/better_ftp.rb"

FTP_HOST = "FTP_HOST"
FTP_USERNAME = "FTP_USERNAME"
FTP_PASSWORD = "FTP_PASSWORD"
PUBLIC_HTML = "/"

module FTPExt
  def chdirc(dir)
    self.chdir dir
  rescue Net::FTPPermError
    self.mkdir_p dir
    self.chdir dir
  end
end

ftp = BetterFTP.new(FTP_HOST, FTP_USERNAME, FTP_PASSWORD)
ftp.extend(FTPExt)

ftp.passive = true

sha_from = ARGV[0]
sha_to = ARGV[1]

if !sha_from || !sha_to
  abort "Invalid params"
end

result = `git show --pretty='format:' --name-only #{sha_from}..#{sha_to}`

files = result.strip.split("\n").reject { |file| file.empty? }
files.each do |file|
  puts "- Uploading #{file}"
  ftp.chdirc(PUBLIC_HTML + File.dirname(file))
  ftp.putbinaryfile(file, File.basename(File.basename(file)))
  puts ftp.last_response
end
ftp.quit

