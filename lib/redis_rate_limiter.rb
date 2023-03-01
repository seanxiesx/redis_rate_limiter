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
    subject_key = "#{@key}:#{subject}"
    @redis.multi do |pipeline|
      pipeline.lpush(subject_key, time)
      pipeline.ltrim(subject_key, 0, @limit - 1)
      pipeline.expire(subject_key, @interval)
    end
  end

  # Check if subject has exceeded count
  #
  # @param [String] subject Name which uniquely identifies subject
  # @return [Boolean] Returns true if subject has exceeded count
  def exceeded? subject
    subject_key = "#{@key}:#{subject}"
    return false if @redis.llen(subject_key) < @limit
    time_since_oldest(subject_key) < @interval
  end

  # Get time in seconds until subject is not rate limited
  #
  # @param [String] subject Name which uniquely identifies subject
  # @return [Float] Returns time in seconds until subject is not rate limited
  def retry_in? subject
    subject_key = "#{@key}:#{subject}"
    return 0.0 if @redis.llen(subject_key) < @limit
    elapsed = time_since_oldest(subject_key)
    elapsed > @interval ? 0.0 : @interval - elapsed
  end

  # Get number of events currently recorded for subject
  #
  # @param [String] subject Name which uniquely identifies subject
  # @return [Integer] Returns number of events currently recorded for subject
  def count subject
    @redis.llen("#{@key}:#{subject}")
  end

  private

  def time_since_oldest subject_key
    Time.now.to_f - @redis.lindex(subject_key, -1).to_f
  end
end
