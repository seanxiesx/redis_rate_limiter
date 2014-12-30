require_relative "spec_helper"

describe RedisRateLimiter do

  describe "#initialize" do
    before { Redis.stub(:new).and_return(@redis = MockRedis.new) }
    subject { RedisRateLimiter.new(:key, Redis.new) }
    its(:key)      { should == :key }
    its(:redis)    { should == @redis }
    its(:interval) { should == 60 }
    its(:limit)    { should == 50 }
  end

  describe "#add" do
    let(:subject) { "subject" }
    before do
      Redis.stub(:new).and_return(@redis = MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should prepend timestamp to subject's list" do
      timestamp = 123
      @rl.add(subject, timestamp)
      @redis.lrange("key:#{subject}", 0, 0).should == [timestamp.to_s]
    end
    it "should trim subject's list" do
      @rl.limit = 5
      10.times { @rl.add(subject) }
      @redis.lrange("key:#{subject}", 0, 100).size.should == @rl.limit
    end
    it "should refresh expiry of subject's list" do
      @redis.should_receive(:expire).with("key:#{subject}", @rl.interval)
      @rl.add(subject)
    end
  end

  describe "#exceeded?" do
    let(:subject) { "subject" }
    before do
      Redis.stub(:new).and_return(MockRedis.new)
      @rl = RedisRateLimiter.new(:key, Redis.new)
    end
    it "should be false if subject's list is less than limit" do
      @rl.exceeded?(subject).should be_false
    end
    context "subject's list is at limit" do
      it "should be false if last item in subject's list is outside interval" do
        outside_interval_timestamp = Time.now.to_f - @rl.interval - 1
        @rl.limit = 5
        @rl.add(subject, outside_interval_timestamp)
        4.times { @rl.add(subject) }
        @rl.exceeded?(subject).should be_false
      end
      it "should be true if last item in subject's list is within interval" do
        @rl.limit = 5
        5.times { @rl.add(subject) }
        @rl.exceeded?(subject).should be_true
      end
    end
  end
end
