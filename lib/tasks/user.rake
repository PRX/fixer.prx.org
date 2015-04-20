namespace :user do

  desc 'Add user from ENV: FIXER_USER_EMAIL, FIXER_USER_PASSWORD'
  task :create => [:environment] do |t, args|
    puts "Start fixer user:create task"
    email = ENV['FIXER_USER_EMAIL']
    password = ENV['FIXER_USER_PASSWORD']
    if !email || !password
      puts "To create or update a user, please specify FIXER_USER_EMAIL and FIXER_USER_PASSWORD"
    elsif user = User.find_by_email(email)
      user.password = password
      user.save!
      puts "Fixer user '#{user.email}' updated with password '#{password}'"
    else
      user = User.create!(email: email, password: password)
      puts "Fixer user '#{user.email}' created with password '#{password}'"
    end
  end
end
