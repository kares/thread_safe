require 'test/unit'
require 'thread_safe'

Thread.abort_on_exception = true

class TestCache < Test::Unit::TestCase
  def setup
    @cache = ThreadSafe::Cache.new
  end

  def test_concurrency
    cache = @cache
    assert_nothing_raised do
      (1..100).map do |i|
        Thread.new do
          1000.times do |j|
            key = i*1000+j
            cache[key] = i
            cache[key]
            cache.delete(key)
          end
        end
      end.map(&:join)
    end
  end

  def test_retrieval
    assert_equal nil, @cache[:a]
    @cache[:a] = 1
    assert_equal 1,   @cache[:a]
  end

  def test_key
    assert_equal false, @cache.key?(:a)
    @cache[:a] = 1
    assert_equal true,  @cache.key?(:a)
  end

  def test_delete
    assert_equal false, @cache.delete(:a)
    @cache[:a] = 1
    assert_equal true,  @cache.delete(:a)
    assert_equal nil,   @cache[:a]
    assert_equal false, @cache.key?(:a)
  end

  def test_default_proc
    cache = ThreadSafe::Cache.new {|h,k| h[k] = 1}
    assert_equal false, cache.key?(:a)
    assert_equal 1,     cache[:a]
    assert_equal true,  cache.key?(:a)
  end

  def test_falsy_default_proc
    cache = ThreadSafe::Cache.new {|h,k| h[k] = nil}
    assert_equal false, cache.key?(:a)
    assert_equal nil,   cache[:a]
    assert_equal true,  cache.key?(:a)
  end

  def test_fetch
    assert_equal nil,   @cache.fetch(:a)
    assert_equal false, @cache.key?(:a)

    assert_equal(1, (@cache.fetch(:a) {1}))

    assert_equal true, @cache.key?(:a)
    assert_equal 1,    @cache[:a]
    assert_equal 1,    @cache.fetch(:a)

    assert_equal(1, (@cache.fetch(:a) {flunk}))
  end

  def test_falsy_fetch
    assert_equal false, @cache.key?(:a)

    assert_equal(nil, (@cache.fetch(:a) {}))

    assert_equal true, @cache.key?(:a)
    assert_equal(nil, (@cache.fetch(:a) {flunk}))
  end

  def test_fetch_with_return
    r = lambda do
      @cache.fetch(:a) { return 10 }
    end.call

    assert_equal 10,    r
    assert_equal false, @cache.key?(:a)
  end

  def test_clear
    @cache[:a] = 1
    assert_equal @cache, @cache.clear
    assert_equal false,  @cache.key?(:a)
    assert_equal nil,    @cache[:a]
  end

  def test_each_pair
    @cache.each_pair {|k, v| flunk}
    assert_equal(@cache, (@cache.each_pair {}))
    @cache[:a] = 1

    h = {}
    @cache.each_pair {|k, v| h[k] = v}
    assert_equal({:a => 1}, h)

    @cache[:b] = 2
    h = {}
    @cache.each_pair {|k, v| h[k] = v}
    assert_equal({:a => 1, :b => 2}, h)
  end

  def test_options_validation
    assert_valid_options(nil)
    assert_valid_options({})
    assert_valid_options(:foo => :bar)
  end

  def test_initial_capacity_options_validation
    assert_valid_option(:initial_capacity, nil)
    assert_valid_option(:initial_capacity, 1)
    assert_invalid_option(:initial_capacity, '')
    assert_invalid_option(:initial_capacity, 1.0)
    assert_invalid_option(:initial_capacity, -1)
  end

  def test_load_factor_options_validation
    assert_valid_option(:load_factor, nil)
    assert_valid_option(:load_factor, 0.01)
    assert_valid_option(:load_factor, 0.75)
    assert_valid_option(:load_factor, 1)
    assert_invalid_option(:load_factor, '')
    assert_invalid_option(:load_factor, 0)
    assert_invalid_option(:load_factor, 1.1)
    assert_invalid_option(:load_factor, 2)
    assert_invalid_option(:load_factor, -1)
  end

  def test_concurency_level_options_validation
    assert_valid_option(:concurrency_level, nil)
    assert_valid_option(:concurrency_level, 1)
    assert_invalid_option(:concurrency_level, '')
    assert_invalid_option(:concurrency_level, 1.0)
    assert_invalid_option(:concurrency_level, 0)
    assert_invalid_option(:concurrency_level, -1)
  end

  private
  def assert_valid_option(option_name, value)
    assert_valid_options(option_name => value)
  end

  def assert_valid_options(options)
    assert_nothing_raised { ThreadSafe::Cache.new(options) }
  end

  def assert_invalid_option(option_name, value)
    assert_invalid_options(option_name => value)
  end

  def assert_invalid_options(options)
    assert_raise(ArgumentError) { ThreadSafe::Cache.new(options) }
  end
end