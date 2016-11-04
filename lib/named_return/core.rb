require "named_return/proxy"

module NamedReturn
  # Mix in to your class to make the magic happen.
  module Core
    # Class methods that get extended.
    module ClassMethods
      # "decorator" to call before defining a method to wrap that method
      def named_return
        _named_return_proxy.wrap_method = true
      end

      # local configuration, e.g. `Foo.named_return_config.test = true`
      def named_return_config
        _named_return_proxy.config
      end

      def method_added(name)
        _named_return_proxy.wrap self, instance_method(name)
      end

      def singleton_method_added(name)
        _named_return_proxy.wrap self, method(name), :_singleton
      end
    end

    class << self
      # raw options that later get set on config
      attr_accessor :options
    end

    # Set config options local to your class.
    def self.[](**options)
      clone.tap { |cls| cls.options = options }
    end

    def self.included(obj)
      proxy = Proxy.new(options || {}) # creating a closure
      obj.send(:define_singleton_method, :_named_return_proxy) { proxy }
      # obj.send(:private, :_named_return_proxy)
      obj.extend clone.const_get(:ClassMethods)
    end
  end
end
