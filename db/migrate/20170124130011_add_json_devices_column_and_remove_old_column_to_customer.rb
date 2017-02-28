class AddJsonDevicesColumnAndRemoveOldColumnToCustomer < ActiveRecord::Migration

	def up

		add_column :customers, :devices, :jsonb

		Customer.order(:id).each{ |customer|

			customer.devices = {
				orange: {
					enable: customer.enable_orange,
					username: customer.orange_user,
					password: customer.orange_password
				},
				tomtom: {
					enable: customer.enable_tomtom,
					account: customer.tomtom_account,
					username: customer.tomtom_user,
					password: customer.tomtom_password
				},
				teksat: {
					enable: customer.enable_teksat,
					customer_id: customer.teksat_customer_id,
					username: customer.teksat_username,
					password: customer.teksat_password
				},
				masternaut: {
					enable: customer.enable_masternaut,
					username: customer.masternaut_user,
					password: customer.masternaut_password
				},
				alyacom: {
					enable: customer.enable_alyacom,
					api_key: customer.alyacom_api_key,
					association: customer.alyacom_association
				},
				trimble: {
					enable: false,
					username: '',
					password: ''
				},
				locster: {
					enable: false,
					username: '',
					password: ''
				},
				suiviDeFlotte: {
					enable: false,
					username: '',
					password: ''
				}		

			}

			customer.save!

		}

		remove_column :customers, :enable_orange
		remove_column :customers, :orange_user
		remove_column :customers, :orange_password
		remove_column :customers, :enable_tomtom
		remove_column :customers, :tomtom_account
		remove_column :customers, :tomtom_user
		remove_column :customers, :tomtom_password
		remove_column :customers, :enable_teksat
		remove_column :customers, :teksat_customer_id
		remove_column :customers, :teksat_username
		remove_column :customers, :teksat_password
		remove_column :customers, :enable_masternaut
		remove_column :customers, :masternaut_user
		remove_column :customers, :masternaut_password
		remove_column :customers, :enable_alyacom
		remove_column :customers, :alyacom_api_key
		remove_column :customers, :alyacom_association
		
	end

	def down

		add_column :customers, :enable_orange, :boolean
		add_column :customers, :orange_user, :string
		add_column :customers, :orange_password, :string
		add_column :customers, :enable_tomtom, :boolean
		add_column :customers, :tomtom_account, :string
		add_column :customers, :tomtom_user, :string
		add_column :customers, :tomtom_password, :string
		add_column :customers, :enable_teksat, :boolean
		add_column :customers, :teksat_customer_id, :string
		add_column :customers, :teksat_username, :string
		add_column :customers, :teksat_password, :string
		add_column :customers, :enable_masternaut, :boolean
		add_column :customers, :masternaut_user, :string
		add_column :customers, :masternaut_password, :string
		add_column :customers, :enable_alyacom, :boolean
		add_column :customers, :alyacom_api_key, :boolean
		add_column :customers, :alyacom_association, :string


		Customer.order(:id).each{ |customer|

			json = customer.devices

			customer.enable_orange = json['orange']['enable']
			customer.orange_user = json['orange']['username']
			customer.orange_password = json['orange']['password']

			customer.enable_tomtom = json['tomtom']['enable']
			customer.tomtom_account = json['tomtom']['account']
			customer.tomtom_user = json['tomtom']['username']
			customer.tomtom_password = json['tomtom']['password']

			customer.enable_teksat = json['teksat']['enable']
			customer.teksat_customer_id = json['teksat']['customer_id']
			customer.teksat_username = json['teksat']['username']
			customer.teksat_password = json['teksat']['password']

			customer.enable_masternaut = json['masternaut']['enable']
			customer.masternaut_user = json['masternaut']['username']
			customer.masternaut_password = json['masternaut']['password']

			customer.enable_alyacom = json['alyacom']['enable']
			customer.alyacom_api_key = json['alyacom']['api_key']
			customer.alyacom_association = json['alyacom']['association']				

			customer.save!

		}

		remove_column :customers, :devices

	end

end
