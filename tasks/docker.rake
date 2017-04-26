namespace :docker do
  task :build do
    Dir.chdir File.expand_path('../..', __FILE__) do
      system "docker build -f docker/Dockerfile -t rubydata/pycall ."
    end
  end

  task :run do
    require 'securerandom'
    require 'launchy'
    token = SecureRandom.hex(48)
    port = ENV['PORT'] || '8888'
    Thread.start do
      sleep 3
      Launchy.open("http://localhost:#{port}/?token=#{token}")
    end
    system "docker run -it -e 'JUPYTER_TOKEN=#{token}' -p #{port}:8888 --rm --name pycall rubydata/pycall"
  end
end
