require 'fileutils'
require 'digest/sha1'
require 'zlib'

def cat_file(sha1)
  # パスの復元
  dir_name = sha1[0..1]
  file_name = sha1[2..-1]
  path = ".git/objects/#{dir_name}/#{file_name}"

  unless File.exists?(path)
    puts "Objects not found!"
    return
  end

  # ファイルを読み込んで解凍する
  # compress: 圧縮する
  # inflate: 膨らます
  compressed_data = File.read(path)
  raw_data = Zlib::Inflate.inflate(compressed_data)

  # ヘッダーと中身を分離する
  # Git式は”blob <size>\0<content>"という形式なので、\0で分割する
  header, content = raw_data.split("\0", 2)
  puts "DEBUG: header is #{header}"

  content
end

File.write("message.txt", "RubyでGitを書くのは楽しい！")
sha = hash_object("message.txt")
puts "Saved hash: #{sha}"

retrieved_content = cat_file(sha)

puts "--- Retrieved Content ---"
puts "Retrieved content: #{retrieved_content}"
