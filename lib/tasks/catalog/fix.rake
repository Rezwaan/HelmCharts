require "json"

namespace :catalog do

  desc "Fetches an invalid catalog from Firestore and overwrites it with a fixed version"
  task :fix, [:catalog_id] => [:environment] do |t, args|
    fixer = Catalogs::Fixer.new(catalog_id: args[:catalog_id])

    fixer.fix
  end
end
