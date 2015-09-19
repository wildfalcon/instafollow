class User < ActiveRecord::Base

  default_scope { order('uid') }
  scope :popular,           -> { where("follower_count > 1000") }
  scope :influential,       -> { where(influential: true) }
  scope :unfollowed,        -> { where(followed_by_me: false) }
  scope :followed,          -> { where(followed_by_me: true) }
  scope :never_followed,    -> { where(followed_at: nil) }
  scope :manually_followed, -> { where(manually_followed: true) }
  scope :auto_followed,     -> { where(manually_followed: false) }
  scope :followed_before,   -> (date) { where("followed_at < ?", date) }

  def self.add_user_by_username!(username, influential = false)
    user_hash = Instafollow::Instagram.get_details_for_username(username)
    if user_hash.present?
      user = User.where(uid: user_hash["id"]).first_or_initialize
      user.influential = influential
      user.save!
    else
      puts "Cound't find #{username}"
    end
  end

  def update_from_instagram!
    begin
      user_hash = Instafollow::Instagram.get_detail_for_uid(uid)
      self.follower_count = user_hash["counts"]["followed_by"]
      self.full_name = user_hash["full_name"]
      self.username = user_hash["username"]
      save
    rescue
    end
  end

  def toggle_influential!
    if self.influential?
      self.influential=false
    else
      self.influential=true
    end
    save
  end

  def unfollow!
    begin
      Instafollow::Instagram.unfollow(uid)
      self.unfollowed_at = Time.now
      self.followed_by_me = false
      save
    rescue
      puts "Unable to unfollow #{uid}"
    end
  end

  def follow!
    begin
      Instafollow::Instagram.follow(uid)
      self.followed_at = Time.now
      self.followed_by_me = true
      save
    rescue
      puts "Unable follow #{uid}"
    end
  end

  def add_follows_as_users!
    begin
      Instafollow::Instagram.get_follows_for_uid(uid).each do |instagram_user|
        u = User.where(uid: instagram_user["id"]).first_or_initialize
        u.follower_count = user_hash["counts"]["followed_by"]
        u.full_name = instagram_user["full_name"]
        u.username = instagram_user["username"]
        u.save
      end
    rescue
      # the error is probably Instagram::BadRequest meaning
      # I can't get this users followers. I'm ok with ignoring this for now
    end
  end
end
