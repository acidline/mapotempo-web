class Locster < DeviceBase

  def definition
	  {
	    device: 'locster',
	    label: 'Locster',
	    image_url: 'http://www.monlocster.com/upload/image/LOCSTER-logo-produit-geosecurite-antivol-balise-gps.gif',
	    has_sync: false,
	    translate: {
	    	admin_customer: {
	      	:enable => 'activerecord.attributes.customer.devices.locster.enable'
	    	},
        admin_vehicle: {
          :label => 'activerecord.attributes.vehicle.devices.locster.label'
        }
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
