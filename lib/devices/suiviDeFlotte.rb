class SuiviDeFlotte < DeviceBase

  def get_device_definition
	  {
	    device: 'suiviDeFlotte',
	    label: 'SuiviDeFlotte',
	    image_url: 'https://lafu.fr/uploads/images/entreprises/Copie_de_logo_vertical.png',
	    has_sync: false,
	    translate: {
	    	admin_customer: {
	    		:enable => 'activerecord.attributes.customer.devices.suiviDeFlotte.enable'
	      },
        admin_vehicle: {
            :label => 'activerecord.attributes.vehicle.devices.suiviDeFlotte.label'
        }
	    },
		forms: {
        	admin_customer: [
	          [:text, 'username'],
	          [:password, 'password']
	        ],
	        admin_vehicle: [
	          [:text, 'suiviDeFlotte_ref']
	        ],
      	}
	  }
  end
  
end
