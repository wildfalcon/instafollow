class HomeController < ApplicationController

  def index
  end

  def callback
    hash = request.env["omniauth.auth"]
    $redis.set("instagram_token", hash["credentials"]["token"])
    $redis.set("uid", hash["uid"])
    redirect_to root_path
  end
end
