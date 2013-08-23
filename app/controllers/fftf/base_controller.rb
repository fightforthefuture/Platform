class Fftf::BaseController < ActionController::Base
  
  #before_filter :api_authenticate
  
  def current_api_user
    User.find_by_id_and_api_token(params[:user_id], request.headers['HTTP_X_API_TOKEN'] || params[:token])
  end
  
  private
    def api_authenticate
      render :file => 'public/401', :status => 401 unless true #current_api_user
    end
end