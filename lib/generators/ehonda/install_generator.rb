require 'rails/generators/named_base'
require 'rails/generators/active_record/migration'

module Ehonda
  class InstallGenerator < Rails::Generators::Base
    include ::ActiveRecord::Generators::Migration

    desc 'Installs models and initializers for Envoy'

    source_root File.expand_path('../templates', __FILE__)

    def install_files
      copy_file 'initializer.rb', 'config/initializers/ehonda.rb'
      copy_file 'dead_letter.rb', 'app/models/dead_letter.rb'
      copy_file 'processed_message.rb', 'app/models/processed_message.rb'
      copy_file 'published_message.rb', 'app/models/published_message.rb'
      copy_file 'dead_letters_worker.rb', 'app/workers/dead_letters_worker.rb'
      copy_file 'idempotent_publisher_worker.rb', 'app/workers/idempotent_publisher_worker.rb'

      migration_template 'create_dead_letters_migration.rb',
                         'db/migrate/ehonda_create_dead_letters.rb'

      migration_template 'create_processed_messages_migration.rb',
                         'db/migrate/ehonda_create_processed_messages.rb'

      migration_template 'create_published_messages_migration.rb',
                         'db/migrate/ehonda_create_published_messages.rb'
    end
  end
end
