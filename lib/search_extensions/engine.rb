# frozen_string_literal: true

module ::SearchExtensions
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace SearchExtensions
    config.autoload_paths << File.join(config.root, "lib")
  end
end
