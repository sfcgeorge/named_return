module NamedReturn
  # Wrapper to store the original method with a DSL to catch named returns.
  class WrappedMethod
    attr_reader :config

    # Wrap a method with catch DSL and pass in config.
    def initialize(method, config, bind)
      @method = method
      @config = config
      @callbacks = {}
      @response = {}
      bind(bind)
    end

    # Get wrapped method name.
    def name
      @method.name
    end

    # DSL to add nested catch statements.
    def on(label, &block)
      @callbacks[label] = block
    end

    # Call the wrapped method with catches inserted by the DSL.
    def call(*args, &block)
      return_pair = recursive_catch(@callbacks.to_a, *args, &block)
      label, value = @response.first
      value = return_pair unless label # important swizzle for no `on` blocks

      if value.is_a?(Array) && value.first == :return
        # NB in this case `label` will be wrong (nil or outermost `catch`),
        # so we return a value where first element is the "real" label :return
        # and the last element is the actual value returned
        handle_return(value.last)
      else
        @callbacks[label].call(value)
      end
    end

    # Call the wrapped method directly.
    def call_original(*args, &block)
      @method.call(*args, &block)
    end

    private

    # Ensure the wrapped method is bound to the correct instance if necessary.
    def bind(obj)
      return if obj.class == Class

      @method = @method.unbind if @method.respond_to? :unbind
      @method = @method.bind(obj)
    end

    def recursive_catch(callbacks, *args, &block)
      # this return format allows returns to be "re-thrown" or raised
      return [:return, call_original(*args, &block)] if callbacks.empty?

      label, _callback = callbacks.pop
      # the all important catch, throws zip up the stack here
      @response[label] = catch(label) do
        # recurse using __method__ so renaming is less brittle
        send __method__, callbacks, *args, &block
      end
    end

    def handle_return(value)
      case config.return
      when :raise
        # there may be a better exception but ArgumentError get the point over
        raise ArgumentError, "returned without throwing", caller(2)
      when :throw
        # we're not really re-throwing, just faking the behaviour ;)
        raise UncaughtThrowError.new(:return, value), "uncaught throw :return",
          caller(2) unless @callbacks[:return]
        @callbacks[:return].call(value)
      else
        value
      end
    end
  end
end
