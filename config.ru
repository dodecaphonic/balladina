require "sinatra"
require_relative "lib/balladina_web/app"

set :env, :production
disable :run

run Sinatra::Application
