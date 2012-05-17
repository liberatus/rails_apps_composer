if config['new_relic']
  gem 'newrelic_rpm'
  ##TODO - prompt for newrelic API key or use of ENV var
  ##TODO - copy over basic newrelic.yml config file
  
end

__END__

name: new_relic
description: "Track app statistics with newrelic.com"
author: wnadeau

category: analytics
tags: [analytics]

config:
  - new_relic:
      type: boolean
      prompt: "Would you like to use New Relic to track application stats?"
