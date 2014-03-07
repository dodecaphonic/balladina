require "sinatra"

set :public_folder, __dir__ + "/public"

get "/" do
  [200, open(__dir__ + "/public/index.html")]
end
