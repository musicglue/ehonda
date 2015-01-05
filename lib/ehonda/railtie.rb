require 'rails'

module Ehonda
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/ehonda.rake', __FILE__)
    end
  end
end
