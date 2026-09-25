# frozen_string_literal: true

# Imports in every status, each with a real spreadsheet attached. They are ready-made
# records: processing heavy spreadsheets here would take minutes for a path the import
# tests already cover. Counters and row errors still come from the attached file.
after "development:users" do
  next if Import.exists?

  random = Faker::Config.random
  data = Rails.root.join("db/data")
  generated = Rails.root.join("tmp/seeds").tap(&:mkpath)
  xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  scope = Admin::ProcessImportOperation::I18N_SCOPE
  email_message = I18n.t("contracts.errors.custom.macro.email_format")
  sequence = 0

  write_csv = lambda do |name, count, errors: false|
    generated.join(name).tap do |path|
      CSV.open(path, "w") do |csv|
        csv << %w[full_name email role]

        count.times do |index|
          sequence += 1
          full_name = Faker::Name.name
          email = "#{I18n.transliterate(full_name).parameterize(separator: ".")}.#{sequence}@pragmatic.dev"
          email = email.sub("@", " at ") if errors && (index % 10).zero?

          csv << [full_name, email, (index % 20).zero? ? "admin" : "profile"]
        end
      end
    end
  end

  # What ProcessImportOperation would read, and why it would give up on the file.
  read = lambda do |path, content_type|
    [SpreadsheetReader.for(content_type).new(path.to_s).each_row.to_a, nil]
  rescue SpreadsheetReader::MissingHeadersError => error
    [[], I18n.t("#{scope}.missing_headers", headers: error.message)]
  rescue SpreadsheetReader::Error, CSV::MalformedCSVError
    [[], I18n.t("#{scope}.unreadable_file")]
  end

  create_import = lambda do |admin, path, status: nil, content_type: "text/csv"|
    rows, failure_reason = read.call(path, content_type)
    failures = rows.filter_map do |row_number, attributes|
      next if attributes[:email].match?(Rails.configuration.x.validations.email_format)

      {"row" => row_number, "data" => attributes.stringify_keys, "messages" => [email_message]}
    end

    started_at = random.rand(1..90).days.ago
    status ||= if failure_reason then :failed
    elsif failures.any? then :completed_with_errors
    else :completed
    end

    attributes = case status
    when :queued
      {}
    when :processing
      {total_rows: rows.size, succeeded_rows: rows.size / 2, started_at:}
    when :failed
      {failure_reason:, started_at:, finished_at: started_at + 1.second}
    else
      {
        total_rows: rows.size, failed_rows: failures.size, succeeded_rows: rows.size - failures.size,
        row_errors: failures, started_at:, finished_at: started_at + (rows.size / 500.0).seconds
      }
    end

    import = admin.imports.new(status:, created_at: started_at, **attributes)
    import.spreadsheet.attach(io: File.open(path), filename: File.basename(path), content_type:)
    import.save!
  end

  ActiveRecord::Migration.say_with_time "Seeding the sample imports" do
    create_import.call(default_admin, data.join("users.csv"))
    create_import.call(default_admin, data.join("users.xlsx"), content_type: xlsx)
    create_import.call(default_admin, data.join("users_missing_headers.csv"))
    create_import.call(default_admin, data.join("users_malformed.csv"))
  end

  ActiveRecord::Migration.say_with_time "Seeding generated imports (two of 80,000 rows)" do
    create_import.call(default_admin, write_csv.call("queued.csv", 200), status: :queued)
    create_import.call(default_admin, write_csv.call("processing.csv", 2_000, errors: true), status: :processing)
    create_import.call(default_admin, write_csv.call("large.csv", 80_000))
    create_import.call(default_admin, write_csv.call("large_with_errors.csv", 80_000, errors: true))

    22.times do |index|
      path = write_csv.call("default_admin_#{index}.csv", random.rand(50..3_000), errors: index.odd?)
      create_import.call(default_admin, path)
    end

    User.admin.where.not(id: default_admin.id).find_each do |admin|
      random.rand(5..10).times do |index|
        path = write_csv.call("admin_#{admin.id}_#{index}.csv", random.rand(20..300), errors: index.odd?)
        create_import.call(admin, path)
      end
    end
  end
end
