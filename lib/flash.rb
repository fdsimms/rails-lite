class Flash

  def initialize(req)
    @cookie ||= {}
    unless req.cookies["flash"].nil?
      @cookie = JSON.parse(req.cookies["flash"])
    end
    @cookie[:path] = "/"
    @cookie["flash_now"] ||= {}
    @cookie["normal_flash"] ||= {}
  end

  def now
    @cookie["flash_now"]
  end

  def [](key)
    @cookie["normal_flash"].merge(now)[key]
  end

  def []=(key, value)
    @cookie["normal_flash"][key] = value
  end

  def reset!
    @cookie["normal_flash"] = {}
    reset_now!
  end

  def reset_now!
    @cookie["flash_now"] = {}
  end

  def store_flash(res)
    cookie_json = @cookie.to_json
    res.set_cookie("flash", cookie_json)
  end
end
