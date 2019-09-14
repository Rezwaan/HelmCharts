class ApplicationController < ActionController::API
  include ExceptionHandler

  attr_reader :current_account
end
