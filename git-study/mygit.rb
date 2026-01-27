require 'fileutils' # fileutils: mv, rm, mkdirなどのファイル操作を行うためのライブラリ
require 'digest/sha1'
require 'zlib'

# 初期： .gitディレクトリを作成する
# git initが実行された時の処理内容を書く
def init
 # オブジェクトDBを格納するためのディレクトリを作成
 # ファイルの内容（Blob）、ディレクトリ構造（Tree)、コミット情報（Commit）などがオブジェクトとして圧縮され、保存される
  FileUtils.mkdir_p('.git/objects')
  # 各ブランチの最新のコミットを指し示す「参照（reference)」を保存するためのディレクトリを作成
  # 例）mainブランチの場合は、mainという名前のファイルがこのディレクトリに作成され、
  # そのファイルにはmainブランチの最新コミットのSHA-1ハッシュ値は記録される
  FileUtils.mkdir_p('.git/refs/heads')
  # 現在作業中のブランチがどれかを示す参照ファイルを作成
  # ここに書き込むことでリポジトリの現在のブランチを指定できる
  File.write('.git/HEAD', "ref: refs/heads/main\n")
  puts "Initialized empty Git repository"
end

# 保存：ファイルをGit形式で保存する
# git addコマンドが内部的に行う処理の一部
# 指定されたファイルをGitオブジェクトとしてリポジトリに保存する
def hash_object(file_path)
  content = File.read(file_path)
  header = "blob #{content.bytesize}\0"
  store = header + content

  sha1 = Digest::SHA1.hexdigest(store)

  # 保存先のパスを計算
  # ハッシュ値の先頭２文字
  # これがオブジェクトストア内のディレクトリ名になる
  dir_name = sha1[0..1]
  # ハッシュ値の残り38文字
  # これがオブジェクトのファイル名になる
  file_name = sha1[2..-1]
  path = ".git/objects/#{dir_name}"

  # オブジェクトを格納するディレクトリを作成
  FileUtils.mkdir_p(path)
  # 容量節約のためにオブジェクトを圧縮する
  Zlib::Deflate(store).then do |compressed|
   # 圧縮したデータを計算したパスにファイルとして書き込む
   File.write("#{path}/#{file_name}", compressed)
  end

  sha1
end

init()
puts "Target file: test.txt"
File.write("test.txt", "Hello, Git!")
hash = hash_obejct("test.txt")
puts "Success! Hash is #{hash}!"
