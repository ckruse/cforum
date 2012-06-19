MongoMapper.connection = Mongo::Connection.new(Rails.configuration.database_host, Rails.configuration.database_port)
MongoMapper.database = Rails.configuration.database_name

if defined?(PhusionPassenger)
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     MongoMapper.connection.connect if forked
   end
end

# eof
