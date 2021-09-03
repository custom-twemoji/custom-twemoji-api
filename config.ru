# frozen_string_literal: true

require 'require_all'
require 'sinatra/base'

require_all './app/controllers/v1'

use FacesController
run ApplicationController
