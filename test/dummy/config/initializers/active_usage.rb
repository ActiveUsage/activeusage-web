ENV.store("ACTIVEUSAGE_PASSWORD", "secret")

require "activeusage"

ActiveUsage.configure do |config|
  config.adapter = ActiveUsage::Web::ActiveRecordAdapter.new
end
