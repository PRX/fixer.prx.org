require 'erb'

namespace :build do

  def env_json
    env = File.readlines('.env.production')
    env_hash = env.map { |l| k,v = l.chomp.split('='); { name: k, value: v } }
    JSON.pretty_generate(env_hash)
  end

  TASK_TEMPLATE_FILES = Rake::FileList.new("./container/ecs/task_definitions/*.json.erb") do |fl|
    fl.exclude("~*")
    fl.exclude(/^scratch\//)
    fl.exclude do |f|
      `git ls-files #{f}`.empty?
    end
  end

  desc 'Create ECS task definition json files'
  task :task_definitions do
    TASK_TEMPLATE_FILES.each do |template|
      puts "template: #{template}"
      dest = template.pathmap("%{container/,build/}X")
      puts "dest: #{dest}"
      @env_json = env_json
      mkdir_p dest.pathmap("%d")
      File.open(dest, "w+") do |f|
        erb_file = File.read(template)
        f.write(ERB.new(erb_file).result(binding))
      end
    end
  end
end
