require 'fileutils' # fileutils: mv, rm, mkdirなどのファイル操作を行うためのライブラリ
require 'digest/sha1'
require 'zlib'

# 初期： .gitディレクトリを作成する
def init
  FileUtils.mkdir_p('.git/objects')
  FileUtils.mkdir_p('.git/refs/heads')
  File.write('.git/HEAD', "ref: refs/heads/main\n")
  puts "Initialized empty Git repository"
end