RedisRateLimiter
==================

Redis-backed rate limiter

Usage
-----

Initialize with preferred limit for a given interval. For example, to rate limit an action 100 times a minute:

    rl = RedisRateLimiter.new("messages", :limit => 100, :interval => 60)

Add to subject's count:

    sender = "John"
    rl.add(sender)

Check if subject has exceeded limit:

    rl.exceeded?(sender)
