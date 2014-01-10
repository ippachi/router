require 'test_helper'

describe Lotus::Routing::EndpointResolver do
  before do
    @resolver = Lotus::Routing::EndpointResolver.new
  end

  it 'recognizes :to when it is a callable object' do
    endpoint = Object.new
    endpoint.define_singleton_method(:call) { }

    options = { to: endpoint }

    @resolver.resolve(options).must_equal(endpoint)
  end

  it 'recognizes :to when it is a string that references a class that can be retrieved now' do
    options = { to: 'test_endpoint' }
    @resolver.resolve(options).call({}).must_equal 'Hi from TestEndpoint!'
  end

  describe 'when :to references a missing class' do
    it 'if the class is available when invoking call, it succeed' do
      options  = { to: 'lazy_controller' }
      endpoint = @resolver.resolve(options)
      LazyController = Class.new(Object) { define_method(:call) {|env| env } }

      endpoint.call({}).must_equal({})
    end

    it 'if the class is not available when invoking call, it raises error' do
      options  = { to: 'missing_endpoint' }
      endpoint = @resolver.resolve(options)

      -> { endpoint.call({}) }.must_raise NameError
    end
  end

  it 'recognizes :to when it is a string with separator' do
    options = { to: 'test#show' }
    @resolver.resolve(options).call({}).must_equal 'Hi from Test::Show!'
  end

  describe 'namespace' do
    before do
      @resolver = Lotus::Routing::EndpointResolver.new(namespace: TestApp)
    end

    it 'recognizes :to when it is a string and an explicit namespace' do
      options = { to: 'test_endpoint' }
      @resolver.resolve(options).call({}).must_equal 'Hi from TestApp::TestEndpoint!'
    end

    it 'recognizes :to when it is a string with separator and it has an explicit namespace' do
      options = { to: 'test2#show' }
      @resolver.resolve(options).call({}).must_equal 'Hi from TestApp::Test2Controller::Show!'
    end
  end

  describe 'custom endpoint' do
    before :all do
      class CustomEndpoint
        def initialize(endpoint)
          @endpoint = endpoint
        end
      end

      @resolver = Lotus::Routing::EndpointResolver.new(endpoint: CustomEndpoint)
    end

    after do
      Object.send(:remove_const, :CustomEndpoint)
    end

    it 'returns specified endpoint instance' do
      @resolver.resolve({}).class.must_equal(CustomEndpoint)
    end
  end

  describe 'custom separator' do
    before do
      @resolver = Lotus::Routing::EndpointResolver.new(separator: separator)
    end

    let(:separator) { '@' }

    it 'matches controller and action with a custom separator' do
      options = { to: "test#{ separator }show" }
      @resolver.resolve(options).call({}).must_equal 'Hi from Test::Show!'
    end
  end

  describe 'custom suffix' do
    before do
      @resolver = Lotus::Routing::EndpointResolver.new(suffix: suffix)
    end

    let(:suffix) { 'Controller::' }

    it 'matches controller and action with a custom separator' do
      options = { to: 'test#show' }
      @resolver.resolve(options).call({}).must_equal 'Hi from Test::Show!'
    end
  end
end