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

    def self.get_details_for_username(username)
      config
      ::Instagram.user_search(username).select {|u| u["username"] == username}.first
    end

    def self.get_detail_for_uid(uid)
      config
      ::Instagram.user(uid)
    end

    def self.get_follows_for_uid(uid)
      config

      cursor = 0
      follows = []
      while cursor.present? do
        new_follows = get_page_of_follows(uid, cursor)
        follows += new_follows
        cursor = new_follows.pagination.next_cursor
      end

      follows
    end

    def self.get_page_of_follows(uid, cursor=nil)
      cursor == 0 ? ::Instagram.user_follows(uid) : ::Instagram.user_follows(uid, :cursor => cursor)
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
