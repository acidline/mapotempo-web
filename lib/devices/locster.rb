class Locster < DeviceBase

  def get_device_definition
	  {
	    device: 'locster',
	    label: 'Locster',
	    image_url: 'http://www.monlocster.com/upload/image/LOCSTER-logo-produit-geosecurite-antivol-balise-gps.gif',
	    has_sync: false,
	    translate: {
	      enable: 'activerecord.attributes.customer.devices.locster.enable'
	    },
		forms: {
        	admin_customer: [
	          [:text, 'username'],
	          [:password, 'password']
	        ],
	        admin_vehicle: [
	          [:text, 'locster_ref']
	        ],
      	}
	  }
  end
  
end
