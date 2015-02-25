if ENV['WORKER_LIB'] == 'shoryuken'

require 'shoryuken'

Shoryuken.default_worker_options =  {
  'queue'                   => 'default',
  'auto_delete'             => true,
  'auto_visibility_timeout' => true,
  'batch'                   => false,
  'body_parser'             => :json
}

end
