module Instafollow

  class RateLimitError < StandardError; end

  class Instagram

    def self.config
      if $redis.get("instagram_token") && $redis.get("uid")
        ::Instagram.configure do |config|
          config.client_id = ENV["INSTAGRAM_ID"]
          config.access_token = $redis.get("instagram_token")
        end
      else
        raise "Instagram not set up"
      end
    end

    def self.get_user_details_from_username(username)
      config
      users = ::Instagram.user_search( username )
      users.select {|u| u["username"] == username}.first
    end

    def self.get_page_of_follows(uid, cursor=nil)
      config
      follows = if cursor == 0
        ::Instagram.user_follows(uid)
      else
        ::Instagram.user_follows(uid, :cursor => cursor)
      end
      follows
    end

    def self.save_as_user(instagram_user)
      u = User.where(uid: instagram_user["id"]).first_or_initialize
      u.full_name = follow["full_name"]
      u.username = follow["username"]
      u.save
    end

    def self.add_follows_as_users(uid)
      cursor = 0

      while cursor.present? do
        follows = get_page_of_follows(uid, cursor)
        follows.each {|f| save_as_user(f) }
        cursor = follows.pagination.next_cursor
        puts "!!!!!!!!!! #{cursor}"
      end
    end

    def self.update_user(uid)
      config
      user = User.find_by_uid uid.to_s
      if user.present?
        user_hash = ::Instagram.user(uid)
        user.follower_count = user_hash["counts"]["followed_by"]
        user.full_name = user_hash["full_name"]
        user.username = user_hash["username"]
        user.save
      end
    end

    def self.follow(uid)
      config
      begin
        ::Instagram.follow_user(uid)
      rescue ::Instagram::TooManyRequests
        raise RateLimitError
      end
    end

    def self.unfollow(uid)
      config
      begin
        ::Instagram.unfollow_user(uid)
      rescue ::Instagram::TooManyRequests
        raise RateLimitError
      end
    end
  end
end
