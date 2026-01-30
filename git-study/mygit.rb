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
  # ファイル検索を高速に行うため、フォルダの階層を分ける役割
  # ファンアウトという仕組み
  dir_name = sha1[0..1]
  # ハッシュ値の残り38文字
  # これがオブジェクトのファイル名になる
  file_name = sha1[2..-1]
  path = ".git/objects/#{dir_name}"

  # オブジェクトを格納するディレクトリを作成
  FileUtils.mkdir_p(path)

  # すでにオブジェクトが存在する場合は何もしない
  return sha1 if File.exist?("#{path}/#{file_name}")

  # 容量節約のためにオブジェクトを圧縮する
  Zlib::deflate(store).then do |compressed|
   # 圧縮したデータを計算したパスにファイルとして書き込む
   File.write("#{path}/#{file_name}", compressed)
  end

  sha1
end

def cat_file(sha1)
  # パスの復元
  dir_name = sha1[0..1]
  file_name = sha1[2..-1]
  path = ".git/objects/#{dir_name}/#{file_name}"

  unless File.exist?(path)
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

def write_tree
  entries = []

  # カレントディレクトリのファイル(.git以外)をループ
  Dir.glob('*').each do |file_name|
    next if file_name == '.git'

    # ファイルをBlobとして保存してハッシュを得る
    sha1_hex = hash_object(file_name)

    # ハッシュ値をバイナリに変換
    # ("H*"): packメソッドに渡す16進数->2進数変換の命令。Hex=16進数の頭文字
    sha1_binary = [sha1_hex].pack('H*')

    # Treeのエントリを作成
    # 100644: ファイルの権限モード
    entries << "100644 #{file_name}\0#{sha1_binary}"
  end

  # 全エントリを合体させてTreeオブジェクトを作る
  tree_content = entries.join

  # Tree用のヘッダーをつけて保存
  header = "tree #{tree_content.bytesize}\0"
  store = header + tree_content
  sha1 = Digest::SHA1.hexdigest(store)

  # zlib圧縮して保存
  save_object(sha1, store)

  sha1
 end

def save_object(sha1, store)
  path = ".git/objects/#{sha1[0..1]}/#{sha1[2..-1]}"
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, Zlib::Deflate.deflate(store))
end

init()
puts "Target file: test.txt"
File.write("test.txt", "Hello, Git!")
hash = hash_object("test.txt")
puts "Success! Hash is #{hash}!"

File.write("message.txt", "RubyでGitを書くのは楽しい！")
sha = hash_object("message.txt")
puts "Saved hash: #{sha}"

retrieved_content = cat_file(sha)

puts "--- Retrieved Content ---"
puts "Retrieved content: #{retrieved_content}"
