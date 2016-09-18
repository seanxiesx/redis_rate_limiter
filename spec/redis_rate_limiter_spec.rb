require_relative "spec_helper"

describe RedisRateLimiter do

  describe "#initialize" do
    before { allow(Redis).to receive(:new).and_return(@redis = MockRedis.new) }
    subject { RedisRateLimiter.new(:key, Redis.new) }
    its(:key)      { is_expected.to eq(:key) }
    its(:redis)    { is_expected.to eq(@redis) }
    its(:interval) { is_expected.to eq(60) }
    its(:limit)    { is_expected.to eq(50) }
  end

  describe "#add" do
    let(:subject) { "subject" }
    before do
      allow(Redis).to receive(:new).and_return(@redis = MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should return false and not prepend timestamp if rate limit exceeded while waiting for lock" do
      @rl.add(subject, 123)
      allow(@rl).to receive(:exceeded?).and_return(false, true)
      expect(@rl.add(subject)).to be_falsy
      expect(@redis.lrange("key:#{subject}", 0, 0)).to eq(["123"])
    end
    it "should return true if successfully added timestamp to subject's list" do
      expect(@rl.add(subject)).to be_truthy
    end
    it "should return false if the rate limit is exceeded" do
      @rl.limit.times { @rl.add(subject) }
      expect(@rl.add(subject)).to be_falsy
    end
    it "should prepend timestamp to subject's list" do
      timestamp = 123
      @rl.add(subject, timestamp)
      expect(@redis.lrange("key:#{subject}", 0, 0)).to eq([timestamp.to_s])
    end
    it "should trim subject's list" do
      @rl.limit = 5
      10.times { @rl.add(subject) }
      expect(@redis.lrange("key:#{subject}", 0, 100).size).to eq(@rl.limit)
    end
    it "should refresh expiry of subject's list" do
      expect(@redis).to receive(:expire).with("key:#{subject}", @rl.interval)
      @rl.add(subject)
    end
  end

  describe "#exceeded?" do
    let(:subject) { "subject" }
    before do
      allow(Redis).to receive(:new).and_return(MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should be false if subject's list is less than limit" do
      expect(@rl.exceeded?(subject)).to be_falsey
    end
    context "subject's list is at limit" do
      it "should be false if oldest item in subject's list is outside interval" do
        outside_interval_timestamp = Time.now.to_f - @rl.interval - 1
        @rl.limit = 5
        @rl.add(subject, outside_interval_timestamp)
        4.times { @rl.add(subject) }
        expect(@rl.exceeded?(subject)).to be_falsey
      end
      it "should be true if oldest item in subject's list is within interval" do
        @rl.limit = 5
        5.times { @rl.add(subject) }
        expect(@rl.exceeded?(subject)).to be_truthy
      end
    end
  end

  describe "#retry_in?" do
    let(:subject) { "subject" }
    before do
      allow(Redis).to receive(:new).and_return(MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should be 0.0 if subject's list is less than limit" do
      expect(@rl.retry_in?(subject)).to eq(0.0)
    end
    context "subject's list is at limit" do
      it "should be 0.0 if oldest item in subject's list is outside interval" do
        outside_interval_timestamp = Time.now.to_f - @rl.interval - 1
        @rl.limit = 5
        @rl.add(subject, outside_interval_timestamp)
        4.times { @rl.add(subject) }
        expect(@rl.retry_in?(subject)).to eq(0.0)
      end
      it "should be the time in seconds until subject stops being rate limited" do
        forty_seconds_ago = Time.now.to_f - 40
        @rl.limit = 5
        @rl.add(subject, forty_seconds_ago)
        4.times { @rl.add(subject) }
        expect(@rl.retry_in?(subject)).to be_within(1).of(20)
      end
    end
  end

  describe "#time_since_oldest" do
    let(:subject) { "subject" }
    let(:subject_key) { "key:subject" }
    before do
      allow(Redis).to receive(:new).and_return(@redis = MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should return time since oldest event for given subject key" do
      forty_seconds_ago = Time.now.to_f - 40
      @rl.add(subject, forty_seconds_ago)
      expect(@rl.send(:time_since_oldest, subject_key)).to be_within(1).of(40)
    end
  end
end
