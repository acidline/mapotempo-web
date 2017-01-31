class V01::Devices::Trimble < Grape::API
  namespace :devices do
    namespace :trimble do
      before do
        @customer = current_customer params[:customer_id]
      end

      rescue_from DeviceServiceError do |e|
        error! e.message, 200
      end

      desc 'Validate Trimble Credentials',
        detail: 'Validate Trimble Credentials',
        nickname: 'deviceMasternautAuth'
      get '/auth' do
        authenticate :trimble, @customer
        status 204
      end

    end
  end
end
