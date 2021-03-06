require 'libertree/db'
require 'libertree/job-processor'


if ARGV[0].nil?
  $stderr.puts "#{$0} <config.yaml> <database.yaml>"
  exit 1
end

if ARGV[1].nil?
  $stderr.puts "no database configuration file given; assuming #{File.dirname( __FILE__ ) }/../database.yaml"
  db_config = "#{File.dirname( __FILE__ ) }/../database.yaml"
else
  db_config = ARGV[1]
end

########################
# FIXME: Sequel needs to connect to the db before defining models.  As model
# definitions are loaded when 'lib/jobs' is required, we have to do this first.
Libertree::DB.load_config db_config
Libertree::DB.dbh
########################

require_relative '../lib/jobs'

jobp = Libertree::JobProcessor.new( ARGV[0] )
jobp.extend Jobs

Jobs::Http::Avatar.options = {
  :avatar_dir => jobp.conf['avatar_dir']
}
Jobs::Email::Simple.from = jobp.conf['smtp']['from_address']
Jobs::Request.init_client_conf(jobp.conf)
Mail.defaults do
  delivery_method :smtp, {
    :address              => jobp.conf['smtp']['host'],
    :port                 => jobp.conf['smtp']['port'],
    :user_name            => jobp.conf['smtp']['username'],
    :password             => jobp.conf['smtp']['password'],
    :authentication       => jobp.conf['smtp']['authentication'],
    :domain               => jobp.conf['smtp']['helo_domain'],
    :ssl                  => jobp.conf['smtp']['ssl'],
    :enable_starttls_auto => jobp.conf['smtp']['starttls_auto'],
    :openssl_verify_mode  => jobp.conf['smtp']['openssl_verify_mode'],
  }
end

if ENV['LIBERTREE_TASKS']
  tasks = ENV['LIBERTREE_TASKS'].split(/[ ,;]+/)
else
  tasks = Jobs.list.keys
end

jobp.log "Processing tasks: #{tasks.inspect}"
jobp.run tasks
