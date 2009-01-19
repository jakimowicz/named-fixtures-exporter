module NamedFixturesExporter

  def self.progress_bar_for(model)
    require "progressbar"
    ProgressBar.new(model.class_name, model.count)
  rescue MissingSourceFile
    nil
  end
  

  def self.fixture_name_from_instance(instance)
    require "active_record/fixtures"
  
    Dir["#{RAILS_ROOT}/test/fixtures/**/*.yml"].each do |file|
      if data = YAML::load(ERB.new(IO.read(file)).result)
        data.keys.each {|key| return key if Fixtures.identify(key) == instance.id}
      end
    end
  
    nil
  end

  def self.name_from_instance!(instance)
    # OPTIMIZE : we could search for uniqueness on these attributes
    fixture_name_from_instance(instance) || instance.attributes['name'] || instance.attributes['title'] || "#{instance.class.to_s.underscore}_#{instance.id}"
  end

  def self.name_from_instance(instance)
    @instance_names ||= {}
    @instance_names[instance] ||= name_from_instance!(instance).gsub(/ /, '_').gsub(/[éè]/, 'e').gsub(/à/, 'a')
  end
  
  def self.fixtures_hash_for(model)
    reflections = model.reflections
    reflections.delete_if {|name, reflection| reflection.macro != :belongs_to and reflection.macro != :has_and_belongs_to}
    bar = progress_bar_for(model)
    result = model.find(:all, :include => reflections.keys.collect(&:to_s)).inject({}) do |result, instance|
      bar.inc if bar
      attributes = instance.attributes
      attributes.delete_if {|column, value| value.nil? or column == 'id' or column == 'updated_at' or column == 'created_at'}
      reflections.each do |name, reflection|
        if reflection.macro == :belongs_to
          attributes.delete reflection.primary_key_name
          attributes[name.to_s] = name_from_instance(instance.send(name)) if instance.send(name)
        else
          attributes[name.to_s] = instance.send(name).collect {|relation_instance| name_from_instance(relation_instance)}.join(', ')
        end
      end
      result[name_from_instance(instance)] = attributes
      result
    end
    bar.finish if bar
    result
  end
  
  def self.export_fixtures(model)
    fixtures_hash = fixtures_hash_for(model)
    File.open("#{RAILS_ROOT}/test/fixtures/#{model.table_name}.yml", 'w' ) {|file| file.write fixtures_hash.to_yaml }
  end
  
end