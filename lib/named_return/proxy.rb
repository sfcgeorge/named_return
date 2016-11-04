require "named_return/wrapped_method"

module NamedReturn
  # The Core mixin calls this class to wrap methods with the catch DSL.
  class Proxy
    attr_accessor :wrap_method, :config

    def initialize(**options)
      @config = NamedReturn.config.clone
      options.each { |option, value| config.send(:"#{option}=", value) }
    end

    def wrap(obj, meth, singleton = nil)
      @wrap_method ||= config.auto_wrap?(meth.name, singleton)
      return unless @wrap_method == true # not just truthy, true for reals

      @wrap_method = :overriding # this prevents infinite loops :P
      wrapped_method = WrappedMethod.new meth, config
      override_method(obj, wrapped_method, singleton)
      @wrap_method = nil
    end

    private

    def override_method(obj, wrapped, singleton)
      base = self
      obj.send(:"define#{singleton}_method", wrapped.name) do |*args, &block|
        wrapped.reset(self)
        # skip the magic if test mode is on
        return wrapped.call_original(*args, &block) if base.config.test

        return wrapped unless block

        block.call(wrapped)
        wrapped.call(*args)
      end
    end
  end
end
