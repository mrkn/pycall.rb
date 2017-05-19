namespace :docker do
  task :build do
    Dir.chdir File.expand_path('../..', __FILE__) do
      system "docker build -f docker/Dockerfile -t rubydata/pycall ."
    end
  end

  desc 'Run docker container [port=8888] [attach_local=$(pwd)]'
  task :run do
    require 'securerandom'
    require 'launchy'
    token = SecureRandom.hex(48)
    port = ENV['port'] || '8888'
    attach_local = File.expand_path(ENV['attach_local'] || Dir.pwd)
    Thread.start do
      sleep 3
      Launchy.open("http://localhost:#{port}/?token=#{token}")
    end
    system "docker run -it -e 'JUPYTER_TOKEN=#{token}' -v #{attach_local}:/notebooks/local -p #{port}:8888 --rm --name pycall rubydata/pycall"
  end
end
