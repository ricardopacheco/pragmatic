# frozen_string_literal: true

namespace :credentials do
  desc "Generate config/master.key and config/credentials.yml.enc for this checkout"
  task :setup do
    key_path = Rails.root.join("config/master.key")
    abort "config/master.key already exists; remove it to start over" if key_path.exist?

    # A name no process sets: the key file just written is the one to use, whatever
    # RAILS_MASTER_KEY holds (bin/setup fills it only to satisfy docker compose).
    credentials = ActiveSupport::EncryptedConfiguration.new(
      config_path: Rails.root.join("config/credentials.yml.enc"),
      key_path: key_path,
      env_key: "RAILS_MASTER_KEY_UNUSED",
      raise_if_missing_key: true
    )

    key_path.write(ActiveSupport::EncryptedConfiguration.generate_key)
    credentials.write(<<~YAML)
      secret_key_base: #{SecureRandom.hex(64)}

      active_record_encryption:
        primary_key: #{SecureRandom.alphanumeric(32)}
        deterministic_key: #{SecureRandom.alphanumeric(32)}
        key_derivation_salt: #{SecureRandom.alphanumeric(32)}
    YAML

    puts "Wrote config/master.key and config/credentials.yml.enc"
  end
end
