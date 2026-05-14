module ActiveUsage
  module Web
    class Engine < ::Rails::Engine
      isolate_namespace ActiveUsage::Web
    end
  end
end
