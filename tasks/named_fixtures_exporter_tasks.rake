namespace :db do
  namespace :fixtures do
    desc "export named fixtures from given MODELS"
    task :export_named do
      ENV["MODELS"].split.collect(&:constantize).each {|model| NamedFixturesExporter::export_fixtures model}
    end
    
    desc "display fixtures for given MODELS"
    task :display_named do
      ENV["MODELS"].split.collect(&:constantize).each {|model| puts NamedFixturesExporter::fixtures_hash_for(model).to_yaml}
    end
  end
end