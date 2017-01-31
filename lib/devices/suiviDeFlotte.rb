class SuiviDeFlotte < DeviceBase

  def get_device_definition
	  {
	    device: 'suiviDeFlotte',
	    label: 'SuiviDeFlotte',
	    image_url: 'https://lafu.fr/uploads/images/entreprises/Copie_de_logo_vertical.png',
	    has_sync: false,
	    translate: {
	      enable: 'activerecord.attributes.customer.devices.suiviDeFlotte.enable'
	    }
	  }
  end
  
end
