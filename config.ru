# frozen_string_literal: true

require 'require_all'
require 'sinatra/base'

require_relative 'app/middleware/cloudflare_origin_auth'

require_all './app/controllers/v1'

use CloudflareOriginAuth
use FacesController
use CustomFacesController
use EmojisController
run ApplicationController
