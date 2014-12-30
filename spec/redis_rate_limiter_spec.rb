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
      it "should be false if last item in subject's list is outside interval" do
        outside_interval_timestamp = Time.now.to_i - @rl.interval - 1
        @rl.limit = 5
        @rl.add(subject, outside_interval_timestamp)
        4.times { @rl.add(subject) }
        expect(@rl.exceeded?(subject)).to be_falsey
      end
      it "should be true if last item in subject's list is within interval" do
        @rl.limit = 5
        5.times { @rl.add(subject) }
        expect(@rl.exceeded?(subject)).to be_truthy
      end
    end
  end
end
