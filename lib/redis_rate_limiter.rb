require 'redis'

class RedisRateLimiter

  # @!attribute key
  #   @return [String] Name which uniquely identifies this rate limiter
  # @!attribute redis
  #   @return [Redis] Redis client associated with this rate limiter
  # @!attribute interval
  #   @return [Integer] Time span this rate limiter tracks in seconds
  # @!attribute limit
  #   @return [Integer] Max count allowed by rate limiter in interval
  attr_accessor :key, :redis, :limit, :interval

  # Initializes a new RedisRateLimiter object
  #
  # @param [String] key A name to uniquely identify this rate limiter
  # @param [Redis] redis Redis client associated with rate limiter
  # @param options [Integer] :interval Time span to track in seconds
  # @param options [Integer] :limit Max count allowed in interval
  # @return [RedisRateLimiter] Instance of this rate limiter
  def initialize key, redis, options = {}
    @key      = key
    @redis    = redis
    @limit    = options[:limit] || 50
    @interval = options[:interval] || 60
  end

  # Add to subject's count
  #
  # @param [String] subject A name to uniquely identify subject
  # @param [time] time UNIX timestamp of event
  def add subject, time = Time.now.to_f
    subject = "#{@key}:#{subject}"
    @redis.multi do
      @redis.lpush(subject, time)
      @redis.ltrim(subject, 0, @limit - 1)
      @redis.expire(subject, @interval)
    end
  end

  # Check if subject has exceeded count
  #
  # @param [String] subject Name which uniquely identifies subject
  # @return [Boolean] Returns true if subject has exceeded count
  def exceeded? subject
    subject = "#{@key}:#{subject}"
    return false if @redis.llen(subject) < @limit
    last = @redis.lindex(subject, -1)
    Time.now.to_f - last.to_f < @interval
  end
end
