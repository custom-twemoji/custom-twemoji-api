# frozen_string_literal: true

require 'require_all'
require 'rack/protection'
require 'sinatra/base'

require_all './app/controllers/v1'

use Rack::Protection::ContentSecurityPolicy, frame_ancestors: 'customtwemoji.com', default_src: 'self'

use FacesController
use EmojisController
run ApplicationController
