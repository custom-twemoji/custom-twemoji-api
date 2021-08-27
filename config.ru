# frozen_string_literal: true

require 'require_all'
require 'sinatra/base'

require_all './app/controllers'

use FacesController
run ApplicationController
