require 'mongo'

require "#{File.dirname(__FILE__)}/data_element_locator"

class PatientDao

  def initialize(db_config)
    @defaults = { :hosts => ['127.0.0.1:27017'], :dbname => 'match' }

    @hosts = get_prop(db_config, 'hosts')
    @port = get_prop(db_config, 'port')
    @dbname = get_prop(db_config, 'dbname')
    @username = get_prop(db_config, 'username')
    @password = get_prop(db_config, 'password')

    @client = Mongo::Client.new(@hosts, :database => @dbname, :user => @username, :password => @password)
  end

  def get_patient_by_status(currentPatientStatus)
    if currentPatientStatus.nil? || !currentPatientStatus.kind_of?(String) || currentPatientStatus.empty?
      raise ArgumentError, 'Current patient status cannot be nil or empty.'
    end
    results = { 'off_trial_patients' => [], 'off_trial_patients_docs' => [] }
    documents = @client[:patient].find(:currentPatientStatus => currentPatientStatus)
    documents.each do |document|
      next if document['currentStepNumber'] != '0'
      patient_sequence_number = document['patientSequenceNumber']
      biopsy = DataElementLocator.get_latest_biopsy(document['biopsies'])
      next if biopsy.nil?
      next_generation_sequence = DataElementLocator.get_latest_next_generation_sequence(biopsy['nextGenerationSequences'])
      next if next_generation_sequence.nil?
      analysis_id = DataElementLocator.get_confirmed_variant_report_analysis_id(next_generation_sequence)
      if !patient_sequence_number.nil? && !analysis_id.nil?
        results['off_trial_patients'].push({ :patient_sequence_number => patient_sequence_number, :analysis_id => analysis_id })
        results['off_trial_patients_docs'].push(document)
      end
    end
    results
  end

  def update(patient_doc)
    if patient_doc.nil?
      raise ArgumentError, 'Patient document cannot be nil.'
    end
    @client[:patient].update_one({'_id' => patient_doc['_id']}, patient_doc)
  end

  def get_prop(db_config, key)
    if !db_config.nil? && db_config.has_key?('database') && db_config['database'].has_key?(key)
      return db_config['database'][key]
    end
    return @defaults.has_key?(key.to_sym) ? @defaults[key.to_sym] : nil
  end

  private :get_prop

end