require "spec_helper"

class SampleClass
  include NamedReturn::Core[only: %i(auto), class_only: %i(auto)]

  named_return
  def wrapped(test)
    self.class.run test
  end

  def auto(test)
    self.class.run test
  end

  def unwrapped(test)
    self.class.run test
  end

  named_return
  def self.wrapped(test)
    run test
  end

  def self.auto(test)
    run test
  end

  def self.unwrapped(test)
    run test
  end

  def self.run(test)
    case test
    when :return then return "returned"
    when :throw then throw :thrown
    when :throw_value then throw :thrown, "value"
    when :raise then raise "raised"
    end
  end
end

class SampleBase
  include NamedReturn::Core[only: %i(auto), class_only: %i(auto)]

  def unwrapped(test)
    self.class.run test
  end

  def self.run(test)
    case test
    when :return then return "returned"
    when :throw then throw :thrown
    when :throw_value then throw :thrown, "value"
    when :raise then raise "raised"
    end
  end
end

class SampleInherited < SampleBase
  def auto(test)
    self.class.run test
  end

  def self.auto(test)
    run test
  end

  def self.unwrapped(test)
    run test
  end
end

describe NamedReturn do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  it "has a configure method" do
    expect(described_class).to respond_to :configure
  end

  it "has a config method" do
    expect(described_class).to respond_to :config
  end

  it "has config defaults" do
    expect(described_class.config.only).to eq([])
  end

  it "sets and reads global config" do
    described_class.configure { |c| c.test = true }
    expect(described_class.config.test).to eq(true)

    described_class.configure { |c| c.test = false }
    expect(described_class.config.test).to eq(false)
  end
end

describe NamedReturn::Core do
  it "has local config method" do
    expect(described_class).to respond_to :[]
  end

  it "returns module when local config method is called" do
    expect(described_class[]).to be_kind_of(Module)
  end
end

shared_examples "unwrapped method" do
  let(:m) { :unwrapped }

  it "doesn't affect return" do
    expect(subject.send(m, :return)).to eq("returned")
  end

  it "doesn't affect throw" do
    expect { subject.send(m, :throw) }.to throw_symbol(:thrown)
  end

  it "doesn't affect throw with value" do
    expect { subject.send(m, :throw_value) }.to throw_symbol(:thrown, "value")
  end

  it "doesn't affect raise" do
    expect { subject.send(m, :raise) }.to raise_error("raised")
  end
end

shared_examples "wrapped method" do |m|
  before do
    @result = true
  end

  it "can be called procedurally and throw" do
    process = subject.send(m)
    process.on(:thrown) { |res| @result = res }
    process.call(:throw)

    expect(@result).to eq(nil)
  end

  it "can be called with block DSL and throw" do
    subject.send(m, :throw) do |process|
      process.on(:thrown) { |res| @result = res }
    end

    expect(@result).to eq(nil)
  end

  it "can be called procedurally and throw value" do
    process = subject.send(m)
    process.on(:thrown) { |res| @result = res }
    process.call(:throw_value)

    expect(@result).to eq("value")
  end

  it "can be called with block DSL and throw value" do
    subject.send(m, :throw_value) do |process|
      process.on(:thrown) { |res| @result = res }
    end

    expect(@result).to eq("value")
  end

  it "can be called procedurally and doesn't affect raise" do
    expect do
      process = subject.send(m)
      process.call(:raise)
    end.to raise_error("raised")
  end

  it "can be called with block DSL and doesn't affect raise" do
    expect do
      subject.send(m, :raise) {}
    end.to raise_error("raised")
  end

  context "standard return" do
    it "can be called procedurally" do
      process = subject.send(m)
      @result = process.call(:return)

      expect(@result).to eq("returned")
    end

    it "can be called with block" do
      @result = subject.send(m, :return) {}

      expect(@result).to eq("returned")
    end

    # this test is quite important due to weird internal juggling of returns
    it "is unaffected by on() DSL blocks" do
      @result = subject.send(m, :return) do |process|
        process.on(:foo) {}
      end

      expect(@result).to eq("returned")
    end
  end

  context "re-thrown return" do
    before(:each) { described_class.named_return_config.return = :throw }
    after(:each) { described_class.named_return_config.return = nil }

    it "can be called procedurally" do
      process = subject.send(m)
      process.on(:return) { |res| @result = res }
      process.call(:return)

      expect(@result).to eq("returned")
    end

    it "can be called with block" do
      subject.send(m, :return) do |process|
        process.on(:return) { |res| @result = res }
      end

      expect(@result).to eq("returned")
    end
  end

  context "raised return" do
    before(:each) { described_class.named_return_config.return = :raise }
    after(:each) { described_class.named_return_config.return = nil }

    it "can be called procedurally" do
      expect do
        process = subject.send(m)
        process.call(:return)
      end.to raise_error(ArgumentError)
    end

    it "can be called with block" do
      expect do
        subject.send(m, :return) do |process|
          process.on(:return) { |res| @result = res }
        end
      end.to raise_error(ArgumentError)
    end
  end
end

describe SampleClass do
  context "instance methods" do
    subject { described_class.new }

    it_should_behave_like "unwrapped method"
    it_should_behave_like "wrapped method", :wrapped
    it_should_behave_like "wrapped method", :auto
  end

  context "class methods" do
    subject { described_class }

    it_should_behave_like "wrapped method", :wrapped
    it_should_behave_like "wrapped method", :auto
  end
end

describe SampleInherited do
  context "instance methods" do
    subject { described_class.new }

    it_should_behave_like "unwrapped method"
    it_should_behave_like "wrapped method", :auto
  end

  context "class methods" do
    subject { described_class }

    it_should_behave_like "wrapped method", :auto
  end
end
