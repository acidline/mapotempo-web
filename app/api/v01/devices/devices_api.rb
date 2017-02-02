class V01::Devices::DevicesApi < Grape::API
  
	namespace :devices do

    helpers do

      def device_object(device)
        Mapotempo::Application.config.devices[device.to_sym]
      end

      def device_enabled?(device)
        devices = @customer.enabled_devices_list
        devices.key?(device)
      end

      def authenticate(device, customer)
        if device_enabled?(device) && device_object(:device).respond_to?('check_auth')
          device_object(:device).check_auth(params, customer)
        end
      end

    end

    # BEFORE ACTION CALL
	  before do
	    @customer = current_customer(params[:customer_id])
	  end

    rescue_from DeviceServiceError do |e|
      error! e.message, 200
    end

    # BASE API METHOD
    desc 'Validate device Credentials',
      detail: 'Validate device Credentials',
      nickname: 'deviceCheckAuth'
    params do
      requires :device, type: String
    end
    get ':device/auth' do
      authenticate(params[:device].to_sym, @customer)
      status 204
    end


    desc 'Send Route',
      detail: 'Send Route',
      nickname: 'deviceSend'
    params do
      requires :route_id, type: Integer, desc: 'Route ID'
      requires :type, type: String, desc: 'Action Name', values: %w(waypoints orders)
    end
    post ':devices/send' do
      if device_enabled?(params[:device]) && device_object.respond_to?('send_route')
        Route.transaction do
          route = Route.for_customer(@customer).find params[:route_id]
          device_object(params[:device]).send_route(route, params.slice(:type))
          route.save!
          present route, with: V01::Entities::DeviceRouteLastSentAt
        end
      end
    end

  end

end
