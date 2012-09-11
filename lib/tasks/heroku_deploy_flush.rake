Rake::Task["assets:precompile"].enhance do
  # How to invoke a task that exists elsewhere
  # Rake::Task["assets:environment"].invoke if Rake::Task.task_defined?("assets:environment")

  # Clear cache on deploy
  print "Clearing the rails memcached cache\n"
  Rails.cache.clear
end