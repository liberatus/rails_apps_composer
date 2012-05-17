if config['powder']
  gem 'powder', :group => :development
  after_bundler do
    run 'powder link'
  end
end

__END__

name: powder
description: "Tame multiple projects with pretty .dev domains using pow.cx."
author: wnadeau

category: other
tags: [dev]

config:
  - powder:
      type: boolean
      prompt: "If on a mac would you like to use powder to manage your Pow.cx link?"