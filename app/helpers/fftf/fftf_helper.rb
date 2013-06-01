module Fftf
  module Fftf::FftfHelper
  
    # Accepts a hash of parameters and cleans
    # them for user creation
    def clean_salsa_params(params)
      @movement = Movement.find_or_create_by_name(params[:user][:movement_name])
      params[:user].merge!({:movement_id => @movement.id})
      params[:user].delete(:movement_name)
      return params[:user]
    end
  end
end