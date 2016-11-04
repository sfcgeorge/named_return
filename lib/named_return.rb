require "named_return/version"
require "named_return/core"

# Named return paths using throw and a DSL around catch.
module NamedReturn
  DefaultConfig = Struct.new(
    # valid config options
    *%i(return only class_only except class_except test)
  ) do
    # Sets defaults.
    def initialize
      self.return = false
      self.only = []
      self.class_only = []
    end

    # Should a method be wrapped by named_return?
    def auto_wrap?(name, singleton)
      if singleton
        class_only.include?(name) ||
          (class_except && !class_except.include?(name))
      else
        only.include?(name) || (except && !except.include?(name))
      end
    end
  end

  # Global configuration block.
  def self.configure
    @config = DefaultConfig.new
    yield(@config) if block_given?
    @config
  end

  # Get configuration.
  def self.config
    @config || configure
  end
end
