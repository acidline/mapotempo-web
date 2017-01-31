class Trimble < DeviceBase

  def get_device_definition
	  {
	    device: 'trimble',
	    label: 'Trimble',
	    image_url: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/dd/Trimble_logo.svg/1280px-Trimble_logo.svg.png',
	    has_sync: false,
	    translate: {
	      enable: 'activerecord.attributes.customer.devices.trimble.enable'
	    },
	    form: [
	    	[:text, 'customer'],
	      [:text, 'username'],
	      [:password, 'password']
	    ]
	  }
  end

  def check_auth(params, customer)

    user    = params[:trimble_username]  ? params[:trimble_username]  : customer.try(:devices[:trimble][:username])
    passwd  = params[:trimble_password]  ? params[:trimble_password]  : customer.try(:devices[:trimble][:password])

    client ||= Savon.client(basic_auth: [user, passwd], wsdl: api_url + '/Customer?wsdl', soap_version: 1) do
      # log true
      # pretty_print_xml true
      convert_request_keys_to :none
    end

    get(client, nil, :get_customer_info, {}, {})

  end
  

  def get(client, no_error_code, operation, message = {}, error_code)
    response = client.call(operation, message: message)
    op_response = (operation.to_s + '_response').to_sym
    op_return = (operation.to_s + '_return').to_sym

    if !response.body.key?(op_response)
      Rails.logger.info response.body[op_response]
      raise DeviceServiceError.new("Trimble operation #{operation} returns error: #{error_code[response.body[op_response][op_return]] || response.body[op_response][op_return]}")
    end

    response.body

  rescue Savon::SOAPFault => error
    Rails.logger.info error
    fault_code = error.to_hash[:fault][:faultcode]
    raise "Trimble : #{fault_code}"
  rescue Savon::HTTPError => error
    Rails.logger.info error.http.code
    raise error
  end

end
