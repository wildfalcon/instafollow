desc "Get initial follows"
task :initial_follows => :environment do
  Instafollow::Instagram.add_follows_as_users($redis.get("uid"))
  User.all.each do |u|
    u.followed_at = Time.now - 2.weeks
    u.followed_by_me = true
    u.save
  end
end


desc "Update user data"
task :update_users => :environment do
  User.all.each do |user|
    user.update_from_instagram
    puts "Updated #{user.full_name}"
  end
end


desc "Get the followers of influential users"
task :get_influencers_followers => :environment do
  User.influential.all.each {|u| u.add_follows_as_users!}
end

desc "Follow/unfollow some users"
task :follow_unfollow_some_users  => :environment do
  users = User.never_followed.limit(30)
  users.each(&:follow!)
  users.each(&:unfollow!)
end