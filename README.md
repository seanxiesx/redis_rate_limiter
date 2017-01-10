RedisRateLimiter
==================

[![Build Status](https://travis-ci.org/seanxiesx/redis_rate_limiter.png)](https://travis-ci.org/seanxiesx/redis_rate_limiter)
[![Coverage Status](https://coveralls.io/repos/seanxiesx/redis_rate_limiter/badge.png)](https://coveralls.io/r/seanxiesx/redis_rate_limiter)

Redis-backed rate limiter

Usage
-----

Initialize with preferred limit for a given interval. For example, to rate limit an action 100 times a minute:

    redis = Redis.new
    rl = RedisRateLimiter.new("messages", redis, :limit => 100, :interval => 60)

Add to subject's count:

    sender = "John"
    rl.add(sender)

Check if subject has exceeded limit:

    rl.exceeded?(sender)

Query number of seconds until subject is not rate limited (returns 0.0 if subject is not rate limited):

    rl.retry_in?(sender)

Query number of events recorded for a given key

    sender = "John"
    3.times { rl.add(sender) }
    rl.count(sender)
    > 3
    sleep 60
    rl.count(sender)
    > 0

Documentation
-----

[http://rubydoc.info/github/seanxiesx/redis_rate_limiter/master/frames](http://rubydoc.info/github/seanxiesx/redis_rate_limiter/master/frames)
