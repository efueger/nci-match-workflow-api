require 'mongo'

class PatientDao

  def initialize(db_config)
    @defaults = { :hostname => '127.0.0.1', :port => 27017, :dbname => 'match' }

    @hostname = get_prop(db_config, 'hostname')
    @port = get_prop(db_config, 'port')
    @dbname = get_prop(db_config, 'dbname')
    @username = get_prop(db_config, 'username')
    @password = get_prop(db_config, 'password')

    @client = Mongo::Client.new([ @hostname + ':' + @port.to_s ], :database => @dbname, :user => @username, :password => @password)
  end

  def get_patient_by_status(currentPatientStatus)
    results = []
    documents = @client[:patient].find(:currentPatientStatus => currentPatientStatus)
    documents.each do |document|
      results.push(document['patientSequenceNumber'])
    end
    results
  end

  def get_prop(db_config, key)
    if !db_config.nil? && db_config.has_key?('database') && db_config['database'].has_key?(key)
      return db_config['database'][key]
    end
    return @defaults.has_key?(key.to_s) ? @defaults[key.to_s] : nil
  end

  private :get_prop

end