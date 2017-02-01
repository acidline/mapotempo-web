class V01::Devices::DevicesApi < Grape::API
  
	namespace :devices do

	  before do
	    @customer = current_customer(params[:customer_id])
	  end

    rescue_from DeviceServiceError do |e|
      error! e.message, 200
    end

    desc 'Validate device Credentials',
      detail: 'Validate device Credentials',
      nickname: 'deviceCheckAuth'
    params do
      requires :device, type: String
    end
    get ':device/auth' do
      authenticate params[:device].to_sym, @customer
      status 204
    end

  end

end
