require 'redis'

class RedisRateLimiter
  attr_accessor :key, :redis, :limit, :interval

  # options:
  # :interval - time span to track in seconds
  # :limit    - max count allowed in interval
  def initialize key, redis, options = {}
    @key      = key
    @redis    = redis
    @limit    = options[:limit] || 50
    @interval = options[:interval] || 60
  end

  def add subject, time = Time.now.to_i
    subject = "#{@key}:#{subject}"
    @redis.multi do
      @redis.lpush(subject, time)
      @redis.ltrim(subject, 0, @limit - 1)
      @redis.expire(subject, @interval)
    end
  end

  def exceeded? subject
    subject = "#{@key}:#{subject}"
    return false if @redis.llen(subject) < @limit
    last = @redis.lrange(subject, @limit - 1, @limit - 1).last
    Time.now.to_i - last.to_i < @interval
  end
end
