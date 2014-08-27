desc 'push assets to qiniu CDN'
task :push_to_qiniu do
  require "dotenv"
  Dotenv.load

  `qboxrsctl login #{ENV['QINIU_ACCESS_KEY']} #{ENV['QINIU_SECRET_KEY']}`

  Dir['public/assets/*'].each do |file|
    key = file[7..-1]

    `qboxrsctl put #{ENV['QINIU_BUCKET']} #{key} #{file}`

    puts "#{file} pushed to http://#{ENV['QINIU_BUCKET']}.qiniudn.com/#{key}"
  end
end
